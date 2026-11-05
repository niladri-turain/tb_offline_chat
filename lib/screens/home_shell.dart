import 'package:flutter/material.dart';

import '../theme.dart';
import 'chats_screen.dart';
import 'groups_screen.dart';
import 'nearby_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    // Nearby is built only while its tab is open, so the radios scan only then.
    final body = switch (_tab) {
      0 => ChatsScreen(onFindNearby: () => setState(() => _tab = 1)),
      1 => const NearbyScreen(),
      2 => const GroupsScreen(),
      _ => const _ComingSoon(title: 'Settings', text: 'Your anonymous ID and privacy options.'),
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

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: TB.lavender, borderRadius: BorderRadius.circular(10)),
                      child: const Text('Coming soon',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: TB.indigo)),
                    ),
                    const SizedBox(height: 12),
                    Text(text, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
