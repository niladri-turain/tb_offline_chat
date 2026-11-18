import 'package:flutter/material.dart';

import 'data/auth.dart';
import 'data/identity.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'screens/permission_denied_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/nearby_scanner.dart';

/// The first screen to show: login, then the first-launch Welcome, then the app itself
/// (or the permission screen if Bluetooth access was taken away).
Future<Widget> appStart() async {
  if (!Auth.loggedIn) return const LoginScreen();
  if (!Identity.onboarded) return const WelcomeScreen();
  return await NearbyScanner.instance.hasPermissions() ? const HomeShell() : const PermissionDeniedScreen();
}
