import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tb_chat/data/chat_db.dart';
import 'package:tb_chat/data/identity.dart';

const me = 'AAAA0000';
const peer = 'BBBB1111';
const blocked = 'CCCC2222';

void main() {
  final db = ChatDb.instance;
  final conversation = ChatDb.directId(me, peer);

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // Each test file gets its own folder, so files running in parallel don't share a database.
    databaseFactory.setDatabasesPath(Directory.systemTemp.createTempSync('tb_chat_settings_').path);
    Identity.myId = me;
  });

  setUp(() async {
    await databaseFactory.deleteDatabase(join(await getDatabasesPath(), 'tb_chat.db'));
    await db.open();
    await db.pairDirect(me, peer);
    await db.addMessage(conversation, 'm1', peer, 'hello', 'received');
    await db.block(blocked);
  });

  test('clearing all chats deletes messages but keeps the pairing and blocks', () async {
    await db.clearAllMessages();
    expect(await db.messages(conversation), isEmpty);
    expect(await db.isPaired(peer), isTrue);
    expect(db.isBlocked(blocked), isTrue);
  });

  test('deleting all chats removes pairings and messages but keeps blocks', () async {
    await db.deleteAllChats();
    expect(await db.chats(me), isEmpty);
    expect(await db.isPaired(peer), isFalse);
    expect(await db.messages(conversation), isEmpty);
    expect(await db.hasContacts(), isFalse);
    expect(db.isBlocked(blocked), isTrue);
  });

  test('erasing everything also empties the block list, after reopening too', () async {
    await db.eraseAll();
    expect(await db.chats(me), isEmpty);
    expect(db.isBlocked(blocked), isFalse);
    await db.open();
    expect(db.isBlocked(blocked), isFalse);
    expect(await db.messages(conversation), isEmpty);
  });
}
