import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/chat_db.dart';
import '../data/identity.dart';

enum ScanStatus { idle, starting, scanning, permissionDenied, bluetoothOff, locationOff, failed }

/// Someone with TB Chat open nearby, seen through Nearby Connections (Bluetooth, BLE and Wi-Fi).
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
/// Only the anonymous ID is broadcast.
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

  List<NearbyPeer> get peers => _found.values.toList();

  final _events = StreamController<PairEvent>.broadcast();
  Stream<PairEvent> get events => _events.stream;

  /// Connections being set up: endpoint → peer ID.
  final Map<String, String> _connecting = {};

  /// Endpoints this phone sent a pair request to.
  final Set<String> _outgoing = {};

  /// Peers connected right now: peer ID → endpoint.
  final Map<String, String> connected = {};

  bool isWaiting(String endpointId) => _outgoing.contains(endpointId);

  Future<void> pair(NearbyPeer peer) async {
    _outgoing.add(peer.endpointId);
    notifyListeners();
    try {
      await Nearby().requestConnection(
        Identity.myId,
        peer.endpointId,
        onConnectionInitiated: _onInitiated,
        onConnectionResult: _onResult,
        onDisconnected: _onDisconnected,
      );
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
    Nearby().rejectConnection(endpointId);
  }

  void cancelPair(String endpointId) {
    _outgoing.remove(endpointId);
    Nearby().disconnectFromEndpoint(endpointId);
    notifyListeners();
  }

  Future<void> _onInitiated(String endpointId, ConnectionInfo info) async {
    final peerId = info.endpointName;
    if (!_idPattern.hasMatch(peerId)) {
      Nearby().rejectConnection(endpointId);
      return;
    }
    _connecting[endpointId] = peerId;
    final code = info.authenticationToken.toUpperCase();
    if (await ChatDb.instance.isPaired(peerId)) {
      // Already paired earlier: reconnect without asking again.
      _accept(endpointId);
    } else if (_outgoing.contains(endpointId)) {
      // The user chose to pair, so accept our side and wait for theirs.
      _accept(endpointId);
      _events.add(PairWaiting(endpointId, peerId, code));
    } else {
      _events.add(PairRequested(endpointId, peerId, code));
    }
  }

  void _accept(String endpointId) {
    Nearby().acceptConnection(
      endpointId,
      // Messages arrive here once chat is built.
      onPayLoadRecieved: (_, _) {},
    );
  }

  Future<void> _onResult(String endpointId, Status result) async {
    final peerId = _connecting.remove(endpointId);
    _outgoing.remove(endpointId);
    if (peerId == null) return notifyListeners();
    if (result == Status.CONNECTED) {
      connected[peerId] = endpointId;
      if (await ChatDb.instance.pairDirect(Identity.myId, peerId)) {
        _events.add(PairFinished(endpointId, peerId, paired: true));
      }
    } else {
      _events.add(PairFinished(endpointId, peerId, paired: false));
    }
    notifyListeners();
  }

  void _onDisconnected(String endpointId) {
    connected.removeWhere((_, e) => e == endpointId);
    notifyListeners();
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
    if (await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on) return true;
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

    if (sdk <= 32 && !await Permission.location.serviceStatus.isEnabled) {
      return _set(ScanStatus.locationOff);
    }

    await _stopRadios();
    _found.clear();
    try {
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
          // When the other phone restarts its scan it gets a new endpoint before the old one is
          // reported lost; keep only the newest so one person shows once.
          _found.removeWhere((_, p) => p.peerId == name);
          _found[endpointId] = NearbyPeer(endpointId, name);
          notifyListeners();
        },
        onEndpointLost: (endpointId) {
          if (_found.remove(endpointId) != null) notifyListeners();
        },
      );
      _set(ScanStatus.scanning);
    } catch (e) {
      debugPrint('Nearby start failed: $e');
      _set(ScanStatus.failed);
    }
  }

  Future<void> _stop() async {
    await _stopRadios();
    _found.clear();
    _set(ScanStatus.idle);
  }

  Future<void> _stopRadios() async {
    try {
      await Nearby().stopDiscovery();
      await Nearby().stopAdvertising();
    } catch (_) {}
  }
}
