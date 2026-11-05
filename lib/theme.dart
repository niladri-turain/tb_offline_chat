import 'package:flutter/material.dart';

/// TB Chat colors, taken from the design canvas.
class TB {
  static const ink = Color(0xFF1B1640);
  static const muted = Color(0xFF5E5A78);
  static const navInactive = Color(0xFF4A4566);
  static const lavender = Color(0xFFEFEDFB);
  static const lavenderSoft = Color(0xFFF5F3FE);
  static const lavenderDeep = Color(0xFFDCD6FA);
  static const pink = Color(0xFFE0067F);
  static const pinkDark = Color(0xFFC4056F);
  static const pinkSoft = Color(0xFFFDE7F2);
  static const purple = Color(0xFF8A12B8);
  static const indigo = Color(0xFF3F1FD1);
  static const green = Color(0xFF0E8A5F);
  static const greenDark = Color(0xFF0B6B4A);
  static const greenSoft = Color(0xFFE8F7F0);
  static const divider = Color(0xFFECEAF5);

  static const gradient = LinearGradient(
    colors: [pink, purple, indigo],
    stops: [0, 0.55, 1],
  );

  /// Diagonal version of [gradient], for cards and icon tiles.
  static const brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pink, purple, indigo],
    stops: [0, 0.6, 1],
  );

  static const display = 'Poppins';
  static const body = 'Inter';

  static ThemeData theme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: body,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(seedColor: indigo, primary: indigo),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontFamily: display, fontWeight: FontWeight.w700, fontSize: 28, color: ink),
        titleLarge: TextStyle(fontFamily: display, fontWeight: FontWeight.w700, fontSize: 24, color: ink),
        titleMedium: TextStyle(fontFamily: display, fontWeight: FontWeight.w600, fontSize: 17, color: ink),
        bodyLarge: TextStyle(fontSize: 15, height: 1.5, color: muted),
        bodyMedium: TextStyle(fontSize: 14, color: ink),
        bodySmall: TextStyle(fontSize: 13, color: muted),
      ),
    );
  }
}

/// Full-width gradient call-to-action button used across the app.
class GradientButton extends StatelessWidget {
  const GradientButton({super.key, required this.label, required this.onPressed, this.icon});

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: TB.gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x38E0067F), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, color: Colors.white, size: 22), const SizedBox(width: 10)],
              Text(label,
                  style: const TextStyle(
                      fontFamily: TB.display, fontWeight: FontWeight.w600, fontSize: 17, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lavender row with an icon, a title and one line of explanation.
///
/// [boxed] puts the icon in a white rounded square (Welcome); otherwise it sits bare (Bluetooth sheet).
class FeatureTile extends StatelessWidget {
  const FeatureTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.boxed = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool boxed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: boxed
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
          : const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: TB.lavenderSoft, borderRadius: BorderRadius.circular(boxed ? 16 : 14)),
      child: Row(
        crossAxisAlignment: boxed ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          if (boxed)
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 22),
            )
          else
            Padding(padding: const EdgeInsets.only(top: 1), child: Icon(icon, color: iconColor, size: 22)),
          SizedBox(width: boxed ? 14 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: boxed ? 15 : 14, color: TB.ink)),
                Text(subtitle, style: const TextStyle(fontSize: 13, color: TB.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Round avatar for an anonymous peer: a gradient picked from the ID plus its first two characters.
class AnonAvatar extends StatelessWidget {
  const AnonAvatar({super.key, required this.peerId, this.size = 48});

  final String peerId;
  final double size;

  static const _palettes = [
    [Color(0xFFE0067F), Color(0xFF8A12B8)],
    [Color(0xFF3F1FD1), Color(0xFF7A5CFA)],
    [Color(0xFF0E8A5F), Color(0xFF2BB3A0)],
    [Color(0xFFD9480F), Color(0xFFE0067F)],
  ];

  @override
  Widget build(BuildContext context) {
    final colors = _palettes[peerId.codeUnits.fold<int>(0, (a, b) => a + b) % _palettes.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Text(
        peerId.substring(0, 2),
        style: TextStyle(
            fontFamily: TB.display, fontWeight: FontWeight.w600, fontSize: size * 0.3, color: Colors.white),
      ),
    );
  }
}

String anonName(String peerId) => 'Anon ${peerId.substring(0, 4)}';
