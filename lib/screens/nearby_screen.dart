import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/chat_db.dart';
import '../services/nearby_scanner.dart';
import '../theme.dart';
import 'pair_dialog.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final NearbyScanner _scanner = NearbyScanner.instance;
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  Set<String> _paired = {};
  late final StreamSubscription<PairEvent> _pairEvents;

  /// Endpoint whose pair popup is open, so it can be closed when the request ends on its own.
  String? _dialogEndpoint;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ChatDb.instance.addListener(_loadPaired);
    _loadPaired();
    _pairEvents = _scanner.events.listen(_onPairEvent);
    _scanner.acquire();
  }

  Future<void> _loadPaired() async {
    final ids = await ChatDb.instance.pairedPeerIds();
    if (mounted) setState(() => _paired = ids);
  }

  Future<void> _onPairEvent(PairEvent event) async {
    switch (event) {
      case PairRequested(:final endpointId, :final peerId, :final code):
        final accept = await _showPairDialog(endpointId, peerId, code, incoming: true);
        if (accept == true) {
          _scanner.acceptRequest(endpointId);
        } else if (accept == false) {
          _scanner.declineRequest(endpointId);
        }
      case PairWaiting(:final endpointId, :final peerId, :final code):
        final result = await _showPairDialog(endpointId, peerId, code, incoming: false);
        if (result == false) _scanner.cancelPair(endpointId);
      case PairFinished(:final endpointId, :final peerId, :final paired):
        if (_dialogEndpoint == endpointId && mounted) Navigator.of(context).pop();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(paired
              ? 'Paired with ${anonName(peerId)}. Find them in Chats.'
              : 'Pairing with ${anonName(peerId)} didn\'t go through.'),
        ));
    }
  }

  Future<bool?> _showPairDialog(String endpointId, String peerId, String code, {required bool incoming}) async {
    if (!mounted) return null;
    _dialogEndpoint = endpointId;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PairDialog(peerId: peerId, code: code, incoming: incoming),
    );
    if (_dialogEndpoint == endpointId) _dialogEndpoint = null;
    return result;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from system settings: try again if something was blocking the scan.
    if (state == AppLifecycleState.resumed && _scanner.status != ScanStatus.scanning) _scanner.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ChatDb.instance.removeListener(_loadPaired);
    _pairEvents.cancel();
    _pulse.dispose();
    _scanner.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: _scanner,
        builder: (context, _) {
          final peers = _scanner.peers;
          final scanning = _scanner.status == ScanStatus.scanning || _scanner.status == ScanStatus.starting;
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _header(context, scanning),
              const SizedBox(height: 20),
              Center(child: _Radar(pulse: _pulse, peers: peers, active: scanning)),
              if (!scanning)
                _Problem(scanner: _scanner)
              else if (peers.isEmpty)
                const _LookingText()
              else ...[
                const Padding(
                  padding: EdgeInsets.only(top: 14),
                  child: Text('Only people with TB Chat open can be found',
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: TB.muted)),
                ),
                _listHeader(context, peers.length),
                for (final p in peers)
                  _PeerRow(
                    peer: p,
                    paired: _paired.contains(p.peerId),
                    waiting: _scanner.isWaiting(p.endpointId),
                    onPair: () => _scanner.pair(p),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _header(BuildContext context, bool scanning) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(child: Text('Nearby', style: Theme.of(context).textTheme.titleLarge)),
          if (scanning)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: TB.pinkSoft, borderRadius: BorderRadius.circular(14)),
              child: const Row(
                children: [
                  CircleAvatar(radius: 4, backgroundColor: TB.pink),
                  SizedBox(width: 6),
                  Text('Scanning', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: TB.pinkDark)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _listHeader(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(count == 1 ? '1 person nearby' : '$count people nearby',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          TextButton(
            onPressed: _scanner.rescan,
            child: const Text('Scan again', style: TextStyle(color: TB.indigo, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

/// Concentric circles with "You" in the middle. Found peers sit on the rings; nothing else is drawn.
class _Radar extends StatelessWidget {
  const _Radar({required this.pulse, required this.peers, required this.active});

  final Animation<double> pulse;
  final List<NearbyPeer> peers;
  final bool active;

  static const double _size = 300;

  @override
  Widget build(BuildContext context) {
    Widget ring(double inset, Color border, [Color? fill]) => Positioned.fill(
          left: inset,
          top: inset,
          right: inset,
          bottom: inset,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fill,
              border: Border.all(color: border, width: 1.5),
            ),
          ),
        );

    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        children: [
          ring(0, const Color(0xFFECE8FD), const Color(0xFFFBFAFF)),
          ring(50, const Color(0xFFE1DBFC)),
          ring(100, const Color(0xFFD2C9FA), const Color(0xFFF3F0FE)),
          if (active)
            AnimatedBuilder(
              animation: pulse,
              builder: (context, _) {
                final inset = 100 * (1 - pulse.value);
                return ring(inset, TB.pink.withValues(alpha: 0.35 * (1 - pulse.value)));
              },
            ),
          for (var i = 0; i < peers.length; i++) _placed(peers[i], i),
          Center(
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [TB.pink, TB.indigo]),
                boxShadow: [BoxShadow(color: Color(0x1FE0067F), spreadRadius: 8)],
              ),
              child: const Text('You',
                  style: TextStyle(
                      fontFamily: TB.display, fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placed(NearbyPeer peer, int index) {
    // Spread peers around the two outer rings at stable angles.
    final angle = -pi / 3 + index * 2.4;
    final radius = index.isEven ? 100.0 : 128.0;
    const dot = 44.0;
    return Positioned(
      left: _size / 2 + radius * cos(angle) - dot / 2,
      top: _size / 2 + radius * sin(angle) - dot / 2,
      child: Container(
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
        padding: const EdgeInsets.all(3),
        child: AnonAvatar(peerId: peer.peerId, size: dot - 6),
      ),
    );
  }
}

class _LookingText extends StatelessWidget {
  const _LookingText();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 0),
      child: Column(
        children: [
          Text('Looking for people nearby…',
              textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text("Ask the other person to open TB Chat and keep Bluetooth on. They'll appear on the radar.",
              textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _PeerRow extends StatelessWidget {
  const _PeerRow({required this.peer, required this.paired, required this.waiting, required this.onPair});

  final NearbyPeer peer;
  final bool paired;
  final bool waiting;
  final VoidCallback onPair;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          AnonAvatar(peerId: peer.peerId, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(anonName(peer.peerId),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: TB.ink)),
                const SizedBox(height: 2),
                const Text('In range', style: TextStyle(fontSize: 13, color: TB.muted)),
              ],
            ),
          ),
          if (paired)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: TB.greenSoft, borderRadius: BorderRadius.circular(10)),
              child: const Text('Paired',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: TB.greenDark)),
            )
          else if (waiting)
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: TB.lavender, borderRadius: BorderRadius.circular(12)),
              child: const Text('Waiting…',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: TB.indigo)),
            )
          else
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [TB.pink, TB.indigo]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  minimumSize: const Size(72, 38),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onPair,
                child: const Text('Pair', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Why scanning isn't running, and the one action that fixes it.
class _Problem extends StatelessWidget {
  const _Problem({required this.scanner});

  final NearbyScanner scanner;

  @override
  Widget build(BuildContext context) {
    final (title, body, action, onTap) = switch (scanner.status) {
      ScanStatus.permissionDenied => (
          'Permission needed',
          'TB Chat needs Nearby devices and Location permission to find people around you. Location is never stored or shared.',
          scanner.permanentlyDenied ? 'Open settings' : 'Allow',
          scanner.permanentlyDenied ? openAppSettings : scanner.start,
        ),
      ScanStatus.bluetoothOff => (
          'Bluetooth is off',
          'Turn on Bluetooth to find people nearby.',
          'Turn on Bluetooth',
          scanner.start,
        ),
      ScanStatus.locationOff => (
          'Location is off',
          'On this Android version, scanning only works with Location turned on. It is never stored or shared.',
          'Try again',
          scanner.start,
        ),
      _ => (
          "Couldn't start scanning",
          'Something went wrong with Bluetooth or Wi-Fi. Try again.'
              '${scanner.failure == null ? '' : '\n\nError: ${scanner.failure}'}',
          'Try again',
          scanner.rescan,
        ),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 0),
      child: Column(
        children: [
          Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(body, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 20),
          GradientButton(label: action, onPressed: () => onTap()),
        ],
      ),
    );
  }
}
