import 'dart:async';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Given to MaterialApp so a toast can be shown from anywhere, even right after a screen change.
final navigatorKey = GlobalKey<NavigatorState>();

/// A toast that slides down from the top with a little bounce, waits, then slides away.
/// Only one shows at a time; a new one replaces the old.
class AppToast {
  AppToast._();

  static OverlayEntry? _current;

  static void success(String message) => _show(message, error: false);
  static void error(String message) => _show(message, error: true);

  static void _show(String message, {required bool error}) {
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;
    _current?.remove();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastView(
        message: message,
        error: error,
        onDone: () {
          if (_current == entry) _current = null;
          if (entry.mounted) entry.remove();
        },
      ),
    );
    _current = entry;
    overlay.insert(entry);
  }
}

class _ToastView extends StatefulWidget {
  const _ToastView({required this.message, required this.error, required this.onDone});

  final String message;
  final bool error;
  final VoidCallback onDone;

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
    reverseDuration: const Duration(milliseconds: 250),
  );
  late final Animation<Offset> _slide = Tween(begin: const Offset(0, -1.4), end: Offset.zero)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn));
  late final Animation<double> _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _timer = Timer(const Duration(milliseconds: 2800), _dismiss);
  }

  Future<void> _dismiss() async {
    _timer?.cancel();
    if (!mounted) return;
    await _controller.reverse();
    widget.onDone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.error ? TB.pinkDark : TB.green;
    return Positioned(
      top: 0,
      left: 16,
      right: 16,
      child: SafeArea(
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _fade,
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: _dismiss,
                onVerticalDragEnd: (_) => _dismiss(),
                child: Semantics(
                  liveRegion: true,
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: color.withValues(alpha: 0.25)),
                      boxShadow: const [BoxShadow(color: Color(0x261B1640), blurRadius: 24, offset: Offset(0, 10))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: widget.error ? TB.pinkSoft : TB.greenSoft,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(widget.error ? Icons.error_outline_rounded : Icons.check_rounded,
                              size: 20, color: color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(widget.message,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500, height: 1.35, color: TB.ink)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
