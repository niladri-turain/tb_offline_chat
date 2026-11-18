import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app_start.dart';
import '../data/auth.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';

/// 4-digit code entry. The code is checked by the verify-otp API; when it is right the session
/// is saved and the app continues to its normal start screen.
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.phone, required this.mobile, required this.resendAfter});

  /// Shown on screen, e.g. +91 7059238072.
  final String phone;

  /// Sent to the API, 10 digits without the country code.
  final String mobile;

  /// From the send-otp response.
  final Duration resendAfter;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _code = TextEditingController();
  final _focus = FocusNode();
  Timer? _timer;
  late int _secondsLeft;

  bool get _complete => _code.text.length == Auth.otpLength;

  @override
  void initState() {
    super.initState();
    _code.addListener(_onChanged);
    _focus.addListener(() => setState(() {}));
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() {
    setState(() {});
    if (_complete) _verify();
  }

  void _startResendTimer([Duration? after]) {
    _timer?.cancel();
    _secondsLeft = (after ?? widget.resendAfter).inSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) t.cancel();
    });
  }

  Future<void> _resend() async {
    final sent = await context.read<AuthProvider>().sendOtp(widget.mobile);
    if (sent == null || !mounted) return;
    _code.clear();
    _focus.requestFocus();
    _startResendTimer(Duration(seconds: sent.resendAfter));
  }

  Future<void> _verify() async {
    final auth = context.read<AuthProvider>();
    if (!_complete || auth.verifying) return;
    FocusScope.of(context).unfocus();
    final session = await auth.verifyOtp(widget.mobile, _code.text);
    if (!mounted) return;
    if (session == null) {
      // Wrong code: the error toast is already showing; let them type again.
      _code.clear();
      _focus.requestFocus();
      return;
    }
    final start = await appStart();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute<void>(builder: (_) => start), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final verifying = auth.verifying;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: IconButton(
            tooltip: 'Back',
            style: IconButton.styleFrom(
              backgroundColor: TB.lavender,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: TB.ink),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: _ShieldHero()),
                    const SizedBox(height: 32),
                    const Text('Verify your number',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: TB.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 28,
                            letterSpacing: -0.3,
                            color: TB.ink)),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        text: 'Enter the 4-digit code sent to\n',
                        children: [
                          TextSpan(
                              text: widget.phone,
                              style: const TextStyle(fontWeight: FontWeight.w600, color: TB.ink)),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15, height: 1.5, color: TB.muted),
                    ),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Change number',
                            style: TextStyle(color: TB.indigo, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _CodeBoxes(controller: _code, focus: _focus),
                    const SizedBox(height: 24),
                    Center(
                      child: _secondsLeft > 0
                          ? Text('Resend code in ${_secondsLeft ~/ 60}:${(_secondsLeft % 60).toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 14, color: TB.muted))
                          : TextButton(
                              onPressed: auth.sendingOtp ? null : _resend,
                              child: const Text('Resend code',
                                  style: TextStyle(color: TB.indigo, fontWeight: FontWeight.w600, fontSize: 14)),
                            ),
                    ),
                    const Spacer(),
                    const SizedBox(height: 24),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: _complete && !verifying ? 1 : 0.45,
                      child: GradientButton(
                        label: verifying ? 'Verifying…' : 'Verify & continue',
                        onPressed: _complete && !verifying ? _verify : null,
                      ),
                    ),
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

/// One box per digit of the code. One invisible text field underneath takes the input,
/// so paste, backspace and SMS autofill behave like a normal field.
class _CodeBoxes extends StatelessWidget {
  const _CodeBoxes({required this.controller, required this.focus});

  final TextEditingController controller;
  final FocusNode focus;

  @override
  Widget build(BuildContext context) {
    final text = controller.text;
    return Stack(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < Auth.otpLength; i++) ...[
              if (i > 0) const SizedBox(width: 14),
              // Shrinks to fit narrow phones, up to 64 px wide.
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 64),
                  child: _Box(
                    digit: i < text.length ? text[i] : null,
                    active: focus.hasFocus &&
                        (i == text.length || (i == Auth.otpLength - 1 && text.length == Auth.otpLength)),
                  ),
                ),
              ),
            ],
          ],
        ),
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: controller,
              focusNode: focus,
              autofocus: true,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              showCursor: false,
              enableInteractiveSelection: false,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(Auth.otpLength),
              ],
              decoration: const InputDecoration(border: InputBorder.none, counterText: ''),
            ),
          ),
        ),
      ],
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.digit, required this.active});

  final String? digit;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final filled = digit != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? TB.lavender : TB.lavenderInput,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: active ? TB.pink : (filled ? TB.lavenderDeep : TB.borderLavender), width: active ? 2 : 1),
      ),
      child: Text(digit ?? '',
          style: const TextStyle(fontFamily: TB.display, fontWeight: FontWeight.w700, fontSize: 28, color: TB.indigo)),
    );
  }
}

/// Gradient card with a shield icon, matching the login hero.
class _ShieldHero extends StatelessWidget {
  const _ShieldHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        gradient: TB.brandGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(color: Color(0x38E0067F), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: const Icon(Icons.verified_user_outlined, size: 42, color: Colors.white),
    );
  }
}
