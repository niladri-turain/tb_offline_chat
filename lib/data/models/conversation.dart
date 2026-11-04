import 'peer.dart';

class Conversation {
  const Conversation({
    required this.peer,
    required this.lastMessage,
    required this.time,
    this.unread = 0,
    this.inRange = false,
    this.messageCount = 0,
  });

  final Peer peer;
  final String lastMessage;
  final String time;
  final int unread;
  final bool inRange;
  final int messageCount;
}
