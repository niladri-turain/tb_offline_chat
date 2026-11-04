import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/message.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final mine = message.isMine;
    const r = Radius.circular(18);
    const tail = Radius.circular(4);

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Column(
          crossAxisAlignment: mine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: mine ? AppGradients.myBubble : null,
                color: mine ? null : AppColors.white,
                border: mine ? null : Border.all(color: AppColors.border),
                borderRadius: BorderRadius.only(
                  topLeft: r,
                  topRight: r,
                  bottomLeft: mine ? r : tail,
                  bottomRight: mine ? tail : r,
                ),
              ),
              child: Text(
                message.text,
                style: AppTextStyles.body.copyWith(
                  height: 1.4,
                  color: mine ? AppColors.white : AppColors.ink,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              mine ? '${message.time} · ${message.status.label}' : message.time,
              style: AppTextStyles.small.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
