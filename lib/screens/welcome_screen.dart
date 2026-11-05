import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';
import 'bluetooth_sheet.dart';

/// First-launch screen. "Get started" opens the Bluetooth sheet.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 48, 28, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 72),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    const _Hero(),
                    const SizedBox(height: 48),
                    const Text('TB Chat',
                        style: TextStyle(
                            fontFamily: TB.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 34,
                            letterSpacing: -0.5,
                            color: TB.ink)),
                    const SizedBox(height: 8),
                    const Text('Anonymous chat with people nearby.\nNo internet. No account.',
                        textAlign: TextAlign.center, style: TextStyle(fontSize: 17, color: TB.muted)),
                    const SizedBox(height: 40),
                    const FeatureTile(
                      boxed: true,
                      icon: Icons.bluetooth,
                      iconColor: TB.pink,
                      title: 'Works offline',
                      subtitle: 'Bluetooth & Wi-Fi Direct, phone to phone',
                    ),
                    const SizedBox(height: 14),
                    const FeatureTile(
                      boxed: true,
                      icon: Icons.visibility_off_outlined,
                      iconColor: TB.purple,
                      title: 'Fully anonymous',
                      subtitle: 'No name, no number, just a random ID',
                    ),
                    const SizedBox(height: 14),
                    const FeatureTile(
                      boxed: true,
                      icon: Icons.lock_outline,
                      iconColor: TB.indigo,
                      title: 'Stays on your phone',
                      subtitle: 'Chats are saved only here, never online',
                    ),
                    const Spacer(),
                    const SizedBox(height: 24),
                    GradientButton(label: 'Get started', onPressed: () => BluetoothSheet.show(context)),
                    const SizedBox(height: 14),
                    const Text('Your random ID is created on this phone only.',
                        textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: TB.muted)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tilted gradient chat card with a lavender Bluetooth card in front.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      height: 128,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Transform.rotate(
              angle: -8 * math.pi / 180,
              child: Container(
                width: 112,
                height: 88,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
                decoration: BoxDecoration(gradient: TB.brandGradient, borderRadius: BorderRadius.circular(22)),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [_Line(width: 70), SizedBox(height: 10), _Line(width: 46)],
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 100,
              height: 76,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: TB.lavenderDeep, borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.bluetooth, size: 34, color: TB.indigo),
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 9,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}
