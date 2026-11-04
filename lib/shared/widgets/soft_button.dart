import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Flat full-width button: lavender "Try again" / "Cancel", or red "Unpair".
class SoftButton extends StatelessWidget {
  const SoftButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.background = AppColors.lavender,
    this.foreground = AppColors.indigo,
    this.height = 56,
    this.radius = 18,
    this.fontSize = 17,
  });

  const SoftButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 56,
    this.radius = 18,
    this.fontSize = 17,
  }) : background = AppColors.pinkDark,
       foreground = AppColors.white;

  final String label;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;
  final double height;
  final double radius;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(radius),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.button.copyWith(
                fontSize: fontSize,
                color: disabled ? AppColors.muted : foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
