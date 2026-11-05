import 'package:flutter/material.dart';

import '../theme.dart';
import 'permission_denied_screen.dart';

/// Our own explanation, shown before the system permission dialogs on first launch.
class BluetoothSheet extends StatefulWidget {
  const BluetoothSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const BluetoothSheet(),
      );

  @override
  State<BluetoothSheet> createState() => _BluetoothSheetState();
}

class _BluetoothSheetState extends State<BluetoothSheet> {
  bool _busy = false;

  Future<void> _allow() async {
    setState(() => _busy = true);
    final navigator = Navigator.of(context);
    if (await requestAccessAndEnter(navigator)) return;
    navigator.pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const PermissionDeniedScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(color: TB.lavenderDeep, borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(height: 24),
              Container(
                width: 76,
                height: 76,
                alignment: Alignment.center,
                decoration: BoxDecoration(gradient: TB.brandGradient, borderRadius: BorderRadius.circular(24)),
                child: const Icon(Icons.bluetooth, size: 38, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text('Bluetooth is required',
                  textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'TB Chat has no server. It finds people nearby and sends messages straight from your phone to theirs.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 22),
              const FeatureTile(
                icon: Icons.bluetooth,
                iconColor: TB.pink,
                title: 'Bluetooth',
                subtitle: 'Find and pair with people around you',
              ),
              const SizedBox(height: 10),
              const FeatureTile(
                icon: Icons.wifi,
                iconColor: TB.purple,
                title: 'Nearby devices & Wi-Fi',
                subtitle: 'Faster messages over Wi-Fi Direct or hotspot',
              ),
              const SizedBox(height: 10),
              const FeatureTile(
                icon: Icons.location_on_outlined,
                iconColor: TB.indigo,
                title: 'Location (older Android only)',
                subtitle: 'Android needs it to scan. Never stored or shared.',
              ),
              const SizedBox(height: 24),
              GradientButton(label: 'Allow & turn on Bluetooth', onPressed: _busy ? null : _allow),
              const SizedBox(height: 12),
              const Text("The app can't run without these permissions.",
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: TB.muted)),
            ],
          ),
        ),
      ),
    );
  }
}
