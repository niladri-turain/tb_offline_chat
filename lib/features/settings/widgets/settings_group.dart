import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/widgets.dart';

/// "CONNECTION" / "PRIVACY" label followed by a white rounded card of rows.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 4, 6, 14),
          child: Text(title, style: AppTextStyles.overline),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              for (final (i, child) in children.indexed) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.divider),
                child,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.titleColor = AppColors.ink,
    this.onTap,
  });

  /// A row with an [AppToggle] on the right.
  SettingsTile.toggle({
    super.key,
    required this.title,
    required this.subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) : trailing = AppToggle(value: value, onChanged: onChanged),
       titleColor = AppColors.ink,
       onTap = null;

  final String title;
  final String subtitle;
  final Widget? trailing;
  final Color titleColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyStrong.copyWith(color: titleColor),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.small),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          ],
        ),
      ),
    );
  }
}

/// Green "Required" tag for settings that can't be turned off.
class RequiredTag extends StatelessWidget {
  const RequiredTag({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Required',
        style: AppTextStyles.small.copyWith(
          color: AppColors.successDark,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
