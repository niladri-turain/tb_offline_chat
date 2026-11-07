import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../data/identity.dart';

/// FlutterBluePlus asks every app to declare this. Commercial use needs a paid license.
const _fbpLicense = License.nonprofit;

/// What travels over the air, kept apart from the radios so it can be tested.
class BleWire {
  static const _servicePrefix = 'b7c41e52-6a0d-4f3e-9d21-';
  static const rxUuid = 'b7c41e52-6a0d-4f3e-9d22-000000000001';
  static const txUuid = 'b7c41e52-6a0d-4f3e-9d22-000000000002';
  static const _ios = 'a1';
  static const _android = 'a2';
  static final _idPattern = RegExp(r'^[0-9A-F]{8}$');

  static bool isValidId(String id) => _idPattern.hasMatch(id);

  /// Each phone's service UUID carries its platform and ID. iOS can't advertise anything else
  /// that Android would see, and an Android device name would mean renaming the user's phone.
  static String serviceUuid(String id, {required bool ios}) =>
      '$_servicePrefix${ios ? _ios : _android}00${id.toLowerCase()}';

  /// The peer in a service UUID, or null if it isn't a TB Chat phone.
  static ({String id, bool ios})? parseService(String uuid) {
    final value = uuid.toLowerCase();
    if (value.length != 36 || !value.startsWith(_servicePrefix)) return null;
    final platform = value.substring(24, 26);
    final id = value.substring(28).toUpperCase();
    if ((platform != _ios && platform != _android) || !isValidId(id)) return null;
    return (id: id, ios: platform == _ios);
  }

  /// Splits [message] into frames of at most [maxLength] bytes. The first byte of each frame
  /// says whether it's the last one.
  static List<Uint8List> frames(List<int> message, int maxLength) {
    final size = maxLength - 1;
    final result = <Uint8List>[];
    for (var start = 0; start < message.length; start += size) {
      final end = min(start + size, message.length);
      result.add(Uint8List.fromList([end == message.length ? 1 : 0, ...message.sublist(start, end)]));
    }
    return result;
  }
}

/// The encryption for one connection. X25519 gives both phones the same secret, and the code the
/// users compare comes from it, so someone in the middle shows up as two different codes.
/// Messages must arrive in order, which BLE guarantees: the counters reject anything replayed.
class BleSession {
  BleSession._(this._key, this.code, this._central);

  static final _aes = AesGcm.with256bits();

  final SecretKey _key;
  final String code;
  final bool _central;
  int _sent = 0;
  int _received = 0;

  static Future<BleSession> derive({
    required SimpleKeyPair mine,
    required List<int> theirPublicKey,
    required bool central,
  }) async {
    final myPublicKey = (await mine.extractPublicKey()).bytes;
    final shared = await X25519().sharedSecretKey(
      keyPair: mine,
      remotePublicKey: SimplePublicKey(theirPublicKey, type: KeyPairType.x25519),
    );
    final material = [
      ...await shared.extractBytes(),
      ...(central ? myPublicKey : theirPublicKey),
      ...(central ? theirPublicKey : myPublicKey),
    ];
    final key = await Sha256().hash([...utf8.encode('tb-chat-key'), ...material]);
    final check = await Sha256().hash([...utf8.encode('tb-chat-code'), ...material]);
    final code = check.bytes.take(3).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return BleSession._(SecretKey(key.bytes), code.substring(0, 5).toUpperCase(), central);
  }

  List<int> _nonce(bool fromCentral, int counter) => [
        fromCentral ? 0 : 1,
        ...List.filled(7, 0),
        (counter >> 24) & 0xff,
        (counter >> 16) & 0xff,
        (counter >> 8) & 0xff,
        counter & 0xff,
      ];

  Future<Uint8List> seal(List<int> plain) async {
    final box = await _aes.encrypt(plain, secretKey: _key, nonce: _nonce(_central, _sent++));
    return Uint8List.fromList([...box.mac.bytes, ...box.cipherText]);
  }

  /// Throws if the message was changed, replayed or came from someone else.
  Future<Uint8List> open(List<int> sealed) async {
    final box = SecretBox(
      sealed.sublist(16),
      nonce: _nonce(!_central, _received),
      mac: Mac(sealed.sublist(0, 16)),
    );
    final plain = await _aes.decrypt(box, secretKey: _key);
    _received++;
    return Uint8List.fromList(plain);
  }
}

