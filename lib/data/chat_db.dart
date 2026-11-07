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
    this.unpaired = false,
  });

  final String conversationId;
  final String peerId;
  final String? lastMessage;
  final DateTime? lastAt;
  final int unread;

  /// The pairing ended. The history stays, but nobody can send.
  final bool unpaired;
}

/// One saved message. Mine go pending → sent → delivered; theirs go received → read.
class ChatMessage {
  ChatMessage({
    required this.id,
    required this.senderId,
    required this.body,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String body;
  final String status;
  final DateTime createdAt;
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
      version: 2,
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
            unpaired_at INTEGER,
            unpair_pending INTEGER NOT NULL DEFAULT 0,
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
      onUpgrade: (db, from, _) async {
        if (from < 2) {
          await db.execute('ALTER TABLE members ADD COLUMN unpaired_at INTEGER');
          await db.execute('ALTER TABLE members ADD COLUMN unpair_pending INTEGER NOT NULL DEFAULT 0');
        }
      },
    );
  }

  /// Every direct chat, newest activity first. Empty until the user pairs with someone.
  Future<List<ChatSummary>> chats(String myId) async {
    final rows = await _db.rawQuery('''
      SELECT c.id AS conversation_id, m.peer_id, m.unpaired_at,
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
              unpaired: r['unpaired_at'] != null,
            ))
        .toList();
  }

  /// Both phones derive the same ID for a direct chat, so it can be matched later without a server.
  static String directId(String a, String b) {
    final ids = [a, b]..sort();
    return 'dm_${ids.join('_')}';
  }

  Future<bool> isPaired(String peerId) async =>
      (await _db.query('members', where: 'peer_id = ? AND unpaired_at IS NULL', whereArgs: [peerId], limit: 1))
          .isNotEmpty;

  /// Saves a new pairing as an empty direct chat. Returns false if the peer was already paired.
  Future<bool> pairDirect(String myId, String peerId) async {
    if (await isPaired(peerId)) return false;
    final id = directId(myId, peerId);
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.transaction((txn) async {
      await txn.insert('conversations', {'id': id, 'type': 'direct', 'created_at': now},
          conflictAlgorithm: ConflictAlgorithm.ignore);
      // Replace, so pairing again with someone unpaired earlier reopens the same chat.
      await txn.insert('members', {'conversation_id': id, 'peer_id': peerId, 'paired_at': now},
          conflictAlgorithm: ConflictAlgorithm.replace);
    });
    notifyListeners();
    return true;
  }

  Future<Set<String>> pairedPeerIds() async {
    final rows = await _db.query('members', columns: ['peer_id'], where: 'unpaired_at IS NULL');
    return rows.map((r) => r['peer_id'] as String).toSet();
  }

  /// Ends a pairing but keeps the messages. [noticePending] means the other phone still has to be told.
  Future<void> unpair(String peerId, {required bool noticePending}) async {
    await _db.update(
      'members',
      {'unpaired_at': DateTime.now().millisecondsSinceEpoch, 'unpair_pending': noticePending ? 1 : 0},
      where: 'peer_id = ?',
      whereArgs: [peerId],
    );
    notifyListeners();
  }

  Future<bool> needsUnpairNotice(String peerId) async => (await _db.query('members',
          where: 'peer_id = ? AND unpair_pending = 1', whereArgs: [peerId], limit: 1))
      .isNotEmpty;

  Future<void> unpairNoticeSent(String peerId) async {
    await _db.update('members', {'unpair_pending': 0}, where: 'peer_id = ?', whereArgs: [peerId]);
    notifyListeners();
  }

  /// Whether the radios have a reason to run: someone is paired, or still has to hear about an unpair.
  Future<bool> hasContacts() async =>
      (await _db.query('members', where: 'unpaired_at IS NULL OR unpair_pending = 1', limit: 1)).isNotEmpty;

  /// Oldest first.
  Future<List<ChatMessage>> messages(String conversationId) async {
    final rows = await _db.query('messages',
        where: 'conversation_id = ?', whereArgs: [conversationId], orderBy: 'created_at, rowid');
    return rows.map(_message).toList();
  }

  /// Mine that the other phone hasn't confirmed yet, oldest first.
  Future<List<ChatMessage>> undelivered(String conversationId, String myId) async {
    final rows = await _db.query('messages',
        where: "conversation_id = ? AND sender_id = ? AND status != 'delivered'",
        whereArgs: [conversationId, myId],
        orderBy: 'created_at, rowid');
    return rows.map(_message).toList();
  }

  ChatMessage _message(Map<String, Object?> r) => ChatMessage(
        id: r['id'] as String,
        senderId: r['sender_id'] as String,
        body: r['body'] as String,
        status: r['status'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
      );

  /// Saves a message. A resend of one already saved changes nothing.
  Future<void> addMessage(String conversationId, String id, String senderId, String body, String status) async {
    final added = await _db.insert(
      'messages',
      {
        'id': id,
        'conversation_id': conversationId,
        'sender_id': senderId,
        'body': body,
        'status': status,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    if (added != 0) notifyListeners();
  }

  /// Deletes this phone's copy of a chat's messages. The other phone keeps its own.
  Future<void> clearMessages(String conversationId) async {
    await _db.delete('messages', where: 'conversation_id = ?', whereArgs: [conversationId]);
    notifyListeners();
  }

  /// Moves my message forward: a late "sent" must not undo "delivered".
  Future<void> setMyMessageStatus(String conversationId, String id, String status) async {
    final changed = await _db.update(
      'messages',
      {'status': status},
      where: "id = ? AND conversation_id = ? AND status != 'delivered'",
      whereArgs: [id, conversationId],
    );
    if (changed > 0) notifyListeners();
  }

  Future<void> markRead(String conversationId, String myId) async {
    final changed = await _db.update(
      'messages',
      {'status': 'read'},
      where: "conversation_id = ? AND sender_id != ? AND status != 'read'",
      whereArgs: [conversationId, myId],
    );
    if (changed > 0) notifyListeners();
  }
}
