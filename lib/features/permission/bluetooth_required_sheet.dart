import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_assets.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/widgets.dart';

/// Screen 2: our own explanation, shown before the system permission dialog.
class BluetoothRequiredSheet extends StatelessWidget {
  const BluetoothRequiredSheet({super.key});

  static Future<void> show(BuildContext context) =>
      showAppBottomSheet(context, child: const BluetoothRequiredSheet());

  // TODO: request Bluetooth scan/advertise/connect, nearby Wi-Fi devices
  // and (Android ≤ 11) location, then ask to turn Bluetooth on.
  Future<bool> _requestPermissions() async => true;

  Future<void> _allow(BuildContext context) async {
    final router = GoRouter.of(context);
    final granted = await _requestPermissions();
    if (!context.mounted) return;
    Navigator.of(context).pop();
    router.go(granted ? AppRoutes.chats : AppRoutes.permissionDenied);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 24),
        Container(
          width: 76,
          height: 76,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: AppGradients.brand,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const AppIcon(
            AppIcons.bluetooth,
            size: 38,
            color: AppColors.white,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Bluetooth is required',
          textAlign: TextAlign.center,
          style: AppTextStyles.h2,
        ),
        const SizedBox(height: 8),
        const Text(
          'TB Chat has no server. It finds people nearby and sends messages '
          'straight from your phone to theirs.',
          textAlign: TextAlign.center,
          style: AppTextStyles.body,
        ),
        const SizedBox(height: 22),
        const FeatureTile(
          icon: AppIcons.bluetooth,
          iconColor: AppColors.pink,
          title: 'Bluetooth',
          subtitle: 'Find and pair with people around you',
        ),
        const SizedBox(height: 10),
        const FeatureTile(
          icon: AppIcons.wifi,
          iconColor: AppColors.purple,
          title: 'Nearby devices & Wi-Fi',
          subtitle: 'Faster messages over Wi-Fi Direct or hotspot',
        ),
        const SizedBox(height: 10),
        const FeatureTile(
          icon: AppIcons.location,
          iconColor: AppColors.indigo,
          title: 'Location (older Android only)',
          subtitle: 'Android needs it to scan. Never stored or shared.',
        ),
        const SizedBox(height: 24),
        GradientButton(
          label: 'Allow & turn on Bluetooth',
          onPressed: () => _allow(context),
        ),
        const SizedBox(height: 12),
        const Text(
          "The app can't run without these permissions.",
          textAlign: TextAlign.center,
          style: AppTextStyles.small,
        ),
      ],
    );
  }
}
