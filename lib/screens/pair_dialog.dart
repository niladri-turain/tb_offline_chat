import 'dart:async';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Pair request popup. Incoming: Accept/Decline, popped with true/false, auto-declines after
/// [timeout]. Outgoing (waiting for the other person): Cancel, popped with false.
/// Popped with null when the request ended on its own.
class PairDialog extends StatefulWidget {
  const PairDialog({super.key, required this.peerId, required this.code, required this.incoming});

  final String peerId;
  final String code;
  final bool incoming;

  static const timeout = Duration(seconds: 30);

  @override
  State<PairDialog> createState() => _PairDialogState();
}

class _PairDialogState extends State<PairDialog> {
  late int _left = PairDialog.timeout.inSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.incoming) {
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_left <= 1) {
          t.cancel();
          Navigator.of(context).pop(false);
        } else {
          setState(() => _left--);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final name = anonName(widget.peerId);
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(shape: BoxShape.circle, color: TB.pinkSoft),
              child: AnonAvatar(peerId: widget.peerId, size: 80),
            ),
            const SizedBox(height: 18),
            Text(widget.incoming ? '$name wants to pair' : 'Waiting for $name',
                textAlign: TextAlign.center, style: text.titleLarge?.copyWith(fontSize: 22)),
            const SizedBox(height: 8),
            Text(
              widget.incoming
                  ? 'Check that the same code shows on both phones before you accept.'
                  : 'Ask them to accept. The same code should show on their phone.',
              textAlign: TextAlign.center,
              style: text.bodyLarge?.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in widget.code.split(''))
                  Container(
                    width: 44,
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: TB.lavender, borderRadius: BorderRadius.circular(14)),
                    child: Text(c,
                        style: const TextStyle(
                            fontFamily: TB.display, fontWeight: FontWeight.w700, fontSize: 26, color: TB.indigo)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 16, color: TB.muted),
                SizedBox(width: 6),
                Flexible(
                  child: Text('Encrypted · nothing leaves the two phones',
                      style: TextStyle(fontSize: 13, color: TB.muted)),
                ),
              ],
            ),
            const SizedBox(height: 22),
            if (widget.incoming)
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: _SoftButton(label: 'Decline', onPressed: () => Navigator.of(context).pop(false)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 7,
                    child: GradientButton(label: 'Accept', onPressed: () => Navigator.of(context).pop(true)),
                  ),
                ],
              )
            else ...[
              const LinearProgressIndicator(color: TB.pink, backgroundColor: TB.lavender),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: _SoftButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop(false)),
              ),
            ],
            if (widget.incoming) ...[
              const SizedBox(height: 12),
              Text('Request expires in 0:${_left.toString().padLeft(2, '0')}', style: text.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _SoftButton extends StatelessWidget {
  const _SoftButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: TB.lavender,
          foregroundColor: TB.ink,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(fontFamily: TB.display, fontWeight: FontWeight.w600, fontSize: 16)),
      ),
    );
  }
}
