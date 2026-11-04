import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/peer.dart';

/// Round gradient avatar with the first two characters of the anon ID.
class AnonAvatar extends StatelessWidget {
  const AnonAvatar({
    super.key,
    required this.peer,
    this.size = 52,
    this.fontSize = 16,
    this.whiteBorder = 0,
    this.ring,
    this.online = false,
  });

  final Peer peer;
  final double size;
  final double fontSize;

  /// White outline width, used on the radar.
  final double whiteBorder;

  /// Soft colored halo around the avatar (pair request).
  final Color? ring;

  /// Green dot in the bottom-right corner when the peer is in range.
  final bool online;

  @override
  Widget build(BuildContext context) {
    final circle = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.forId(peer.id),
        border: whiteBorder > 0
            ? Border.all(color: AppColors.white, width: whiteBorder)
            : null,
        boxShadow: ring == null
            ? null
            : [BoxShadow(color: ring!, spreadRadius: 8)],
      ),
      child: Text(
        peer.initials,
        style: AppTextStyles.button.copyWith(
          fontSize: fontSize,
          color: AppColors.white,
        ),
      ),
    );

    if (!online) return circle;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          circle,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
