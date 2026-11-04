/// Every route path in one place. Use these instead of raw strings.
abstract final class AppRoutes {
  static const welcome = '/';
  static const permissionDenied = '/permission-denied';

  // Bottom-nav tabs
  static const chats = '/chats';
  static const groups = '/groups';
  static const settings = '/settings';

  // Full screen, no bottom nav
  static const nearby = '/nearby';
  static const chat = '/chat/:peerId';
  static String chatWith(String peerId) => '/chat/$peerId';
}
