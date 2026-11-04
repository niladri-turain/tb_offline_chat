import 'package:flutter/material.dart';

/// All colors used in TB Chat, taken from the design file.
abstract final class AppColors {
  // Brand
  static const pink = Color(0xFFE0067F);
  static const pinkDark = Color(0xFFC4056F);
  static const purple = Color(0xFF8A12B8);
  static const indigo = Color(0xFF3F1FD1);
  static const violet = Color(0xFF5A1AC8);

  // Text
  static const ink = Color(0xFF1B1640);
  static const inkSoft = Color(0xFF4A4566);
  static const muted = Color(0xFF5E5A78);

  // Surfaces
  static const white = Color(0xFFFFFFFF);
  static const background = Color(0xFFFFFFFF);
  static const backgroundSoft = Color(0xFFF7F6FC);
  static const lavender = Color(0xFFEFEDFB);
  static const lavenderSoft = Color(0xFFF5F3FE);
  static const lavenderInput = Color(0xFFF3F1FB);
  static const lavenderStrong = Color(0xFFDCD6FA);
  static const lavenderAvatar = Color(0xFFE6E2FA);
  static const pinkSoft = Color(0xFFFDE7F2);

  // Lines
  static const border = Color(0xFFECEAF5);
  static const borderLavender = Color(0xFFE6E2FA);
  static const divider = Color(0xFFF0EEF8);
  static const switchOff = Color(0xFFD9D5EA);

  // Status
  static const success = Color(0xFF0E8A5F);
  static const successDark = Color(0xFF0B6B4A);
  static const successSoft = Color(0xFFE8F7F0);

  // Radar rings
  static const radarOuter = Color(0xFFECE8FD);
  static const radarOuterFill = Color(0xFFFBFAFF);
  static const radarMiddle = Color(0xFFE1DBFC);
  static const radarInner = Color(0xFFD2C9FA);
  static const radarInnerFill = Color(0xFFF3F0FE);

  /// Dimmed backdrop behind sheets and dialogs.
  static const scrim = Color(0x8C1B1640);
}
