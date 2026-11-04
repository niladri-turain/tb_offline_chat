import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/widgets.dart';

/// Screen 10: Groups, not built yet.
class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                children: [
                  const Text('Groups', style: AppTextStyles.h1),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.lavender,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Coming soon',
                      style: AppTextStyles.small.copyWith(
                        color: AppColors.indigo,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _GroupIllustration(),
                    const SizedBox(height: 32),
                    const Text(
                      'Anonymous group chats',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Talk with up to 8 paired people nearby at once. '
                      'Messages hop phone to phone, no internet needed.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: 28),
                    const SoftButton(
                      label: 'Create a group · soon',
                      fontSize: 16,
                      onPressed: null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Three gradient circles and a "+" circle.
class _GroupIllustration extends StatelessWidget {
  const _GroupIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 140,
      child: Stack(
        children: [
          _circle(70, 0, gradient: AppGradients.avatars[0]),
          _circle(10, 60, gradient: AppGradients.avatars[1]),
          _circle(130, 60, gradient: AppGradients.avatars[3]),
          _circle(
            70,
            76,
            color: AppColors.lavenderStrong,
            child: const AppIcon(
              AppIcons.plus,
              size: 24,
              color: AppColors.indigo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(
    double left,
    double top, {
    Gradient? gradient,
    Color? color,
    Widget? child,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: 60,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: gradient,
          color: color,
          border: Border.all(color: AppColors.white, width: 4),
        ),
        child: child,
      ),
    );
  }
}