class _Link {
  _Link.central(this.endpoint, this.peerId, this.device) : deviceId = null;
  _Link.peripheral(this.deviceId) : device = null;

  final BluetoothDevice? device;
  final String? deviceId;
  String? endpoint;
  String? peerId;

  BluetoothCharacteristic? rx;
  int maxLength = 20;
  late SimpleKeyPair keys;
  BleSession? session;

  final inbox = BytesBuilder();
  Future<void> receiving = Future.value();
  Future<void> sending = Future.value();
  final subscriptions = <StreamSubscription<Object?>>[];
  final introduced = Completer<void>();

  bool acceptedHere = false;
  bool acceptedThere = false;
  bool connected = false;
  bool closed = false;

  bool get isCentral => device != null;
}

/// Finds and talks to phones over plain BLE, the one radio iPhones and Android phones share:
/// Google Nearby has no Bluetooth on iOS, and Apple's Multipeer doesn't exist on Android.
/// Both phones advertise and scan; whoever connects is the GATT central.
///
/// Connecting mirrors Nearby so [NearbyScanner] can treat both alike: introduce, show the code
/// ([onInitiated]), and both sides accept before [onResult] reports success.
class BleLink {
  BleLink({
    required this.onFound,
    required this.onLost,
    required this.onInitiated,
    required this.onResult,
    required this.onDisconnected,
    required this.onPayload,
  }) {
    _channel.setMethodCallHandler(_onNative);
  }

  static const endpointPrefix = 'ble:';
  static const _channel = MethodChannel('tb_chat/ble_peripheral');
  static const _goneAfter = Duration(seconds: 20);
  static const _maxFrame = 180;

  // First byte of a message.
  static const _hello = 0x48;
  static const _sealed = 0x45;

  // First byte inside a sealed message.
  static const _accept = 0x41;
  static const _leave = 0x52;
  static const _data = 0x44;

  final void Function(String endpoint, String peerId) onFound;
  final void Function(String endpoint) onLost;
  final void Function(String endpoint, String peerId, String code) onInitiated;
  final void Function(String endpoint, bool connected) onResult;
  final void Function(String endpoint) onDisconnected;
  final void Function(String endpoint, Uint8List bytes) onPayload;

  static bool owns(String endpoint) => endpoint.startsWith(endpointPrefix);
  static String _endpoint(String peerId) => '$endpointPrefix$peerId';

  final Map<String, ({BluetoothDevice device, DateTime seen})> _seen = {};
  final Map<String, _Link> _links = {};
  final Map<String, _Link> _incoming = {};
  final Map<String, int> _maxLengths = {};
  StreamSubscription<List<ScanResult>>? _scan;
  Timer? _sweep;

  Future<void> startRadios() async {
    await _channel.invokeMethod<void>('start', {
      'service': BleWire.serviceUuid(Identity.myId, ios: Platform.isIOS),
      'rx': BleWire.rxUuid,
      'tx': BleWire.txUuid,
    });
    _scan = FlutterBluePlus.onScanResults.listen(_onScanResults);
    _sweep = Timer.periodic(const Duration(seconds: 5), (_) => _forgetGone());
    // Each phone's UUID is different, so scanning can't filter by service.
    await FlutterBluePlus.startScan(continuousUpdates: true, androidCheckLocationServices: false);
  }

  Future<void> stopRadios() async {
    _sweep?.cancel();
    _sweep = null;
    await _scan?.cancel();
    _scan = null;
    _seen.clear();
    await FlutterBluePlus.stopScan();
    await _channel.invokeMethod<void>('stopAdvertising');
  }

  void _onScanResults(List<ScanResult> results) {
    for (final result in results) {
      for (final uuid in result.advertisementData.serviceUuids) {
        final peer = BleWire.parseService(uuid.str128);
        if (peer == null || peer.id == Identity.myId) continue;
        // Two Android phones already reach each other through Nearby, which is faster.
        if (Platform.isAndroid && !peer.ios) continue;
        final isNew = !_seen.containsKey(peer.id);
        _seen[peer.id] = (device: result.device, seen: result.timeStamp);
        if (isNew) onFound(_endpoint(peer.id), peer.id);
      }
    }
  }

