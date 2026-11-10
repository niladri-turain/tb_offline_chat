import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tb_chat/data/chat_db.dart';
import 'package:tb_chat/data/identity.dart';
import 'package:tb_chat/services/chat_service.dart';

const me = 'AAAA0000';
const peer = 'BBBB1111';

Uint8List _message(String id) =>
    Uint8List.fromList(utf8.encode(jsonEncode({'t': 'msg', 'id': id, 'body': 'hello'})));

void main() {
  final db = ChatDb.instance;
  final conversation = ChatDb.directId(me, peer);
  late String path;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    Identity.myId = me;
  });

  setUp(() async {
    path = join(await getDatabasesPath(), 'tb_chat.db');
    await databaseFactory.deleteDatabase(path);
    await db.open();
  });

  test('a block survives reopening the database', () async {
    await db.block(peer);
    await db.open();
    expect(db.isBlocked(peer), isTrue);
    expect(await db.blockedPeers(), [peer]);
  });

  test('unblock removes the peer', () async {
    await db.block(peer);
    await db.unblock(peer);
    await db.open();
    expect(db.isBlocked(peer), isFalse);
    expect(await db.blockedPeers(), isEmpty);
  });

  test('messages from a blocked peer are dropped, and arrive again after unblock', () async {
    await db.pairDirect(me, peer);
    await db.block(peer);
    await ChatService.instance.onPayload(peer, _message('m1'));
    expect(await db.messages(conversation), isEmpty);

    await db.unblock(peer);
    await ChatService.instance.onPayload(peer, _message('m2'));
    expect((await db.messages(conversation)).map((m) => m.id), ['m2']);
  });

  test('a blocked peer cannot end my pairing state with an unpair message', () async {
    await db.pairDirect(me, peer);
    await db.block(peer);
    await ChatService.instance.onPayload(peer, Uint8List.fromList(utf8.encode('{"t":"unpair"}')));
    expect(await db.isPaired(peer), isTrue);
  });

  test('blocking keeps the chat but leaves nothing for the radios to do', () async {
    await db.pairDirect(me, peer);
    await db.addMessage(conversation, 'm1', peer, 'hello', 'received');
    await ChatService.instance.block(peer);
    expect(db.isBlocked(peer), isTrue);
    expect(await db.isPaired(peer), isFalse);
    expect(await db.needsUnpairNotice(peer), isFalse);
    expect(await db.hasContacts(), isFalse);
    expect(await db.messages(conversation), hasLength(1));
  });

  test('upgrading a version 2 database adds the block list and keeps chats', () async {
    await databaseFactory.deleteDatabase(path);
    final old = await databaseFactory.openDatabase(path,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: (d, _) async {
            await d.execute('CREATE TABLE conversations (id TEXT PRIMARY KEY, type TEXT NOT NULL, '
                'created_at INTEGER NOT NULL)');
            await d.execute('CREATE TABLE members (conversation_id TEXT NOT NULL, peer_id TEXT NOT NULL, '
                'paired_at INTEGER NOT NULL, unpaired_at INTEGER, unpair_pending INTEGER NOT NULL DEFAULT 0, '
                'PRIMARY KEY (conversation_id, peer_id))');
            await d.execute('CREATE TABLE messages (id TEXT PRIMARY KEY, conversation_id TEXT NOT NULL, '
                'sender_id TEXT NOT NULL, body TEXT NOT NULL, status TEXT NOT NULL, created_at INTEGER NOT NULL)');
            await d.insert('conversations', {'id': conversation, 'type': 'direct', 'created_at': 1});
            await d.insert('members', {'conversation_id': conversation, 'peer_id': peer, 'paired_at': 1});
          },
        ));
    await old.close();

    await db.open();
    expect(await db.isPaired(peer), isTrue);
    await db.block(peer);
    expect(await db.blockedPeers(), [peer]);
  });
}
