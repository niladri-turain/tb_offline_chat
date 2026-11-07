import 'package:flutter/material.dart';

import '../data/chat_db.dart';
import '../services/chat_service.dart';
import '../theme.dart';

/// Settings tab. For now it only manages who is blocked.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _db = ChatDb.instance;
  List<String> _blocked = [];

  @override
  void initState() {
    super.initState();
    _db.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    _db.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final blocked = await _db.blockedPeers();
    if (mounted) setState(() => _blocked = blocked);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        children: [
          Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          const Text('BLOCKED PEOPLE',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: TB.muted)),
          const SizedBox(height: 8),
          if (_blocked.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Nobody is blocked.', style: Theme.of(context).textTheme.bodyLarge),
            ),
          for (final peerId in _blocked)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  AnonAvatar(peerId: peerId, size: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(anonName(peerId),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: TB.ink)),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: TB.lavender,
                      foregroundColor: TB.indigo,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => ChatService.instance.unblock(peerId),
                    child: const Text('Unblock', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
