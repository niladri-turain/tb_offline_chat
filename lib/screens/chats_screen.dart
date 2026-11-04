import 'package:flutter/material.dart';

import '../data/chat_db.dart';
import '../data/identity.dart';
import '../theme.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key, required this.onFindNearby});

  final VoidCallback onFindNearby;

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  List<ChatSummary>? _chats;

  @override
  void initState() {
    super.initState();
    ChatDb.instance.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    ChatDb.instance.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final chats = await ChatDb.instance.chats(Identity.myId);
    if (mounted) setState(() => _chats = chats);
  }

  @override
  Widget build(BuildContext context) {
    final chats = _chats;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(),
          const _OfflineBanner(),
          Expanded(
            child: chats == null
                ? const SizedBox.shrink()
                : chats.isEmpty
                    ? _EmptyChats(onFindNearby: widget.onFindNearby)
                    : _ChatList(chats: chats, onFindNearby: widget.onFindNearby),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: TB.gradient),
            child: Container(
              alignment: Alignment.center,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE6E2FA)),
              child: Text(Identity.myId.substring(0, 2),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: TB.indigo)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text('Chats', style: Theme.of(context).textTheme.headlineMedium)),
        ],
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: TB.greenSoft, borderRadius: BorderRadius.circular(12)),
      child: const Row(
        children: [
          CircleAvatar(radius: 4, backgroundColor: TB.green),
          SizedBox(width: 8),
          Expanded(
            child: Text('Offline mode · No internet needed',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: TB.greenDark)),
          ),
          Icon(Icons.bluetooth, size: 16, color: TB.greenDark),
        ],
      ),
    );
  }
}

/// Shown until the user has chatted with anyone.
class _EmptyChats extends StatelessWidget {
  const _EmptyChats({required this.onFindNearby});

  final VoidCallback onFindNearby;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(36, 48, 36, 24),
      child: Column(
        children: [
          const _BubblesIllustration(),
          const SizedBox(height: 36),
          Text('No chats yet', style: text.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text('Find someone nearby to start an anonymous chat. Your chats will show up here.',
              style: text.bodyLarge, textAlign: TextAlign.center),
          const SizedBox(height: 28),
          GradientButton(label: 'Find nearby', icon: Icons.wifi_tethering, onPressed: onFindNearby),
          const SizedBox(height: 16),
          Text('No internet needed · stays on this phone', style: text.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _BubblesIllustration extends StatelessWidget {
  const _BubblesIllustration();

  @override
  Widget build(BuildContext context) {
    Widget line(double w, Color c) =>
        Container(height: 9, width: w, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(5)));
    return SizedBox(
      width: 168,
      height: 128,
      child: Stack(
        children: [
          Transform.rotate(
            angle: -0.14,
            child: Container(
              width: 112,
              height: 88,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  colors: [TB.pink, TB.purple, TB.indigo],
                  stops: [0, 0.6, 1],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [line(70, Colors.white70), const SizedBox(height: 10), line(46, Colors.white70)],
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 100,
              height: 76,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: TB.lavenderDeep, borderRadius: BorderRadius.circular(20)),
              child: line(52, Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatList extends StatelessWidget {
  const _ChatList({required this.chats, required this.onFindNearby});

  final List<ChatSummary> chats;
  final VoidCallback onFindNearby;

  String _time(DateTime? t) {
    if (t == null) return '';
    final now = DateTime.now();
    if (t.year == now.year && t.month == now.month && t.day == now.day) {
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }
    return '${t.day}/${t.month}';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
          itemCount: chats.length,
          itemBuilder: (context, i) {
            final c = chats[i];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              leading: AnonAvatar(peerId: c.peerId, size: 52),
              title: Row(
                children: [
                  Expanded(
                    child: Text(anonName(c.peerId),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: TB.ink)),
                  ),
                  Text(_time(c.lastAt), style: const TextStyle(fontSize: 12, color: TB.muted)),
                ],
              ),
              subtitle: Row(
                children: [
                  Expanded(
                    child: Text(c.lastMessage ?? 'Paired · say hi',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, color: TB.muted)),
                  ),
                  if (c.unread > 0)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(color: TB.pink, borderRadius: BorderRadius.circular(11)),
                      child: Text('${c.unread}',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            );
          },
        ),
        Positioned(
          right: 20,
          bottom: 16,
          child: SizedBox(
            width: 170,
            child: GradientButton(label: 'Find nearby', icon: Icons.wifi_tethering, onPressed: onFindNearby),
          ),
        ),
      ],
    );
  }
}
