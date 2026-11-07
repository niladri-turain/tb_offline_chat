import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/identity.dart';
import '../services/nearby_scanner.dart';
import '../theme.dart';
import 'home_shell.dart';

/// Asks for the permissions, then opens Home. False if something was refused.
Future<bool> requestAccessAndEnter(NavigatorState navigator) async {
  final scanner = NearbyScanner.instance;
  final results = await scanner.requestPermissions();
  if (results.values.any((s) => !s.isGranted)) return false;
  await scanner.ensureBluetoothOn();
  await Identity.finishOnboarding();
  navigator.pushAndRemoveUntil(MaterialPageRoute<void>(builder: (_) => const HomeShell()), (_) => false);
  return true;
}

/// The app stops here until the permissions are given.
class PermissionDeniedScreen extends StatefulWidget {
  const PermissionDeniedScreen({super.key});

  @override
  State<PermissionDeniedScreen> createState() => _PermissionDeniedScreenState();
}

class _PermissionDeniedScreenState extends State<PermissionDeniedScreen> {
  late final AppLifecycleListener _lifecycle;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Coming back from the phone's settings: carry on by itself if the permissions are on now.
    _lifecycle = AppLifecycleListener(onResume: _recheck);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _recheck() async {
    if (_busy || !await NearbyScanner.instance.hasPermissions()) return;
    await _tryAgain();
  }

  Future<void> _tryAgain() async {
    if (_busy || !mounted) return;
    _busy = true;
    if (!await requestAccessAndEnter(Navigator.of(context))) _busy = false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 72, 28, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 96),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: TB.pinkSoft, shape: BoxShape.circle),
                        child: const Icon(Icons.bluetooth_disabled, size: 52, color: TB.pinkDark),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        "TB Chat can't start\nwithout Bluetooth",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: TB.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 26,
                            height: 1.25,
                            color: TB.ink),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Permission was turned off. Turn it on in your phone's settings, then come back.",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 28),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          border: Border.all(color: TB.borderLavender),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('HOW TO FIX',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    letterSpacing: 0.6,
                                    color: TB.muted)),
                            const SizedBox(height: 14),
                            const _FixStep(number: 1, before: 'Tap ', bold: 'Open settings', after: ' below'),
                            const SizedBox(height: 14),
                            if (Platform.isIOS) ...[
                              const _FixStep(number: 2, before: 'Turn on ', bold: 'Bluetooth'),
                              const SizedBox(height: 14),
                              const _FixStep(number: 3, before: 'Return to ', bold: 'TB Chat'),
                            ] else ...[
                              const _FixStep(number: 2, before: 'Go to ', bold: 'Permissions → Nearby devices'),
                              const SizedBox(height: 14),
                              const _FixStep(number: 3, before: 'Choose ', bold: 'Allow', after: ', then return to TB Chat'),
                            ],
                          ],
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(height: 24),
                      const GradientButton(label: 'Open settings', onPressed: openAppSettings),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 56,
                        width: double.infinity,
                        child: Material(
                          color: TB.lavender,
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            onTap: _tryAgain,
                            borderRadius: BorderRadius.circular(18),
                            child: const Center(
                              child: Text('Try again',
                                  style: TextStyle(
                                      fontFamily: TB.display,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 17,
                                      color: TB.indigo)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Numbered "How to fix" line with one bold part.
class _FixStep extends StatelessWidget {
  const _FixStep({required this.number, required this.before, required this.bold, this.after = ''});

  final int number;
  final String before;
  final String bold;
  final String after;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: TB.lavender, shape: BoxShape.circle),
          child: Text('$number',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: TB.indigo)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 14, color: TB.ink),
              children: [
                TextSpan(text: before),
                TextSpan(text: bold, style: const TextStyle(fontWeight: FontWeight.w600)),
                TextSpan(text: after),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
