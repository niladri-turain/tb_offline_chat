import 'package:flutter/material.dart';

import '../theme.dart';

/// Groups tab: not built yet, so it only says what's coming.
class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Row(
              children: [
                Text('Groups', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: TB.lavender, borderRadius: BorderRadius.circular(10)),
                  child: const Text('Coming soon',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: TB.indigo)),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _GroupIllustration(),
                  const SizedBox(height: 32),
                  const Text('Anonymous group chats',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: TB.display, fontWeight: FontWeight.w700, fontSize: 22, color: TB.ink)),
                  const SizedBox(height: 10),
                  Text(
                    'Talk with up to 8 paired people nearby at once. Messages hop phone to phone, no internet needed.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 28),
                  Container(
                    height: 56,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: TB.lavender, borderRadius: BorderRadius.circular(18)),
                    child: const Text('Create a group · soon',
                        style: TextStyle(
                            fontFamily: TB.display, fontWeight: FontWeight.w600, fontSize: 16, color: TB.muted)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Three gradient circles and a "+" circle.
class _GroupIllustration extends StatelessWidget {
  const _GroupIllustration();

  static const _pink = LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFE0067F), Color(0xFF8A12B8)]);
  static const _indigo = LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF3F1FD1), Color(0xFF7A5CFA)]);
  static const _orange = LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFD9480F), Color(0xFFE0067F)]);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 140,
      child: Stack(
        children: [
          _circle(70, 0, gradient: _pink),
          _circle(10, 60, gradient: _indigo),
          _circle(130, 60, gradient: _orange),
          _circle(70, 76, color: TB.lavenderDeep, child: const Icon(Icons.add, size: 24, color: TB.indigo)),
        ],
      ),
    );
  }

  Widget _circle(double left, double top, {Gradient? gradient, Color? color, Widget? child}) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: 60,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: gradient,
          color: color,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: child,
      ),
    );
  }
}
