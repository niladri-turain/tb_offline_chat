import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../shared/widgets/widgets.dart';

/// Tilted gradient chat card with a lavender Bluetooth card in front.
class WelcomeHero extends StatelessWidget {
  const WelcomeHero({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      height: 128,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Transform.rotate(
              angle: -8 * math.pi / 180,
              child: Container(
                width: 112,
                height: 88,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  gradient: AppGradients.brand,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Line(width: 70),
                    SizedBox(height: 10),
                    _Line(width: 46),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 100,
              height: 76,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.lavenderStrong,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const AppIcon(
                AppIcons.bluetooth,
                size: 34,
                color: AppColors.indigo,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 9,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}
