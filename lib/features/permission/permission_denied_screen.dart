import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/widgets.dart';
import 'widgets/fix_step.dart';

/// Screen 3: the app stops here until permission is given.
class PermissionDeniedScreen extends StatelessWidget {
  const PermissionDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 72, 28, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 96,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.pinkSoft,
                          shape: BoxShape.circle,
                        ),
                        child: const AppIcon(
                          AppIcons.bluetoothOff,
                          size: 52,
                          color: AppColors.pinkDark,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        "TB Chat can't start\nwithout Bluetooth",
                        textAlign: TextAlign.center,
                        style: AppTextStyles.h2.copyWith(
                          fontSize: 26,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Permission was turned off. Turn it on in your "
                        "phone's settings, then come back.",
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body,
                      ),
                      const SizedBox(height: 28),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.borderLavender),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('HOW TO FIX', style: AppTextStyles.overline),
                            SizedBox(height: 14),
                            FixStep(
                              number: 1,
                              before: 'Tap ',
                              bold: 'Open settings',
                              after: ' below',
                            ),
                            SizedBox(height: 14),
                            FixStep(
                              number: 2,
                              before: 'Go to ',
                              bold: 'Permissions → Nearby devices',
                            ),
                            SizedBox(height: 14),
                            FixStep(
                              number: 3,
                              before: 'Choose ',
                              bold: 'Allow',
                              after: ', then return to TB Chat',
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(height: 24),
                      GradientButton(
                        label: 'Open settings',
                        // TODO: openAppSettings() from permission_handler.
                        onPressed: () {},
                      ),
                      const SizedBox(height: 12),
                      SoftButton(
                        label: 'Try again',
                        // TODO: re-check permissions, go to chats if granted.
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
