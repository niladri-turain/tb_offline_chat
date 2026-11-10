import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/chat_db.dart';
import '../data/identity.dart';
import '../data/prefs.dart';
import 'nearby_scanner.dart';

/// Sends and receives chat over a Nearby connection. Every message is saved on this phone first,
/// so it survives closing the app, and is sent again on reconnect until the other phone confirms it.
class ChatService {
  ChatService._();
  static final instance = ChatService._();

  static const maxBodyLength = 4000;

  final _db = ChatDb.instance;
  final _scanner = NearbyScanner.instance;

  final _unpairedByPeer = StreamController<String>.broadcast();

  /// Peer IDs that just unpaired from this phone.
  Stream<String> get unpairedByPeer => _unpairedByPeer.stream;

  String _conversation(String peerId) => ChatDb.directId(Identity.myId, peerId);

  Future<void> send(String peerId, String body) async {
    if (!await _db.isPaired(peerId)) return;
    final id = const Uuid().v4();
    await _db.addMessage(_conversation(peerId), id, Identity.myId, body, 'pending');
    await _deliver(peerId, id, body);
  }

  Future<void> _deliver(String peerId, String id, String body) async {
    if (await _scanner.sendTo(peerId, {'t': 'msg', 'id': id, 'body': body})) {
      await _db.setMyMessageStatus(_conversation(peerId), id, 'sent');
    }
  }

  /// Sends whatever the other phone hasn't confirmed. It ignores any it already has.
  Future<void> onConnected(String peerId) async {
    for (final m in await _db.undelivered(_conversation(peerId), Identity.myId)) {
      await _deliver(peerId, m.id, m.body);
    }
  }

  Future<void> onPayload(String peerId, Uint8List bytes) async {
    if (_db.isBlocked(peerId)) return;
    final Object? data;
    try {
      data = jsonDecode(utf8.decode(bytes));
    } on FormatException catch (e) {
      debugPrint('Bad payload: $e');
      return;
    }
    switch (data) {
      case {'t': 'msg', 'id': final String id, 'body': final String body}
          when body.isNotEmpty && body.length <= maxBodyLength:
        if (!await _db.isPaired(peerId)) return;
        await _db.addMessage(_conversation(peerId), id, peerId, body, 'received');
        await _scanner.sendTo(peerId, {'t': 'ack', 'id': id});
      case {'t': 'ack', 'id': final String id}:
        await _db.setMyMessageStatus(_conversation(peerId), id, 'delivered');
      case {'t': 'unpair'}:
        if (!await _db.isPaired(peerId)) return;
        await _db.unpair(peerId, noticePending: false);
        _scanner.disconnectPeer(peerId);
        _unpairedByPeer.add(peerId);
    }
  }

  /// Ends the pairing here. If the other phone is out of range, it's told on the next connection.
  Future<void> unpair(String peerId) async {
    await _db.unpair(peerId, noticePending: true);
    if (_scanner.isConnected(peerId)) await sendUnpairNotice(peerId);
  }

  /// Ends the pairing and refuses this peer from now on. They only see an unpair, and only if
  /// they're connected right now: a blocked phone is never connected to again just to tell it.
  Future<void> block(String peerId) async {
    final connected = _scanner.isConnected(peerId);
    await _db.block(peerId);
    // A pending notice also keeps the radios on until it has gone out.
    await _db.unpair(peerId, noticePending: connected);
    _scanner.forgetPeer(peerId);
    if (connected) {
      await sendUnpairNotice(peerId);
      await _db.unpairNoticeSent(peerId);
    }
  }

  Future<void> unblock(String peerId) async {
    await _db.unblock(peerId);
    // The radios only report someone once, so look again for anyone who was being ignored.
    await _scanner.rescan();
  }

  /// Starts over with a new ID. All chats are deleted; whoever is in range is told they're unpaired.
  Future<void> newIdentity() async {
    await _leaveEveryone();
    await _db.deleteAllChats();
    await Identity.renew();
    await _scanner.rescan();
  }

  /// Deletes everything this app keeps and goes back to first launch.
  Future<void> eraseEverything() async {
    await _leaveEveryone();
    await _scanner.stop();
    await _db.eraseAll();
    await Identity.reset();
    await Prefs.load();
  }

  /// Phones out of range can't be told; their chat stays until they unpair it themselves.
  Future<void> _leaveEveryone() async {
    for (final peerId in await _db.pairedPeerIds()) {
      if (_scanner.isConnected(peerId)) await sendUnpairNotice(peerId);
    }
  }

  /// Turns being findable on or off, and restarts the radios so it takes effect now.
  Future<void> setVisible(bool visible) async {
    await Prefs.setVisible(visible);
    await _scanner.rescan();
  }

  Future<void> sendUnpairNotice(String peerId) async {
    if (await _scanner.sendTo(peerId, {'t': 'unpair'})) await _db.unpairNoticeSent(peerId);
    // Leave time for the notice to go out before the connection closes.
    await Future<void>.delayed(const Duration(seconds: 1));
    _scanner.disconnectPeer(peerId);
  }
}
