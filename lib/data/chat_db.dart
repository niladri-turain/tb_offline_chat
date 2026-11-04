import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// One row of the chat list: a paired peer and the latest message with them.
class ChatSummary {
  ChatSummary({
    required this.conversationId,
    required this.peerId,
    this.lastMessage,
    this.lastAt,
    this.unread = 0,
  });

  final String conversationId;
  final String peerId;
  final String? lastMessage;
  final DateTime? lastAt;
  final int unread;
}

/// Local-only storage. Nothing here ever leaves the phone.
///
/// Conversations are generic (type 'direct' or 'group') so group chat can be added later
/// without changing the schema.
class ChatDb extends ChangeNotifier {
  ChatDb._();
  static final instance = ChatDb._();

  late Database _db;

  Future<void> open() async {
    _db = await openDatabase(
      join(await getDatabasesPath(), 'tb_chat.db'),
      version: 1,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE conversations (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )''');
        await db.execute('''
          CREATE TABLE members (
            conversation_id TEXT NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
            peer_id TEXT NOT NULL,
            paired_at INTEGER NOT NULL,
            PRIMARY KEY (conversation_id, peer_id)
          )''');
        await db.execute('''
          CREATE TABLE messages (
            id TEXT PRIMARY KEY,
            conversation_id TEXT NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
            sender_id TEXT NOT NULL,
            body TEXT NOT NULL,
            status TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )''');
      },
    );
  }

  /// Every direct chat, newest activity first. Empty until the user pairs with someone.
  Future<List<ChatSummary>> chats(String myId) async {
    final rows = await _db.rawQuery('''
      SELECT c.id AS conversation_id, m.peer_id,
        (SELECT body FROM messages WHERE conversation_id = c.id ORDER BY created_at DESC LIMIT 1) AS last_message,
        COALESCE((SELECT MAX(created_at) FROM messages WHERE conversation_id = c.id), m.paired_at) AS last_at,
        (SELECT COUNT(*) FROM messages
           WHERE conversation_id = c.id AND sender_id != ? AND status != 'read') AS unread
      FROM conversations c
      JOIN members m ON m.conversation_id = c.id
      WHERE c.type = 'direct'
      ORDER BY last_at DESC
    ''', [myId]);
    return rows
        .map((r) => ChatSummary(
              conversationId: r['conversation_id'] as String,
              peerId: r['peer_id'] as String,
              lastMessage: r['last_message'] as String?,
              lastAt: DateTime.fromMillisecondsSinceEpoch(r['last_at'] as int),
              unread: r['unread'] as int,
            ))
        .toList();
  }

  /// Both phones derive the same ID for a direct chat, so it can be matched later without a server.
  static String directId(String a, String b) {
    final ids = [a, b]..sort();
    return 'dm_${ids.join('_')}';
  }

  Future<bool> isPaired(String peerId) async =>
      (await _db.query('members', where: 'peer_id = ?', whereArgs: [peerId], limit: 1)).isNotEmpty;

  /// Saves a new pairing as an empty direct chat. Returns false if the peer was already paired.
  Future<bool> pairDirect(String myId, String peerId) async {
    if (await isPaired(peerId)) return false;
    final id = directId(myId, peerId);
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.transaction((txn) async {
      await txn.insert('conversations', {'id': id, 'type': 'direct', 'created_at': now},
          conflictAlgorithm: ConflictAlgorithm.ignore);
      await txn.insert('members', {'conversation_id': id, 'peer_id': peerId, 'paired_at': now},
          conflictAlgorithm: ConflictAlgorithm.ignore);
    });
    notifyListeners();
    return true;
  }

  Future<Set<String>> pairedPeerIds() async {
    final rows = await _db.query('members', columns: ['peer_id']);
    return rows.map((r) => r['peer_id'] as String).toSet();
  }
}
