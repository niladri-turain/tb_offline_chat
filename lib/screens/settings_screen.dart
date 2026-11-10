import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../data/chat_db.dart';
import '../data/identity.dart';
import '../data/prefs.dart';
import '../services/chat_service.dart';
import '../theme.dart';
import 'welcome_screen.dart';

/// Settings tab: who you are, whether you can be found, who is blocked, and your data.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _db = ChatDb.instance;
  List<String> _blocked = [];
  String _version = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _db.addListener(_load);
    _load();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = info.version);
    });
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

  void _toast(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));

  /// Runs one action at a time, so a second tap can't start another while the first is going.
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm({required String title, required String body, required String action}) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text(title, style: Theme.of(context).textTheme.titleMedium),
          content: Text(body, style: Theme.of(context).textTheme.bodyLarge),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: TB.pinkDark),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(action),
            ),
          ],
        ),
      ) ==
      true;

  Future<void> _copyId() async {
    await Clipboard.setData(ClipboardData(text: Identity.myId));
    if (mounted) _toast('ID copied');
  }

  Future<void> _newId() async {
    final ok = await _confirm(
      title: 'Get a new ID?',
      body:
          'All your chats will be deleted and everyone will be unpaired. People in range are told now; '
          "others won't be. Nobody will see your old ID again. Your block list stays.",
      action: 'New ID',
    );
    if (!ok) return;
    await _run(() async {
      await ChatService.instance.newIdentity();
      if (mounted) _toast('You are now ${anonName(Identity.myId)}');
    });
  }

  Future<void> _setVisible(bool value) => _run(() async {
    await ChatService.instance.setVisible(value);
    if (mounted) setState(() {});
  });

  Future<void> _clearChats() async {
    final ok = await _confirm(
      title: 'Clear all chats?',
      body:
          "Every message will be deleted from this phone. This can't be undone. "
          'You stay paired, and the other person keeps their copy.',
      action: 'Clear all',
    );
    if (!ok) return;
    await _run(() async {
      await _db.clearAllMessages();
      if (mounted) _toast('All chats cleared');
    });
  }

  Future<void> _eraseEverything() async {
    final ok = await _confirm(
      title: 'Erase everything?',
      body:
          'Your ID, all chats, pairings, the block list and settings will be deleted from this phone. '
          "This can't be undone. The app will start again like new.",
      action: 'Erase',
    );
    if (!ok) return;
    await _run(() async {
      final navigator = Navigator.of(context);
      await ChatService.instance.eraseEverything();
      navigator.pushAndRemoveUntil(MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()), (_) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      bottom: false,
      child: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            Text('Settings', style: textTheme.headlineMedium),
            const SizedBox(height: 20),
            _ProfileCard(onCopy: _copyId, onNewId: _newId),
            const _Section('NEARBY'),
            _Card(
              children: [
                SwitchListTile(
                  value: Prefs.visible,
                  onChanged: _setVisible,
                  activeThumbColor: Colors.white,
                  activeTrackColor: TB.indigo,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: TB.switchOff,
                  trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: const Text('Visible to others', style: _titleStyle),
                  subtitle: Text(
                    Prefs.visible
                        ? 'People nearby can find you and send a pair request.'
                        : "You're hidden. You can still find others and chat with people you're paired with.",
                    style: _subtitleStyle,
                  ),
                ),
              ],
            ),
            const _Section('BLOCKED PEOPLE'),
            _Card(
              children: [
                if (_blocked.isEmpty) const ListTile(title: Text('Nobody is blocked.', style: _subtitleStyle)),
                for (final peerId in _blocked)
                  ListTile(
                    leading: AnonAvatar(peerId: peerId, size: 40),
                    title: Text(anonName(peerId), style: _titleStyle),
                    trailing: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: TB.lavender,
                        foregroundColor: TB.indigo,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => ChatService.instance.unblock(peerId),
                      child: const Text('Unblock', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
              ],
            ),
            const _Section('DATA'),
            _Card(
              children: [
                _ActionTile(
                  icon: Icons.chat_bubble_outline,
                  title: 'Clear all chats',
                  subtitle: 'Delete every message, stay paired',
                  onTap: _clearChats,
                ),
                const Divider(height: 1, color: TB.divider),
                _ActionTile(
                  icon: Icons.delete_forever_outlined,
                  title: 'Erase everything',
                  subtitle: 'ID, chats, pairings and settings',
                  danger: true,
                  onTap: _eraseEverything,
                ),
              ],
            ),
            const _Section('ABOUT'),
            _Card(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline, color: TB.indigo),
                  title: const Text('TB Chat', style: _titleStyle),
                  trailing: Text(_version.isEmpty ? '' : 'v$_version', style: _subtitleStyle),
                ),
                const Divider(height: 1, color: TB.divider),
                const ListTile(
                  leading: Icon(Icons.lock_outline, color: TB.indigo),
                  title: Text('No server, no account', style: _titleStyle),
                  subtitle: Text(
                    'Messages go straight from phone to phone over Bluetooth and Wi-Fi. '
                    'Your ID and chats are kept only on this phone.',
                    style: _subtitleStyle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

const _titleStyle = TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: TB.ink);
const _subtitleStyle = TextStyle(fontSize: 13, color: TB.muted, height: 1.4);

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.onCopy, required this.onNewId});

  final VoidCallback onCopy;
  final VoidCallback onNewId;

  @override
  Widget build(BuildContext context) {
    final id = Identity.myId;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: TB.lavenderSoft, borderRadius: BorderRadius.circular(22)),
      child: Column(
        children: [
          Row(
            children: [
              AnonAvatar(peerId: id, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anonName(id),
                      style: const TextStyle(
                        fontFamily: TB.display,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: TB.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text('This is how others see you', style: _subtitleStyle),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onCopy,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    const Text('Your ID', style: _subtitleStyle),
                    const Spacer(),
                    Text(
                      id,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                        color: TB.indigo,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.copy_rounded, size: 18, color: TB.indigo),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: TB.pinkDark,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: onNewId,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Get a new ID', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
    child: Text(
      label,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: TB.muted),
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Material(
    color: TB.lavenderSoft,
    borderRadius: BorderRadius.circular(22),
    clipBehavior: Clip.antiAlias,
    child: Column(children: children),
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? TB.pinkDark : TB.ink;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: danger ? TB.pinkDark : TB.indigo),
      title: Text(title, style: _titleStyle.copyWith(color: color)),
      subtitle: Text(subtitle, style: _subtitleStyle),
      trailing: const Icon(Icons.chevron_right, color: TB.muted),
    );
  }
}
