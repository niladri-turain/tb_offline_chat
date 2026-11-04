import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_text_styles.dart';

/// The main pink → indigo call-to-action button.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 56,
    this.radius = 18,
    this.fontSize = 17,
    this.gradient = AppGradients.button,
    this.shadow = false,
    this.expand = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 22),
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final double height;
  final double radius;
  final double fontSize;
  final Gradient gradient;
  final bool shadow;
  final bool expand;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    return Container(
      height: height,
      width: expand ? double.infinity : null,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: shape,
        boxShadow: shadow ? AppGradients.buttonShadow : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          borderRadius: shape,
          child: Padding(
            padding: padding,
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[icon!, const SizedBox(width: 10)],
                Text(
                  label,
                  style: AppTextStyles.button.copyWith(
                    fontSize: fontSize,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
