import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import 'widgets/app_bottom_nav.dart';

/// Holds the Chats, Groups and Settings tabs with the bottom nav.
/// Nearby is in the nav too, but opens as its own full screen.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _branchTabs = [NavTab.chats, NavTab.groups, NavTab.settings];

  void _onTap(BuildContext context, NavTab tab) {
    if (tab == NavTab.nearby) {
      context.push(AppRoutes.nearby);
      return;
    }
    final index = _branchTabs.indexOf(tab);
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: AppBottomNav(
        current: _branchTabs[shell.currentIndex],
        onTap: (tab) => _onTap(context, tab),
      ),
    );
  }
}
