import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppGradients {
  /// Main horizontal button gradient: pink → purple → indigo.
  static const button = LinearGradient(
    colors: [AppColors.pink, AppColors.purple, AppColors.indigo],
    stops: [0, 0.55, 1],
  );

  /// Diagonal brand gradient for cards and icon tiles.
  static const brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.pink, AppColors.purple, AppColors.indigo],
    stops: [0, 0.6, 1],
  );

  /// Two-stop pink → indigo, used on small round things (send, "You", Pair).
  static const pinkIndigo = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.pink, AppColors.indigo],
  );

  static const pinkIndigoHorizontal = LinearGradient(
    colors: [AppColors.pink, AppColors.indigo],
  );

  /// My chat bubble.
  static const myBubble = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.pinkDark, AppColors.violet],
  );

  /// Avatar gradients. A peer always gets the same one from its ID.
  static const avatars = [
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.pink, AppColors.purple],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.indigo, Color(0xFF7A5CFA)],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.success, Color(0xFF2BB3A0)],
    ),
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFD9480F), AppColors.pink],
    ),
  ];

  static LinearGradient forId(String id) =>
      avatars[id.codeUnits.fold(0, (a, b) => a + b) % avatars.length];

  static const buttonShadow = [
    BoxShadow(
      color: Color(0x38E0067F),
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
  ];
}
