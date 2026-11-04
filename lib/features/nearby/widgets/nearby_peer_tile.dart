import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/nearby_peer.dart';
import '../../../shared/widgets/widgets.dart';

class NearbyPeerTile extends StatelessWidget {
  const NearbyPeerTile({
    super.key,
    required this.nearby,
    required this.onPair,
    required this.onMessage,
  });

  final NearbyPeer nearby;
  final VoidCallback onPair;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          AnonAvatar(peer: nearby.peer, size: 46, fontSize: 14),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nearby.peer.name, style: AppTextStyles.bodyStrong),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const AppIcon(
                      AppIcons.signal,
                      size: 14,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 6),
                    Text(nearby.distance, style: AppTextStyles.caption),
                  ],
                ),
              ],
            ),
          ),
          switch (nearby.state) {
            PairState.notPaired => GradientButton(
              label: 'Pair',
              expand: false,
              height: 38,
              radius: 12,
              fontSize: 14,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              gradient: AppGradients.pinkIndigoHorizontal,
              onPressed: onPair,
            ),
            PairState.waiting => const _SmallButton(
              label: 'Waiting…',
              background: AppColors.lavender,
            ),
            PairState.paired => _SmallButton(
              label: 'Message',
              background: AppColors.white,
              outlined: true,
              onTap: onMessage,
            ),
          },
        ],
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({
    required this.label,
    required this.background,
    this.outlined = false,
    this.onTap,
  });

  final String label;
  final Color background;
  final bool outlined;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: outlined
          ? const BorderSide(color: AppColors.indigo, width: 1.5)
          : BorderSide.none,
    );
    return Material(
      color: background,
      shape: shape,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.label.copyWith(color: AppColors.indigo),
          ),
        ),
      ),
    );
  }
}
