import 'package:go_router/go_router.dart';

import '../../features/chat/chat_screen.dart';
import '../../features/chats/chats_screen.dart';
import '../../features/groups/groups_screen.dart';
import '../../features/home/home_shell.dart';
import '../../features/nearby/nearby_screen.dart';
import '../../features/permission/permission_denied_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/welcome/welcome_screen.dart';
import 'app_routes.dart';

// Sheets and dialogs (Bluetooth required, Pair request, Unpair) are not routes.
// Each one has a static `show(context)` in its own feature folder.
final appRouter = GoRouter(
  initialLocation: AppRoutes.welcome,
  routes: [
    GoRoute(
      path: AppRoutes.welcome,
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.permissionDenied,
      builder: (context, state) => const PermissionDeniedScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => HomeShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.chats,
              builder: (context, state) => const ChatsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.groups,
              builder: (context, state) => const GroupsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.settings,
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.nearby,
      builder: (context, state) => const NearbyScreen(),
    ),
    GoRoute(
      path: AppRoutes.chat,
      builder: (context, state) =>
          ChatScreen(peerId: state.pathParameters['peerId']!),
    ),
  ],
);
