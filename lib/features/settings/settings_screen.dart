import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/mock/mock_data.dart';
import '../../shared/widgets/widgets.dart';
import 'widgets/identity_card.dart';
import 'widgets/settings_group.dart';

/// Screen 9: Settings.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // TODO: load and save these in local storage.
  bool _wifiDirect = true;
  bool _visible = true;
  bool _hidePreview = true;
  bool _appLock = false;
  bool _blockScreenshots = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSoft,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text('Settings', style: AppTextStyles.h1),
            ),
            const SizedBox(height: 16),
            IdentityCard(
              me: MockData.me,
              // TODO: new uuid in flutter_secure_storage.
              onNewId: () {},
            ),
            const SizedBox(height: 14),
            SettingsGroup(
              title: 'CONNECTION',
              children: [
                const SettingsTile(
                  title: 'Bluetooth',
                  subtitle: 'Always on while TB Chat runs',
                  trailing: RequiredTag(),
                ),
                SettingsTile.toggle(
                  title: 'Wi-Fi Direct / Hotspot',
                  subtitle: 'Faster messages & files when available',
                  value: _wifiDirect,
                  onChanged: (v) => setState(() => _wifiDirect = v),
                ),
                SettingsTile.toggle(
                  title: 'Visible to nearby',
                  subtitle: 'Others can find and request you',
                  value: _visible,
                  onChanged: (v) => setState(() => _visible = v),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SettingsGroup(
              title: 'PRIVACY',
              children: [
                SettingsTile.toggle(
                  title: 'Hide message preview',
                  subtitle: 'Notifications say “New message” only',
                  value: _hidePreview,
                  onChanged: (v) => setState(() => _hidePreview = v),
                ),
                SettingsTile.toggle(
                  title: 'App lock',
                  subtitle: 'PIN or fingerprint to open',
                  value: _appLock,
                  onChanged: (v) => setState(() => _appLock = v),
                ),
                SettingsTile.toggle(
                  title: 'Block screenshots',
                  subtitle: 'Inside chats',
                  value: _blockScreenshots,
                  onChanged: (v) => setState(() => _blockScreenshots = v),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: SettingsTile(
                title: 'Erase everything',
                subtitle: 'Unpair all · delete chats · new ID',
                titleColor: AppColors.pinkDark,
                trailing: const AppIcon(
                  AppIcons.chevronRight,
                  size: 18,
                  color: AppColors.pinkDark,
                ),
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
