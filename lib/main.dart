import 'package:flutter/material.dart';

import 'data/chat_db.dart';
import 'data/identity.dart';
import 'data/prefs.dart';
import 'screens/home_shell.dart';
import 'screens/permission_denied_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/nearby_scanner.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Identity.load();
  await Prefs.load();
  await ChatDb.instance.open();
  final Widget start = !Identity.onboarded
      ? const WelcomeScreen()
      : await NearbyScanner.instance.hasPermissions()
          ? const HomeShell()
          : const PermissionDeniedScreen();
  runApp(TbChatApp(start: start));
}

class TbChatApp extends StatelessWidget {
  const TbChatApp({super.key, required this.start});

  final Widget start;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TB Chat',
      debugShowCheckedModeBanner: false,
      theme: TB.theme(),
      home: start,
    );
  }
}
