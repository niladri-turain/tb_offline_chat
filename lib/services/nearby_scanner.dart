import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/chat_db.dart';
import '../data/identity.dart';
import 'ble_link.dart';
import 'chat_service.dart';

enum ScanStatus { idle, starting, scanning, permissionDenied, bluetoothOff, locationOff, failed }

/// Someone with TB Chat open nearby, seen through Nearby Connections (Android to Android)
/// or [BleLink] (anything with an iPhone in it).
class NearbyPeer {
  NearbyPeer(this.endpointId, this.peerId);

  final String endpointId;
  final String peerId;
}

/// What the pairing UI needs to react to. [code] is Nearby's authentication token,
/// which is the same on both phones when nobody is in the middle.
sealed class PairEvent {
  PairEvent(this.endpointId, this.peerId);

  final String endpointId;
  final String peerId;
}

/// Someone nearby wants to pair with this phone; the user accepts or declines.
class PairRequested extends PairEvent {
  PairRequested(super.endpointId, super.peerId, this.code);

  final String code;
}

/// This phone asked to pair and is waiting for the other person.
class PairWaiting extends PairEvent {
  PairWaiting(super.endpointId, super.peerId, this.code);

  final String code;
}

/// The request ended: paired, or declined/cancelled/failed.
class PairFinished extends PairEvent {
  PairFinished(super.endpointId, super.peerId, {required this.paired});

  final bool paired;
}

/// Advertises this phone and discovers other TB Chat phones, with no internet.
/// Only the anonymous ID is broadcast. Android runs Nearby and BLE side by side; iOS runs BLE only,
/// because Nearby has no iOS version here. An endpoint belongs to BLE if [BleLink.owns] says so.
///
/// One app-wide instance: screens call [acquire] when they open and [release] when they close,
/// and the radios run while at least one screen holds it. When a screen is rebuilt, the new
/// one acquires before the old one releases, so the scan isn't torn down in between.
class NearbyScanner extends ChangeNotifier {
  NearbyScanner._();
  static final instance = NearbyScanner._();

  static const serviceId = 'com.tbchat.tb_chat';
  static final _idPattern = RegExp(r'^[0-9A-F]{8}$');

  ScanStatus status = ScanStatus.idle;
  bool permanentlyDenied = false;
  final Map<String, NearbyPeer> _found = {};
  int _holders = 0;
  // Start and stop run one after another; overlapping them makes Nearby fail with ALREADY_DISCOVERING.
  Future<void> _queue = Future.value();

  late final _ble = BleLink(
    onFound: _onPeerFound,
    onLost: _onPeerLost,
    onInitiated: (endpoint, peerId, code) => _onInitiated(endpoint, ConnectionInfo(peerId, code, false)),
    onResult: (endpoint, connected) => _onResult(endpoint, connected ? Status.CONNECTED : Status.ERROR),
    onDisconnected: _onDisconnected,
    onPayload: _onBytes,
  );

  List<NearbyPeer> get peers => _found.values.toList();

  final _events = StreamController<PairEvent>.broadcast();
  Stream<PairEvent> get events => _events.stream;

  /// Connections being set up: endpoint → peer ID.
  final Map<String, String> _connecting = {};

  /// Endpoints this phone sent a pair request to.
  final Set<String> _outgoing = {};

  /// Peers connected right now: peer ID → endpoint.
  final Map<String, String> connected = {};

  /// Who each live endpoint is. Set before [connected], because the other phone can start
  /// sending the moment its side of the connection is up.
  final Map<String, String> _endpointPeers = {};

  /// Peers this phone is reconnecting to on its own.
  final Set<String> _redialing = {};

  bool isConnected(String peerId) => connected.containsKey(peerId);

