import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/peer.dart';
import '../../../shared/widgets/widgets.dart';

/// Three rings with "You" in the middle and nearby people around it.
class RadarView extends StatelessWidget {
  const RadarView({super.key, required this.peers});

  final List<Peer> peers;

  static const _size = 300.0;

  // Spots on the radar, from the design. (left, top, diameter)
  static const _slots = [
    (196.0, 64.0, 44.0),
    (34.0, 170.0, 44.0),
    (214.0, 232.0, 40.0),
    (60.0, 52.0, 40.0),
    (120.0, 236.0, 40.0),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        children: [
          _ring(0, AppColors.radarOuter, AppColors.radarOuterFill),
          _ring(50, AppColors.radarMiddle, null),
          _ring(100, AppColors.radarInner, AppColors.radarInnerFill),
          Positioned(
            left: 122,
            top: 122,
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.pinkIndigo,
                boxShadow: [
                  BoxShadow(color: Color(0x1FE0067F), spreadRadius: 8),
                ],
              ),
              child: Text(
                'You',
                style: AppTextStyles.button.copyWith(
                  fontSize: 13,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          for (var i = 0; i < peers.length && i < _slots.length; i++)
            Positioned(
              left: _slots[i].$1,
              top: _slots[i].$2,
              child: AnonAvatar(
                peer: peers[i],
                size: _slots[i].$3,
                fontSize: _slots[i].$3 > 40 ? 13 : 12,
                whiteBorder: 3,
              ),
            ),
        ],
      ),
    );
  }

  Widget _ring(double inset, Color border, Color? fill) {
    return Positioned.fill(
      left: inset,
      top: inset,
      right: inset,
      bottom: inset,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fill,
          border: Border.all(color: border, width: 1.5),
        ),
      ),
    );
  }
}
