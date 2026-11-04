import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_assets.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/mock/mock_data.dart';
import '../../shared/widgets/widgets.dart';
import 'pair_request_dialog.dart';
import 'widgets/nearby_peer_tile.dart';
import 'widgets/radar_view.dart';

/// Screen 5: scanning for people nearby.
class NearbyScreen extends StatelessWidget {
  const NearbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: startAdvertising + startDiscovery with only the anon ID as name.
    const people = MockData.nearby;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                children: [
                  SquareIconButton(
                    icon: AppIcons.back,
                    tooltip: 'Back to chats',
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go(AppRoutes.chats),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Nearby', style: AppTextStyles.h2),
                  ),
                  const _ScanningPill(),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: RadarView(peers: [for (final p in people) p.peer]),
            ),
            const SizedBox(height: 14),
            const Text(
              'Only people with TB Chat open can be found',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      '${people.length} people nearby',
                      style: AppTextStyles.title,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      'Scan again',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.indigo,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Column(
                children: [
                  for (final p in people)
                    NearbyPeerTile(
                      nearby: p,
                      // TODO: requestConnection, then show the code dialog.
                      onPair: () =>
                          PairRequestDialog.show(context, peer: p.peer),
                      onMessage: () =>
                          context.push(AppRoutes.chatWith(p.peer.id)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanningPill extends StatelessWidget {
  const _ScanningPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.pinkSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const StatusDot(color: AppColors.pink),
          const SizedBox(width: 6),
          Text(
            'Scanning',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.pinkDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
