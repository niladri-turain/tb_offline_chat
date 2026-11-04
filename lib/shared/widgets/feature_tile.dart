import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_icon.dart';

/// Lavender row with an icon, a title and one line of explanation.
///
/// `boxed` puts the icon inside a white rounded square (Welcome screen);
/// otherwise the icon sits bare at the top (Bluetooth required sheet).
class FeatureTile extends StatelessWidget {
  const FeatureTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.boxed = false,
  });

  final String icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool boxed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: boxed
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
          : const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.lavenderSoft,
        borderRadius: BorderRadius.circular(boxed ? 16 : 14),
      ),
      child: Row(
        crossAxisAlignment: boxed
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          if (boxed)
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: AppIcon(icon, color: iconColor),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: AppIcon(icon, color: iconColor),
            ),
          SizedBox(width: boxed ? 14 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyStrong.copyWith(
                    fontSize: boxed ? 15 : 14,
                  ),
                ),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
