import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/peer.dart';
import '../../../shared/widgets/widgets.dart';

class ChatHeader extends StatelessWidget {
  const ChatHeader({
    super.key,
    required this.peer,
    required this.connected,
    required this.onBack,
    required this.onMore,
  });

  final Peer peer;
  final bool connected;
  final VoidCallback onBack;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final statusColor = connected ? AppColors.successDark : AppColors.muted;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
          child: Row(
            children: [
              SquareIconButton(
                icon: AppIcons.back,
                tooltip: 'Back to chats',
                size: 40,
                radius: 12,
                iconSize: 22,
                background: Colors.transparent,
                onPressed: onBack,
              ),
              const SizedBox(width: 10),
              AnonAvatar(peer: peer, size: 42, fontSize: 14),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(peer.name, style: AppTextStyles.title),
                    Row(
                      children: [
                        StatusDot(
                          size: 7,
                          color: connected
                              ? AppColors.success
                              : AppColors.switchOff,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          connected
                              ? 'Connected · Bluetooth'
                              : 'Out of range',
                          style: AppTextStyles.small.copyWith(
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SquareIconButton(
                icon: AppIcons.more,
                tooltip: 'Chat options',
                size: 40,
                radius: 12,
                iconSize: 22,
                background: Colors.transparent,
                onPressed: onMore,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
