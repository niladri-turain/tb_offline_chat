import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'app_icon.dart';

/// Rounded-square icon button used in headers (search, back, attach).
class SquareIconButton extends StatelessWidget {
  const SquareIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.size = 44,
    this.radius = 14,
    this.iconSize = 20,
    this.background = AppColors.lavender,
    this.iconColor = AppColors.ink,
  });

  final String icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final double size;
  final double radius;
  final double iconSize;
  final Color background;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(radius),
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: AppIcon(icon, size: iconSize, color: iconColor),
            ),
          ),
        ),
      ),
    );
  }
}