  /// Sends one JSON message to a connected peer. False if it couldn't be handed to Nearby.
  Future<bool> sendTo(String peerId, Map<String, Object?> data) async {
    final endpointId = connected[peerId];
    if (endpointId == null) return false;
    try {
      final bytes = utf8.encode(jsonEncode(data));
      if (BleLink.owns(endpointId)) {
        await _ble.send(endpointId, bytes);
      } else {
        await Nearby().sendBytesPayload(endpointId, bytes);
      }
      return true;
    } catch (e) {
      debugPrint('Send failed: $e');
      return false;
    }
  }

  void disconnectPeer(String peerId) {
    final endpointId = connected.remove(peerId);
    if (endpointId == null) return;
    _endpointPeers.remove(endpointId);
    _hangUp(endpointId);
    notifyListeners();
  }

  /// Drops a blocked peer from the nearby list and from any connection still being set up.
  void forgetPeer(String peerId) {
    _found.removeWhere((_, p) => p.peerId == peerId);
    final settingUp = [
      for (final e in _connecting.entries)
        if (e.value == peerId) e.key
    ];
    for (final endpointId in settingUp) {
      _endpointPeers.remove(endpointId);
      _outgoing.remove(endpointId);
      declineRequest(endpointId);
    }
    notifyListeners();
  }

  void _hangUp(String endpointId) {
    if (BleLink.owns(endpointId)) {
      _ble.disconnect(endpointId);
    } else {
      Nearby().disconnectFromEndpoint(endpointId);
    }
  }

  Future<void> _dial(String endpointId) {
    if (BleLink.owns(endpointId)) return _ble.connect(endpointId);
    return Nearby().requestConnection(
      Identity.myId,
      endpointId,
      onConnectionInitiated: _onInitiated,
      onConnectionResult: _onResult,
      onDisconnected: _onDisconnected,
    );
  }

  /// Reconnects to someone already known. Only the lower ID dials, so the two phones don't
  /// dial each other at once.
  Future<void> _redial(String endpointId, String peerId) async {
    if (connected.containsKey(peerId) || _redialing.contains(peerId)) return;
    if (_connecting.containsValue(peerId) || Identity.myId.compareTo(peerId) > 0) return;
    final known = await ChatDb.instance.isPaired(peerId) || await ChatDb.instance.needsUnpairNotice(peerId);
    if (!known) return;
    _redialing.add(peerId);
    try {
      await _dial(endpointId);
    } catch (e) {
      debugPrint('Reconnect failed: $e');
    } finally {
      _redialing.remove(peerId);
    }
  }

  bool isWaiting(String endpointId) => _outgoing.contains(endpointId);

  Future<void> pair(NearbyPeer peer) async {
    _outgoing.add(peer.endpointId);
    notifyListeners();
    try {
      await _dial(peer.endpointId);
    } catch (e) {
      debugPrint('Pair request failed: $e');
      _outgoing.remove(peer.endpointId);
      _events.add(PairFinished(peer.endpointId, peer.peerId, paired: false));
      notifyListeners();
    }
  }

  void acceptRequest(String endpointId) => _accept(endpointId);

  void declineRequest(String endpointId) {
    _connecting.remove(endpointId);
    _reject(endpointId);
  }

  void _reject(String endpointId) {
    if (BleLink.owns(endpointId)) {
      _ble.disconnect(endpointId);
    } else {
      Nearby().rejectConnection(endpointId);
    }
  }

  void cancelPair(String endpointId) {
    _outgoing.remove(endpointId);
    _hangUp(endpointId);
    notifyListeners();
  }

