import '../models/conversation.dart';
import '../models/message.dart';
import '../models/nearby_peer.dart';
import '../models/peer.dart';

/// Sample data for building the UI. Replace with the local database and
/// Nearby Connections once those are wired up.
abstract final class MockData {
  static const me = Peer('4C1E');

  static const conversations = [
    Conversation(
      peer: Peer('7F3A'),
      lastMessage: 'Ami gate er pashe achi',
      time: '10:42',
      unread: 2,
      inRange: true,
      messageCount: 48,
    ),
    Conversation(
      peer: Peer('B21C'),
      lastMessage: 'Ok, file pathacchi',
      time: '10:15',
      inRange: true,
      messageCount: 12,
    ),
    Conversation(
      peer: Peer('09DE'),
      lastMessage: 'Out of range · will send when nearby',
      time: 'Yesterday',
      messageCount: 7,
    ),
    Conversation(
      peer: Peer('E5A1'),
      lastMessage: 'Thanks!',
      time: 'Mon',
      messageCount: 3,
    ),
  ];

  static const nearby = [
    NearbyPeer(
      peer: Peer('7F3A'),
      distance: 'Very close · ~2 m',
      state: PairState.paired,
    ),
    NearbyPeer(
      peer: Peer('B21C'),
      distance: 'Near · ~6 m',
      state: PairState.waiting,
    ),
    NearbyPeer(
      peer: Peer('A9C4'),
      distance: 'In range · ~12 m',
      state: PairState.notPaired,
    ),
  ];

  static const messages = [
    Message(text: 'Hi! Tumi o ki 3rd floor e?', time: '10:38', isMine: false),
    Message(
      text: 'Haan, canteen er pashe',
      time: '10:39',
      isMine: true,
      status: MessageStatus.seen,
    ),
    Message(text: 'Nice, notes ta pathabo?', time: '10:40', isMine: false),
    Message(
      text: 'Pathao, Wi-Fi Direct on ache',
      time: '10:41',
      isMine: true,
      status: MessageStatus.delivered,
    ),
    Message(text: 'Ami gate er pashe achi', time: '10:42', isMine: false),
  ];

  static Conversation conversationFor(String peerId) =>
      conversations.firstWhere(
        (c) => c.peer.id == peerId,
        orElse: () => Conversation(
          peer: Peer(peerId),
          lastMessage: '',
          time: '',
          inRange: true,
        ),
      );
}
