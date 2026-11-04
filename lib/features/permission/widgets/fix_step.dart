import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Numbered "How to fix" line with one bold part.
class FixStep extends StatelessWidget {
  const FixStep({
    super.key,
    required this.number,
    required this.before,
    required this.bold,
    this.after = '',
  });

  final int number;
  final String before;
  final String bold;
  final String after;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.lavender,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: AppTextStyles.label.copyWith(
              fontSize: 13,
              color: AppColors.indigo,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w400),
              children: [
                TextSpan(text: before),
                TextSpan(
                  text: bold,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: after),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
