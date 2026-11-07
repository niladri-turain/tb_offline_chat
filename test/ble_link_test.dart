import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tb_chat/services/ble_link.dart';

void main() {
  group('service UUID', () {
    test('carries the ID and platform', () {
      final uuid = BleWire.serviceUuid('0A1B2C3D', ios: true);
      expect(uuid.length, 36);
      final peer = BleWire.parseService(uuid.toUpperCase());
      expect(peer?.id, '0A1B2C3D');
      expect(peer?.ios, true);
      expect(BleWire.parseService(BleWire.serviceUuid('0A1B2C3D', ios: false))?.ios, false);
    });

    test('ignores other devices', () {
      expect(BleWire.parseService('0000180f-0000-1000-8000-00805f9b34fb'), isNull);
      expect(BleWire.parseService('b7c41e52-6a0d-4f3e-9d21-ff000a1b2c3d'), isNull);
    });
  });

  test('frames rebuild the message and mark only the last one', () {
    final message = List.generate(100, (i) => i);
    final frames = BleWire.frames(message, 20);
    expect(frames.every((f) => f.length <= 20), true);
    expect(frames.map((f) => f[0]).toList(), [...List.filled(frames.length - 1, 0), 1]);
    expect(frames.expand((f) => f.sublist(1)).toList(), message);
  });

  group('session', () {
    late BleSession central;
    late BleSession peripheral;

    setUp(() async {
      final a = await X25519().newKeyPair();
      final b = await X25519().newKeyPair();
      central = await BleSession.derive(
        mine: a,
        theirPublicKey: (await b.extractPublicKey()).bytes,
        central: true,
      );
      peripheral = await BleSession.derive(
        mine: b,
        theirPublicKey: (await a.extractPublicKey()).bytes,
        central: false,
      );
    });

    test('both phones show the same code', () {
      expect(central.code, peripheral.code);
      expect(central.code, hasLength(5));
    });

    test('a different key gives a different code', () async {
      final intruder = await X25519().newKeyPair();
      final other = await BleSession.derive(
        mine: intruder,
        theirPublicKey: (await (await X25519().newKeyPair()).extractPublicKey()).bytes,
        central: true,
      );
      expect(other.code, isNot(central.code));
    });

    test('messages cross in both directions', () async {
      final hello = utf8.encode('hello');
      expect(await peripheral.open(await central.seal(hello)), hello);
      expect(await central.open(await peripheral.seal(hello)), hello);
      expect(await peripheral.open(await central.seal(hello)), hello);
    });

    test('rejects a replayed message', () async {
      final sealed = await central.seal(utf8.encode('hello'));
      await peripheral.open(sealed);
      await expectLater(peripheral.open(sealed), throwsA(isA<SecretBoxAuthenticationError>()));
    });

    test('rejects a changed message', () async {
      final sealed = await central.seal(utf8.encode('hello'));
      sealed[sealed.length - 1] ^= 1;
      await expectLater(peripheral.open(sealed), throwsA(isA<SecretBoxAuthenticationError>()));
    });
  });
}
