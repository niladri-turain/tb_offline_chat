import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/peer.dart';
import '../../shared/widgets/widgets.dart';

/// Screen 6: both phones show the same 4-digit code before pairing.
/// Returns true when the user accepts.
class PairRequestDialog extends StatefulWidget {
  const PairRequestDialog({
    super.key,
    required this.peer,
    required this.code,
  });

  final Peer peer;

  /// `authenticationDigits` from Nearby Connections.
  final String code;

  static Future<bool?> show(
    BuildContext context, {
    required Peer peer,
    String code = '4829',
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PairRequestDialog(peer: peer, code: code),
    );
  }

  @override
  State<PairRequestDialog> createState() => _PairRequestDialogState();
}

class _PairRequestDialogState extends State<PairRequestDialog> {
  static const _timeout = 42;
  int _secondsLeft = _timeout;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        Navigator.of(context).pop(false);
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _countdown =>
      '${_secondsLeft ~/ 60}:${(_secondsLeft % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnonAvatar(
              peer: widget.peer,
              size: 80,
              fontSize: 24,
              ring: AppColors.pinkSoft,
            ),
            const SizedBox(height: 22),
            Text(
              '${widget.peer.name} wants to pair',
              textAlign: TextAlign.center,
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: 8),
            Text(
              'Check that the same code shows on both phones before you accept.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (i, digit) in widget.code.split('').indexed) ...[
                  if (i > 0) const SizedBox(width: 10),
                  _DigitBox(digit),
                ],
              ],
            ),
            const SizedBox(height: 18),
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(AppIcons.lock, size: 16, color: AppColors.muted),
                SizedBox(width: 8),
                Text(
                  'Encrypted · nothing leaves the two phones',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  flex: 10,
                  child: SoftButton(
                    label: 'Decline',
                    foreground: AppColors.ink,
                    height: 52,
                    radius: 16,
                    fontSize: 16,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 14,
                  child: GradientButton(
                    label: 'Accept',
                    height: 52,
                    radius: 16,
                    fontSize: 16,
                    // TODO: acceptConnection, create conversation in local db.
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Request expires in $_countdown',
              style: AppTextStyles.small,
            ),
          ],
        ),
      ),
    );
  }
}

class _DigitBox extends StatelessWidget {
  const _DigitBox(this.digit);

  final String digit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.lavender,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        digit,
        style: AppTextStyles.h1.copyWith(
          fontSize: 26,
          color: AppColors.indigo,
        ),
      ),
    );
  }
}
