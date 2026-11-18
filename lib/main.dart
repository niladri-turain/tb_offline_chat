import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/di/locator.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'theme.dart';
import 'widgets/app_toast.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupLocator();
  // The splash screen loads the session, ID, settings and chats, then picks the first screen.
  runApp(const TbChatApp());
}

class TbChatApp extends StatelessWidget {
  const TbChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: locator<AuthProvider>(),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'TB Chat',
        debugShowCheckedModeBanner: false,
        theme: TB.theme(),
        home: const SplashScreen(),
      ),
    );
  }
}
