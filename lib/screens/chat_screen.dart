import 'package:flutter/material.dart';

import '../data/chat_db.dart';
import '../data/identity.dart';
import '../services/chat_service.dart';
import '../services/nearby_scanner.dart';
import '../theme.dart';

/// The popup for a chat that can't be used any more.
Future<void> showUnpairedDialog(BuildContext context, String peerId) => showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Unpaired from ${anonName(peerId)}', style: Theme.of(context).textTheme.titleMedium),
        content: Text(
          "You can't send or receive messages in this chat any more. It stays saved on your phone. "
          'To chat again, pair from Nearby.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
      ),
    );

enum _ChatAction { unpair, clear }

/// One-to-one chat. Stays readable after unpairing, but nothing can be sent.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.peerId});

  final String peerId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _db = ChatDb.instance;
  final _scanner = NearbyScanner.instance;
  late final _conversation = ChatDb.directId(Identity.myId, widget.peerId);
  List<ChatMessage> _messages = [];
  bool _paired = true;

  @override
  void initState() {
    super.initState();
    _db.addListener(_load);
    _scanner.addListener(_onConnectionChange);
    _load();
  }

  @override
  void dispose() {
    _db.removeListener(_load);
    _scanner.removeListener(_onConnectionChange);
    super.dispose();
  }

  void _onConnectionChange() => setState(() {});

  Future<void> _load() async {
    await _db.markRead(_conversation, Identity.myId);
    final messages = await _db.messages(_conversation);
    final paired = await _db.isPaired(widget.peerId);
    if (mounted) {
      setState(() {
        _messages = messages;
        _paired = paired;
      });
    }
  }

  Future<void> _openOptions() async {
    final action = await showModalBottomSheet<_ChatAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OptionsSheet(peerId: widget.peerId),
    );
    switch (action) {
      case _ChatAction.unpair:
        await ChatService.instance.unpair(widget.peerId);
        if (mounted) await showUnpairedDialog(context, widget.peerId);
      case _ChatAction.clear:
        await _confirmClear();
      case null:
        break;
    }
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Clear this chat?', style: Theme.of(context).textTheme.titleMedium),
        content: Text(
          "All messages will be deleted from this phone. This can't be undone. "
          '${anonName(widget.peerId)} keeps their copy.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: TB.pinkDark),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _db.clearMessages(_conversation);
  }

  @override
  Widget build(BuildContext context) {
    final newestFirst = _messages.reversed.toList();
    return Scaffold(
      backgroundColor: TB.backgroundSoft,
      body: Column(
        children: [
          _Header(
            peerId: widget.peerId,
            paired: _paired,
            connected: _scanner.isConnected(widget.peerId),
            onMore: _paired ? _openOptions : _confirmClear,
          ),
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              itemCount: newestFirst.length + 1,
              itemBuilder: (context, i) {
                if (i == newestFirst.length) return const _LocalOnlyNotice();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _Bubble(message: newestFirst[i]),
                );
              },
            ),
          ),
          if (_paired)
            _InputBar(onSend: (text) => ChatService.instance.send(widget.peerId, text))
          else
            _UnpairedBar(onTap: () => showUnpairedDialog(context, widget.peerId)),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.peerId, required this.paired, required this.connected, required this.onMore});

  final String peerId;
  final bool paired;
  final bool connected;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final online = paired && connected;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: TB.divider)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Back to chats',
                icon: const Icon(Icons.arrow_back, color: TB.ink),
                onPressed: () => Navigator.of(context).pop(),
              ),
              AnonAvatar(peerId: peerId, size: 42),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(anonName(peerId), style: Theme.of(context).textTheme.titleMedium),
                    Row(
                      children: [
                        CircleAvatar(radius: 3.5, backgroundColor: online ? TB.green : TB.switchOff),
                        const SizedBox(width: 6),
                        Text(
                          !paired ? 'Unpaired' : (connected ? 'Connected' : 'Out of range'),
                          style: TextStyle(fontSize: 12, color: online ? TB.greenDark : TB.muted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Chat options',
                icon: const Icon(Icons.more_vert, color: TB.ink),
                onPressed: onMore,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocalOnlyNotice extends StatelessWidget {
  const _LocalOnlyNotice();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: TB.lavender, borderRadius: BorderRadius.circular(12)),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 14, color: TB.navInactive),
              SizedBox(width: 8),
              Flexible(
                child: Text('Saved only on this phone.', style: TextStyle(fontSize: 12, color: TB.navInactive)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  static const _labels = {'pending': 'Pending', 'sent': 'Sent', 'delivered': 'Delivered'};

  @override
  Widget build(BuildContext context) {
    final mine = message.senderId == Identity.myId;
    final t = message.createdAt;
    final time = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    const r = Radius.circular(18);
    const tail = Radius.circular(4);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Column(
          crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: mine
                    ? const LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [TB.pinkDark, TB.violet])
                    : null,
                color: mine ? null : Colors.white,
                border: mine ? null : Border.all(color: TB.divider),
                borderRadius: BorderRadius.only(
                  topLeft: r,
                  topRight: r,
                  bottomLeft: mine ? r : tail,
                  bottomRight: mine ? tail : r,
                ),
              ),
              child: Text(message.body,
                  style: TextStyle(fontSize: 15, height: 1.4, color: mine ? Colors.white : TB.ink)),
            ),
            const SizedBox(height: 3),
            Text(mine ? '$time · ${_labels[message.status]}' : time,
                style: const TextStyle(fontSize: 11, color: TB.muted)),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatefulWidget {
  const _InputBar({required this.onSend});

  final ValueChanged<String> onSend;

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  final _controller = TextEditingController();

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: TB.divider)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLength: ChatService.maxBodyLength,
                  onSubmitted: (_) => _send(),
                  textInputAction: TextInputAction.send,
                  style: const TextStyle(fontSize: 15, color: TB.ink),
                  decoration: InputDecoration(
                    hintText: 'Message',
                    counterText: '',
                    filled: true,
                    fillColor: TB.lavenderInput,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Tooltip(
                message: 'Send',
                child: GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                          begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [TB.pink, TB.indigo]),
                    ),
                    child: const Icon(Icons.send, size: 20, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Takes the place of the input bar once the pairing has ended.
class _UnpairedBar extends StatelessWidget {
  const _UnpairedBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TB.pinkSoft,
      child: InkWell(
        onTap: onTap,
        child: const SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.link_off, size: 18, color: TB.pinkDark),
                SizedBox(width: 8),
                Flexible(
                  child: Text("Unpaired · you can't send messages",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: TB.pinkDark)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Unpair or clear this chat. Pops the chosen action, or null for Cancel.
class _OptionsSheet extends StatelessWidget {
  const _OptionsSheet({required this.peerId});

  final String peerId;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: TB.pinkSoft, shape: BoxShape.circle),
                child: const Icon(Icons.link_off, size: 32, color: TB.pinkDark),
              ),
              const SizedBox(height: 18),
              Text('Unpair ${anonName(peerId)}?',
                  textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                "You won't be able to send or receive messages. This chat stays saved on your phone.",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: TB.pinkDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: () => Navigator.of(context).pop(_ChatAction.unpair),
                  child: const Text('Unpair',
                      style: TextStyle(fontFamily: TB.display, fontWeight: FontWeight.w600, fontSize: 17)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: TB.pinkSoft,
                    foregroundColor: TB.pinkDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: () => Navigator.of(context).pop(_ChatAction.clear),
                  child: const Text('Clear chat',
                      style: TextStyle(fontFamily: TB.display, fontWeight: FontWeight.w600, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: TB.lavender,
                    foregroundColor: TB.ink,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel',
                      style: TextStyle(fontFamily: TB.display, fontWeight: FontWeight.w600, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
