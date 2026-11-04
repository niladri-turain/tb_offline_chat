import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/peer.dart';

/// Gradient card showing my anonymous ID with a "New ID" button.
class IdentityCard extends StatelessWidget {
  const IdentityCard({super.key, required this.me, required this.onNewId});

  final Peer me;
  final VoidCallback onNewId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.white.withValues(alpha: 0.22),
            ),
            child: Text(
              me.initials,
              style: AppTextStyles.title.copyWith(color: AppColors.white),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your anonymous ID',
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.white.withValues(alpha: 0.9),
                  ),
                ),
                Text(
                  me.name,
                  style: AppTextStyles.title.copyWith(
                    fontSize: 19,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onNewId,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                child: Text(
                  'New ID',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.purple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
