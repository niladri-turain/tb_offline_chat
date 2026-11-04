import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/widgets.dart';

/// Green "Offline mode · Bluetooth on · Visible" strip.
class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const StatusDot(color: AppColors.success),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.successDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const AppIcon(
            AppIcons.bluetooth,
            size: 16,
            color: AppColors.successDark,
          ),
        ],
      ),
    );
  }
}