  void _forgetGone() {
    final cutoff = DateTime.now().subtract(_goneAfter);
    final gone = _seen.entries.where((e) => e.value.seen.isBefore(cutoff)).map((e) => e.key).toList();
    for (final peerId in gone) {
      _seen.remove(peerId);
      onLost(_endpoint(peerId));
    }
  }

  /// Connects to a peer and introduces both phones. Completes once [onInitiated] has fired;
  /// throws if the peer couldn't be reached.
  Future<void> connect(String endpoint) async {
    final peerId = endpoint.substring(endpointPrefix.length);
    final device = _seen[peerId]?.device;
    if (device == null) throw StateError('$peerId is out of range');
    if (_links.containsKey(endpoint)) return;

    final link = _Link.central(endpoint, peerId, device);
    _links[endpoint] = link;
    try {
      await _connectWithRetry(device);
      if (link.closed) return;
      link.subscriptions.add(device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) _close(link);
      }));

      final services = await device.discoverServices();
      final service = services.firstWhere((s) => BleWire.parseService(s.uuid.str128)?.id == peerId);
      final tx = service.characteristics.firstWhere((c) => c.uuid.str128 == BleWire.txUuid);
      link.rx = service.characteristics.firstWhere((c) => c.uuid.str128 == BleWire.rxUuid);
      link.maxLength = min(device.mtuNow - 3, _maxFrame);

      link.subscriptions.add(tx.onValueReceived.listen((frame) => _onFrame(link, frame)));
      await tx.setNotifyValue(true);
      if (link.closed) return;
      await _sendHello(link);
      await link.introduced.future.timeout(const Duration(seconds: 15));
    } catch (e) {
      if (!link.closed) _close(link, silent: true);
      rethrow;
    }
  }

  /// Android often fails a first connection with status 133 while it's also scanning.
  Future<void> _connectWithRetry(BluetoothDevice device) async {
    try {
      await device.connect(license: _fbpLicense, timeout: const Duration(seconds: 12));
    } on FlutterBluePlusException {
      if (!Platform.isAndroid) rethrow;
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await device.connect(license: _fbpLicense, timeout: const Duration(seconds: 12));
    }
  }

  void accept(String endpoint) {
    final link = _links[endpoint];
    if (link == null) return;
    link.acceptedHere = true;
    _sendSealed(link, const [_accept]);
    _checkConnected(link);
  }

  /// Ends a connection, declined or live, and tells the other phone.
  Future<void> disconnect(String endpoint) async {
    final link = _links[endpoint];
    if (link == null) return;
    final wasPending = link.session != null && !link.connected;
    try {
      await _sendSealed(link, const [_leave]).timeout(const Duration(seconds: 2));
    } catch (_) {}
    if (link.closed) return;
    _close(link, silent: true);
    if (wasPending) onResult(endpoint, false);
  }

  Future<void> send(String endpoint, List<int> bytes) {
    final link = _links[endpoint];
    if (link == null || !link.connected) throw StateError('Not connected');
    return _sendSealed(link, [_data, ...bytes]);
  }

  Future<void> _sendHello(_Link link) async {
    link.keys = await X25519().newKeyPair();
    final publicKey = (await link.keys.extractPublicKey()).bytes;
    final hello = jsonEncode({'id': Identity.myId, 'key': base64Encode(publicKey)});
    await _enqueue(link, () async => [_hello, ...utf8.encode(hello)]);
  }

  Future<void> _sendSealed(_Link link, List<int> plain) {
    final session = link.session;
    if (session == null) return Future.value();
    return _enqueue(link, () async => [_sealed, ...await session.seal(plain)]);
  }

  /// Sends one at a time, sealing in the same order, because the counters must match on arrival.
  Future<void> _enqueue(_Link link, Future<List<int>> Function() build) {
    final done = link.sending.catchError((_) {}).then((_) async {
      if (link.closed) throw StateError('Link closed');
      for (final frame in BleWire.frames(await build(), link.maxLength)) {
        final rx = link.rx;
        if (rx != null) {
          await rx.write(frame);
        } else {
          await _channel.invokeMethod<void>('notify', {'device': link.deviceId, 'value': frame});
        }
      }
    });
    link.sending = done;
    return done;
  }

  Future<void> _onNative(MethodCall call) async {
    final args = (call.arguments as Map).cast<String, Object?>();
    final deviceId = args['device'] as String;
    switch (call.method) {
      case 'mtu':
        final maxLength = min(args['maxLength'] as int, _maxFrame);
        _maxLengths[deviceId] = maxLength;
        _incoming[deviceId]?.maxLength = maxLength;
      case 'write':
        final link = _incoming.putIfAbsent(deviceId, () {
          return _Link.peripheral(deviceId)..maxLength = _maxLengths[deviceId] ?? 20;
        });
        _onFrame(link, args['value'] as Uint8List);
      case 'disconnected':
        _maxLengths.remove(deviceId);
        final link = _incoming[deviceId];
        if (link != null) _close(link);
    }
  }

  void _onFrame(_Link link, List<int> frame) {
    if (frame.isEmpty || link.closed) return;
    link.inbox.add(frame.sublist(1));
    if (frame[0] != 1) return;
    final message = link.inbox.takeBytes();
    link.receiving = link.receiving.then((_) => _onMessage(link, message)).catchError((Object e) {
      debugPrint('BLE message rejected: $e');
      _close(link);
    });
  }

  Future<void> _onMessage(_Link link, Uint8List message) async {
    if (link.closed || message.isEmpty) return;
    final body = message.sublist(1);
    if (message[0] == _hello && link.session == null) return _onHello(link, body);
    if (message[0] != _sealed) throw const FormatException('Unknown message');
    final plain = await link.session!.open(body);
    if (plain.isEmpty) return;
    switch (plain[0]) {
      case _accept:
        link.acceptedThere = true;
        _checkConnected(link);
      case _leave:
        _close(link);
      case _data when link.connected:
        onPayload(link.endpoint!, plain.sublist(1));
    }
  }

  Future<void> _onHello(_Link link, Uint8List body) async {
    final hello = jsonDecode(utf8.decode(body)) as Map<String, Object?>;
    final peerId = hello['id'] as String;
    final theirKey = base64Decode(hello['key'] as String);
    if (!BleWire.isValidId(peerId) || theirKey.length != 32) throw const FormatException('Bad hello');

    if (link.isCentral) {
      if (peerId != link.peerId) throw const FormatException('Wrong phone answered');
    } else {
      final endpoint = _endpoint(peerId);
      final existing = _links[endpoint];
      if (existing != null) {
        // Both phones dialled each other: the lower ID's call wins on both sides.
        final mineWins = existing.isCentral && !existing.connected && Identity.myId.compareTo(peerId) < 0;
        if (mineWins) return _close(link, silent: true);
        _close(existing, silent: true);
      }
      link
        ..peerId = peerId
        ..endpoint = endpoint;
      _links[endpoint] = link;
      await _sendHello(link);
    }

    final session = await BleSession.derive(mine: link.keys, theirPublicKey: theirKey, central: link.isCentral);
    link.session = session;
    onInitiated(link.endpoint!, peerId, session.code);
    if (!link.introduced.isCompleted) link.introduced.complete();
  }

  void _checkConnected(_Link link) {
    if (link.connected || !link.acceptedHere || !link.acceptedThere) return;
    link.connected = true;
    onResult(link.endpoint!, true);
  }

  /// Tears a link down. Unless [silent], tells the scanner what ended.
  void _close(_Link link, {bool silent = false}) {
    if (link.closed) return;
    link.closed = true;
    for (final subscription in link.subscriptions) {
      subscription.cancel();
    }
    final endpoint = link.endpoint;
    if (endpoint != null && identical(_links[endpoint], link)) _links.remove(endpoint);
    if (link.isCentral) {
      link.device!.disconnect().catchError((Object e) => debugPrint('BLE disconnect failed: $e'));
    } else {
      _incoming.remove(link.deviceId);
      _channel.invokeMethod<void>('disconnect', {'device': link.deviceId});
    }
    if (silent || endpoint == null) return;
    if (link.connected) {
      onDisconnected(endpoint);
    } else if (link.session != null) {
      onResult(endpoint, false);
    }
  }
}
