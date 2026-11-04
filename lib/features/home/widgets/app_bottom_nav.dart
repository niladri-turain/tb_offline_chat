import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/widgets.dart';

enum NavTab {
  chats('Chats', AppIcons.chat),
  nearby('Nearby', AppIcons.radar),
  groups('Groups', AppIcons.groups),
  settings('Settings', AppIcons.settings);

  const NavTab(this.label, this.icon);
  final String label;
  final String icon;
}

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.current, required this.onTap});

  final NavTab current;
  final ValueChanged<NavTab> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
          child: Row(
            children: [
              for (final tab in NavTab.values)
                Expanded(
                  child: _NavItem(
                    tab: tab,
                    active: tab == current,
                    onTap: () => onTap(tab),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.active,
    required this.onTap,
  });

  final NavTab tab;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.pinkDark : AppColors.inkSoft;
    return Semantics(
      button: true,
      selected: active,
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 64,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppColors.pinkSoft : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: AppIcon(tab.icon, size: 22, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              tab.label,
              style: AppTextStyles.small.copyWith(
                color: color,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
