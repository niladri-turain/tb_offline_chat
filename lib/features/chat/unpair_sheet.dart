import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/peer.dart';
import '../../shared/widgets/widgets.dart';

/// Screen 8: unpair and erase the chat from both phones.
/// Returns true when the user confirms.
class UnpairSheet extends StatelessWidget {
  const UnpairSheet({
    super.key,
    required this.peer,
    required this.messageCount,
  });

  final Peer peer;
  final int messageCount;

  static Future<bool?> show(
    BuildContext context, {
    required Peer peer,
    required int messageCount,
  }) {
    return showAppBottomSheet<bool>(
      context,
      child: UnpairSheet(peer: peer, messageCount: messageCount),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 24),
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.pinkSoft,
            shape: BoxShape.circle,
          ),
          child: const AppIcon(
            AppIcons.unlink,
            size: 32,
            color: AppColors.pinkDark,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Unpair ${peer.name}?',
          textAlign: TextAlign.center,
          style: AppTextStyles.h3,
        ),
        const SizedBox(height: 8),
        Text(
          'All $messageCount messages and files in this chat will be erased '
          "from both phones. This can't be undone.",
          textAlign: TextAlign.center,
          style: AppTextStyles.body,
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.lavenderSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Column(
            children: [
              _Consequence(
                icon: AppIcons.close,
                color: AppColors.pinkDark,
                text: 'Messages & files deleted',
              ),
              SizedBox(height: 10),
              _Consequence(
                icon: AppIcons.close,
                color: AppColors.pinkDark,
                text: 'Pairing key removed',
              ),
              SizedBox(height: 10),
              _Consequence(
                icon: AppIcons.check,
                color: AppColors.success,
                text: 'You can pair again later as strangers',
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SoftButton.danger(
          label: 'Unpair & delete chat',
          // TODO: send `unpair` signal, then delete conversation, messages
          // and pairing key. If out of range, delete here now and on their
          // phone at next connect.
          onPressed: () => Navigator.of(context).pop(true),
        ),
        const SizedBox(height: 10),
        SoftButton(
          label: 'Cancel',
          foreground: AppColors.ink,
          height: 52,
          fontSize: 16,
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}

class _Consequence extends StatelessWidget {
  const _Consequence({
    required this.icon,
    required this.color,
    required this.text,
  });

  final String icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppIcon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w400),
          ),
        ),
      ],
    );
  }
}