  Future<void> _onInitiated(String endpointId, ConnectionInfo info) async {
    final peerId = info.endpointName;
    if (!_idPattern.hasMatch(peerId) || ChatDb.instance.isBlocked(peerId)) {
      _reject(endpointId);
      return;
    }
    _connecting[endpointId] = peerId;
    _endpointPeers[endpointId] = peerId;
    final code = info.authenticationToken.toUpperCase();
    if (await ChatDb.instance.isPaired(peerId)) {
      // Already paired earlier: reconnect without asking again.
      _accept(endpointId);
    } else if (_outgoing.contains(endpointId)) {
      // The user chose to pair, so accept our side and wait for theirs.
      _accept(endpointId);
      _events.add(PairWaiting(endpointId, peerId, code));
    } else if (await ChatDb.instance.needsUnpairNotice(peerId)) {
      // They still think we're paired. Connect only to tell them we're not.
      _accept(endpointId);
    } else if (_events.hasListener) {
      _events.add(PairRequested(endpointId, peerId, code));
    } else {
      // The radios also run outside Nearby to keep paired chats alive, but only Nearby can ask the user.
      declineRequest(endpointId);
    }
  }

  void _accept(String endpointId) {
    if (BleLink.owns(endpointId)) return _ble.accept(endpointId);
    Nearby().acceptConnection(
      endpointId,
      onPayLoadRecieved: (endpoint, payload) {
        final bytes = payload.bytes;
        if (payload.type == PayloadType.BYTES && bytes != null) _onBytes(endpoint, bytes);
      },
    );
  }

  void _onBytes(String endpointId, Uint8List bytes) {
    final peerId = _endpointPeers[endpointId];
    if (peerId != null) ChatService.instance.onPayload(peerId, bytes);
  }

  void _onPeerFound(String endpointId, String peerId) {
    if (ChatDb.instance.isBlocked(peerId)) return;
    // When the other phone restarts its scan it gets a new endpoint before the old one is
    // reported lost; keep only the newest so one person shows once.
    _found.removeWhere((_, p) => p.peerId == peerId);
    _found[endpointId] = NearbyPeer(endpointId, peerId);
    notifyListeners();
    _redial(endpointId, peerId);
  }

  void _onPeerLost(String endpointId) {
    if (_found.remove(endpointId) != null) notifyListeners();
  }

  Future<void> _onResult(String endpointId, Status result) async {
    final peerId = _connecting.remove(endpointId);
    final chosen = _outgoing.remove(endpointId);
    if (peerId == null) return notifyListeners();
    final db = ChatDb.instance;
    if (result == Status.CONNECTED) {
      // Blocked while the connection was being set up: pairing now would undo the block.
      if (db.isBlocked(peerId)) {
        _endpointPeers.remove(endpointId);
        _hangUp(endpointId);
        return notifyListeners();
      }
      connected[peerId] = endpointId;
      if (!chosen && await db.needsUnpairNotice(peerId)) {
        await ChatService.instance.sendUnpairNotice(peerId);
        return notifyListeners();
      }
      if (await db.pairDirect(Identity.myId, peerId)) {
        _events.add(PairFinished(endpointId, peerId, paired: true));
      }
      notifyListeners();
      await ChatService.instance.onConnected(peerId);
    } else {
      _endpointPeers.remove(endpointId);
      // A failed reconnect isn't a failed pairing; the next scan tries again.
      if (!await db.isPaired(peerId)) _events.add(PairFinished(endpointId, peerId, paired: false));
      notifyListeners();
    }
  }

  void _onDisconnected(String endpointId) {
    _endpointPeers.remove(endpointId);
    connected.removeWhere((_, e) => e == endpointId);
    notifyListeners();
    // Nearby won't report this phone as found again by itself, so look again to reconnect.
    if (_holders > 0) rescan();
  }

  void acquire() {
    if (_holders++ == 0) start();
  }

  void release() {
    if (--_holders == 0) stop();
  }

  Future<void> start() => _serial(_start);

  Future<void> stop() => _serial(_stop);

  Future<void> rescan() => _serial(() async {
        await _stop();
        await _start();
      });

  Future<void> _serial(Future<void> Function() op) => _queue = _queue.then((_) => op());

  void _set(ScanStatus s) {
    status = s;
    notifyListeners();
  }

  Future<int> _sdk() async =>
      Platform.isAndroid ? (await DeviceInfoPlugin().androidInfo).version.sdkInt : 0;

