import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_start.dart';
import '../data/auth.dart';
import '../data/chat_db.dart';
import '../data/identity.dart';
import '../data/prefs.dart';
import '../theme.dart';

/// Shown on every launch. Loads the saved session, ID, settings and chats while the logo
/// animates, then fades into the right first screen (Login, Welcome or Home).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// Shortest time the splash stays, so the animation can finish even when loading is instant.
  static const minDuration = Duration(milliseconds: 2400);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..forward();
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();

  late final Animation<double> _logoScale =
      CurvedAnimation(parent: _intro, curve: const Interval(0, 0.6, curve: Curves.easeOutBack));
  late final Animation<double> _logoFade =
      CurvedAnimation(parent: _intro, curve: const Interval(0, 0.35, curve: Curves.easeOut));
  late final Animation<double> _title =
      CurvedAnimation(parent: _intro, curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic));
  late final Animation<double> _tagline =
      CurvedAnimation(parent: _intro, curve: const Interval(0.5, 0.9, curve: Curves.easeOutCubic));
  late final Animation<double> _footer =
      CurvedAnimation(parent: _intro, curve: const Interval(0.7, 1, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final results = await Future.wait<Object?>([
      _load(),
      Future<void>.delayed(SplashScreen.minDuration),
    ]);
    final next = results.first! as Widget;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, _, _) => next,
      transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
    ));
  }

  Future<Widget> _load() async {
    await Auth.load();
    await Identity.load();
    await Prefs.load();
    await ChatDb.instance.open();
    return appStart();
  }

  @override
  void dispose() {
    _intro.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [TB.pink, TB.purple, TB.indigo],
              stops: [0, 0.55, 1],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 5),
                SizedBox(
                  width: 260,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _Pulse(animation: _pulse, delay: 0),
                      _Pulse(animation: _pulse, delay: 0.5),
                      FadeTransition(
                        opacity: _logoFade,
                        child: ScaleTransition(scale: _logoScale, child: const _Logo()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                _Rise(
                  animation: _title,
                  child: const Text('TB Chat',
                      style: TextStyle(
                          fontFamily: TB.display,
                          fontWeight: FontWeight.w700,
                          fontSize: 40,
                          letterSpacing: -0.6,
                          color: Colors.white)),
                ),
                const SizedBox(height: 8),
                _Rise(
                  animation: _tagline,
                  child: Text('Anonymous chat with people nearby',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.88))),
                ),
                const Spacer(flex: 6),
                FadeTransition(
                  opacity: _footer,
                  child: Column(
                    children: [
                      _Dots(animation: _pulse),
                      const SizedBox(height: 18),
                      // Row(
                      //   mainAxisSize: MainAxisSize.min,
                      //   children: [
                      //     Icon(Icons.bluetooth, size: 16, color: Colors.white.withValues(alpha: 0.85)),
                      //     const SizedBox(width: 6),
                      //     Text('No internet needed · stays on your phone',
                      //         style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.85))),
                      //   ],
                      // ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// White chat card tilted behind a glassy Bluetooth card, like the Welcome hero but on the gradient.
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    Widget line(double width) => Container(
          width: width,
          height: 9,
          decoration: BoxDecoration(color: TB.lavenderDeep, borderRadius: BorderRadius.circular(5)),
        );
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
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 12))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [line(70), const SizedBox(height: 10), line(46)],
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
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1.5),
              ),
              child: const Icon(Icons.bluetooth, size: 34, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// A ring that grows out from the logo and fades, like a radar ping.
class _Pulse extends StatelessWidget {
  const _Pulse({required this.animation, required this.delay});

  final Animation<double> animation;

  /// 0–1, how far behind the first ring this one runs.
  final double delay;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = (animation.value + delay) % 1;
        final size = 140 + 120 * t;
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.35 * (1 - t)), width: 2),
          ),
        );
      },
    );
  }
}

/// Fades in while sliding up a little.
class _Rise extends StatelessWidget {
  const _Rise({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.6), end: Offset.zero).animate(animation),
        child: child,
      ),
    );
  }
}

/// Three dots that bounce one after another while the app loads.
class _Dots extends StatelessWidget {
  const _Dots({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Builder(builder: (context) {
              final t = (animation.value - i * 0.15) % 1;
              final lift = math.sin(math.pi * (t * 2).clamp(0.0, 1.0));
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                transform: Matrix4.translationValues(0, -6 * lift, 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.55 + 0.45 * lift),
                ),
              );
            }),
        ],
      ),
    );
  }
}
