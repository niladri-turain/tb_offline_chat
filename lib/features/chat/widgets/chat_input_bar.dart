import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/widgets.dart';

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({super.key, required this.onSend, required this.onAttach});

  final ValueChanged<String> onSend;
  final VoidCallback onAttach;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
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
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Row(
            children: [
              SquareIconButton(
                icon: AppIcons.plus,
                tooltip: 'Attach',
                iconColor: AppColors.indigo,
                onPressed: widget.onAttach,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _controller,
                  onSubmitted: (_) => _send(),
                  textInputAction: TextInputAction.send,
                  style: AppTextStyles.body.copyWith(color: AppColors.ink),
                  decoration: InputDecoration(
                    hintText: 'Message',
                    hintStyle: AppTextStyles.body,
                    filled: true,
                    fillColor: AppColors.lavenderInput,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
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
                      gradient: AppGradients.pinkIndigo,
                    ),
                    child: const AppIcon(AppIcons.send, color: AppColors.white),
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
