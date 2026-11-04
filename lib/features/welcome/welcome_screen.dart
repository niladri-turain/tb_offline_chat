import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/widgets.dart';
import '../permission/bluetooth_required_sheet.dart';
import 'widgets/welcome_hero.dart';

/// Screen 1: Welcome.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 48, 28, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 72,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    const WelcomeHero(),
                    const SizedBox(height: 48),
                    const Text('TB Chat', style: AppTextStyles.display),
                    const SizedBox(height: 8),
                    const Text(
                      'Anonymous chat with people nearby.\n'
                      'No internet. No account.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyLarge,
                    ),
                    const SizedBox(height: 40),
                    const FeatureTile(
                      boxed: true,
                      icon: AppIcons.bluetooth,
                      iconColor: AppColors.pink,
                      title: 'Works offline',
                      subtitle: 'Bluetooth & Wi-Fi Direct, phone to phone',
                    ),
                    const SizedBox(height: 14),
                    const FeatureTile(
                      boxed: true,
                      icon: AppIcons.anonymous,
                      iconColor: AppColors.purple,
                      title: 'Fully anonymous',
                      subtitle: 'No name, no number, just a random ID',
                    ),
                    const SizedBox(height: 14),
                    const FeatureTile(
                      boxed: true,
                      icon: AppIcons.trash,
                      iconColor: AppColors.indigo,
                      title: 'Nothing is kept',
                      subtitle: 'Unpair and every message is erased',
                    ),
                    const Spacer(),
                    const SizedBox(height: 24),
                    GradientButton(
                      label: 'Get started',
                      shadow: true,
                      onPressed: () => BluetoothRequiredSheet.show(context),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Your random ID is created on this phone only.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.small,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
