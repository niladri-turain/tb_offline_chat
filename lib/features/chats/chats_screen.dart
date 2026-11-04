import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_assets.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/mock/mock_data.dart';
import '../../shared/widgets/widgets.dart';
import 'widgets/chat_filter_chips.dart';
import 'widgets/chat_list_tile.dart';
import 'widgets/connection_banner.dart';

/// Screen 4: Chats list (home tab).
class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  ChatFilter _filter = ChatFilter.all;

  @override
  Widget build(BuildContext context) {
    final chats = MockData.conversations.where(
      (c) => switch (_filter) {
        ChatFilter.all => true,
        ChatFilter.unread => c.unread > 0,
        ChatFilter.inRange => c.inRange,
      },
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                children: [
                  _MyAvatar(initials: MockData.me.initials),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Chats', style: AppTextStyles.h1),
                  ),
                  SquareIconButton(
                    icon: AppIcons.search,
                    tooltip: 'Search chats',
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: ConnectionBanner(
                text: 'Offline mode · Bluetooth on · Visible',
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: ChatFilterChips(
                selected: _filter,
                onSelected: (f) => setState(() => _filter = f),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 96),
                children: [
                  for (final c in chats)
                    ChatListTile(
                      conversation: c,
                      onTap: () => context.push(AppRoutes.chatWith(c.peer.id)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: GradientButton(
        label: 'Find nearby',
        expand: false,
        radius: 28,
        fontSize: 16,
        shadow: true,
        icon: const AppIcon(AppIcons.radar, color: AppColors.white),
        gradient: AppGradients.button,
        onPressed: () => context.push(AppRoutes.nearby),
      ),
    );
  }
}

/// My own avatar: gradient ring around a lavender circle.
class _MyAvatar extends StatelessWidget {
  const _MyAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.pinkIndigo,
      ),
      child: Container(
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.lavenderAvatar,
        ),
        child: Text(
          initials,
          style: AppTextStyles.label.copyWith(
            fontSize: 13,
            color: AppColors.indigo,
          ),
        ),
      ),
    );
  }
}
