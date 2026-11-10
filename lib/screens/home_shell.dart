import 'dart:async';

import 'package:flutter/material.dart';

import '../data/chat_db.dart';
import '../services/chat_service.dart';
import '../services/nearby_scanner.dart';
import '../theme.dart';
import 'chat_screen.dart';
import 'chats_screen.dart';
import 'groups_screen.dart';
import 'nearby_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  bool _holdingRadios = false;
  late final StreamSubscription<String> _unpaired;

  @override
  void initState() {
    super.initState();
    ChatDb.instance.addListener(_syncRadios);
    _syncRadios();
    _unpaired = ChatService.instance.unpairedByPeer.listen((peerId) {
      if (mounted) showUnpairedDialog(context, peerId);
    });
  }

  @override
  void dispose() {
    ChatDb.instance.removeListener(_syncRadios);
    _unpaired.cancel();
    if (_holdingRadios) NearbyScanner.instance.release();
    super.dispose();
  }

  /// Messages can only arrive while the radios run, so they stay on once someone is paired.
  Future<void> _syncRadios() async {
    final needed = await ChatDb.instance.hasContacts();
    if (!mounted || needed == _holdingRadios) return;
    _holdingRadios = needed;
    needed ? NearbyScanner.instance.acquire() : NearbyScanner.instance.release();
  }

  @override
  Widget build(BuildContext context) {
    // Nearby is built only while its tab is open; with nobody paired, the radios scan only then.
    final body = switch (_tab) {
      0 => ChatsScreen(onFindNearby: () => setState(() => _tab = 1)),
      1 => const NearbyScreen(),
      2 => const GroupsScreen(),
      _ => const SettingsScreen(),
    };
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: TB.pinkSoft,
          labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
                fontSize: 12,
                fontWeight: s.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
                color: s.contains(WidgetState.selected) ? TB.pinkDark : TB.navInactive,
              )),
          iconTheme: WidgetStateProperty.resolveWith(
              (s) => IconThemeData(color: s.contains(WidgetState.selected) ? TB.pinkDark : TB.navInactive)),
        ),
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Chats'),
            NavigationDestination(icon: Icon(Icons.wifi_tethering), label: 'Nearby'),
            NavigationDestination(icon: Icon(Icons.group_outlined), label: 'Groups'),
            NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}
