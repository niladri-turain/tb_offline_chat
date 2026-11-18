import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme.dart';
import 'otp_screen.dart';

/// Mobile number entry. "Send OTP" opens [OtpScreen].
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const countryCode = '+91';
  static const numberLength = 10;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _number = TextEditingController();

  bool get _valid => _number.text.length == LoginScreen.numberLength;

  @override
  void initState() {
    super.initState();
    _number.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_valid) return;
    FocusScope.of(context).unfocus();
    final mobile = _number.text;
    final sent = await context.read<AuthProvider>().sendOtp(mobile);
    if (sent == null || !mounted) return;
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => OtpScreen(
        phone: '${LoginScreen.countryCode} $mobile',
        mobile: mobile,
        resendAfter: Duration(seconds: sent.resendAfter),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final sending = context.watch<AuthProvider>().sendingOtp;
    final canSend = _valid && !sending;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 48, 28, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 72),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    const Center(child: _PhoneHero()),
                    const SizedBox(height: 40),
                    const Text('Log in to TB Chat',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: TB.display,
                            fontWeight: FontWeight.w700,
                            fontSize: 28,
                            letterSpacing: -0.3,
                            color: TB.ink)),
                    const SizedBox(height: 8),
                    const Text('Enter your mobile number. We\'ll send you a 4-digit code to verify it.',
                        textAlign: TextAlign.center, style: TextStyle(fontSize: 15, height: 1.5, color: TB.muted)),
                    const SizedBox(height: 36),
                    const Text('Mobile number',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: TB.navInactive)),
                    const SizedBox(height: 8),
                    _NumberField(controller: _number, onSubmitted: _sendOtp),
                    const SizedBox(height: 14),
                    const Row(
                      children: [
                        Icon(Icons.lock_outline, size: 16, color: TB.muted),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text('Your number stays on this phone. Nearby people only see your anonymous ID.',
                              style: TextStyle(fontSize: 12, height: 1.4, color: TB.muted)),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const SizedBox(height: 24),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: canSend ? 1 : 0.45,
                      child: GradientButton(
                        label: sending ? 'Sending…' : 'Send OTP',
                        onPressed: canSend ? _sendOtp : null,
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

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.onSubmitted});

  final TextEditingController controller;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: TB.lavenderInput,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: TB.borderLavender),
      ),
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.all(6),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)),
            child: const Text(LoginScreen.countryCode,
                style: TextStyle(fontFamily: TB.display, fontWeight: FontWeight.w600, fontSize: 16, color: TB.ink)),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmitted(),
              // 10 digits without +91, as the API expects.
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(LoginScreen.numberLength),
              ],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: TB.ink),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '98765 43210',
                hintStyle: TextStyle(color: Color(0xFFA9A5C0), fontWeight: FontWeight.w500, letterSpacing: 1.2),
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Gradient card with a phone icon, matching the Welcome hero.
class _PhoneHero extends StatelessWidget {
  const _PhoneHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        gradient: TB.brandGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [BoxShadow(color: Color(0x38E0067F), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: const Icon(Icons.smartphone_rounded, size: 46, color: Colors.white),
    );
  }
}