  Future<List<Permission>> _neededPermissions() async {
    if (Platform.isIOS) return [Permission.bluetooth];
    final sdk = await _sdk();
    return [
      if (sdk >= 31) ...[Permission.bluetoothScan, Permission.bluetoothAdvertise, Permission.bluetoothConnect],
      if (sdk >= 33) Permission.nearbyWifiDevices,
      // Google Nearby refuses to discover without location permission, on every Android version.
      Permission.location,
    ];
  }

  /// Asks for everything scanning needs. Also used by the first-launch Bluetooth sheet.
  Future<Map<Permission, PermissionStatus>> requestPermissions() async =>
      (await _neededPermissions()).request();

  /// Whether everything scanning needs is already allowed. Never shows a dialog.
  Future<bool> hasPermissions() async {
    for (final permission in await _neededPermissions()) {
      if (!await permission.isGranted) return false;
    }
    return true;
  }

  /// Turns Bluetooth on if it's off. False if it couldn't be turned on.
  Future<bool> ensureBluetoothOn() async {
    // iOS reports "unknown" for a moment after launch.
    final state = await FlutterBluePlus.adapterState
        .firstWhere((s) => s != BluetoothAdapterState.unknown)
        .timeout(const Duration(seconds: 3), onTimeout: () => BluetoothAdapterState.unknown);
    if (state == BluetoothAdapterState.on) return true;
    // Only Android lets an app switch Bluetooth on.
    if (!Platform.isAndroid) return false;
    try {
      await FlutterBluePlus.turnOn();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _start() async {
    if (_holders == 0 || status == ScanStatus.scanning) return;
    _set(ScanStatus.starting);

    final sdk = await _sdk();
    final results = await requestPermissions();
    if (results.values.any((s) => !s.isGranted)) {
      permanentlyDenied = results.values.any((s) => s.isPermanentlyDenied);
      return _set(ScanStatus.permissionDenied);
    }

    if (!await ensureBluetoothOn()) return _set(ScanStatus.bluetoothOff);

    if (Platform.isAndroid && sdk <= 32 && !await Permission.location.serviceStatus.isEnabled) {
      return _set(ScanStatus.locationOff);
    }

    await _stopRadios();
    _found.clear();
    try {
      if (Platform.isAndroid) await _startNearby();
    } catch (e) {
      debugPrint('Nearby start failed: $e');
      return _set(ScanStatus.failed);
    }
    try {
      await _ble.startRadios();
    } catch (e) {
      debugPrint('BLE start failed: $e');
      // An Android phone that can't advertise over BLE still reaches other Android phones.
      if (!Platform.isAndroid) return _set(ScanStatus.failed);
    }
    _set(ScanStatus.scanning);
  }

  Future<void> _startNearby() async {
    await Nearby().startAdvertising(
      Identity.myId,
      Strategy.P2P_CLUSTER,
      serviceId: serviceId,
      onConnectionInitiated: _onInitiated,
      onConnectionResult: _onResult,
      onDisconnected: _onDisconnected,
    );
    await Nearby().startDiscovery(
      Identity.myId,
      Strategy.P2P_CLUSTER,
      serviceId: serviceId,
      onEndpointFound: (endpointId, name, foundServiceId) {
        if (foundServiceId != serviceId || !_idPattern.hasMatch(name) || name == Identity.myId) return;
        _onPeerFound(endpointId, name);
      },
      onEndpointLost: (endpointId) {
        if (endpointId != null) _onPeerLost(endpointId);
      },
    );
  }

  Future<void> _stop() async {
    await _stopRadios();
    _found.clear();
    _set(ScanStatus.idle);
  }

  Future<void> _stopRadios() async {
    try {
      await _ble.stopRadios();
    } catch (_) {}
    if (!Platform.isAndroid) return;
    try {
      await Nearby().stopDiscovery();
      await Nearby().stopAdvertising();
    } catch (_) {}
  }
}
