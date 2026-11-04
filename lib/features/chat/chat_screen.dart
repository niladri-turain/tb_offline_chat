import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_assets.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/mock/mock_data.dart';
import '../../data/models/message.dart';
import '../../shared/widgets/widgets.dart';
import 'unpair_sheet.dart';
import 'widgets/chat_header.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/message_bubble.dart';

/// Screen 7: one-to-one chat.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.peerId});

  final String peerId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final _conversation = MockData.conversationFor(widget.peerId);
  final _messages = [...MockData.messages];

  void _send(String text) {
    final now = TimeOfDay.now();
    setState(() {
      _messages.add(
        Message(
          text: text,
          time:
              '${now.hour.toString().padLeft(2, '0')}:'
              '${now.minute.toString().padLeft(2, '0')}',
          isMine: true,
          // TODO: save locally, send as bytes payload, update on ack.
          status: _conversation.inRange
              ? MessageStatus.sent
              : MessageStatus.pending,
        ),
      );
    });
  }

  void _back() =>
      context.canPop() ? context.pop() : context.go(AppRoutes.chats);

  Future<void> _openUnpair() async {
    final unpaired = await UnpairSheet.show(
      context,
      peer: _conversation.peer,
      messageCount: _messages.length,
    );
    if (unpaired == true && mounted) _back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSoft,
      body: Column(
        children: [
          ChatHeader(
            peer: _conversation.peer,
            connected: _conversation.inRange,
            onBack: _back,
            onMore: _openUnpair,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              children: [
                const _LocalOnlyNotice(),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'Today',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.small,
                  ),
                ),
                for (final m in _messages)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: MessageBubble(message: m),
                  ),
              ],
            ),
          ),
          ChatInputBar(onSend: _send, onAttach: () {}),
        ],
      ),
    );
  }
}

class _LocalOnlyNotice extends StatelessWidget {
  const _LocalOnlyNotice();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.lavender,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppIcon(AppIcons.lock, size: 14, color: AppColors.inkSoft),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Saved only on this phone. Deleted when you unpair.',
                textAlign: TextAlign.center,
                style: AppTextStyles.small.copyWith(
                  color: AppColors.inkSoft,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
