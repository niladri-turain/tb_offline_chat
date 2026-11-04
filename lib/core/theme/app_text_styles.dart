import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Poppins for headings and buttons, Inter for everything else.
abstract final class AppFonts {
  static const poppins = 'Poppins';
  static const inter = 'Inter';
}

abstract final class AppTextStyles {
  // Headings (Poppins)
  static const display = TextStyle(
    fontFamily: AppFonts.poppins,
    fontWeight: FontWeight.w700,
    fontSize: 34,
    letterSpacing: -0.5,
    color: AppColors.ink,
  );
  static const h1 = TextStyle(
    fontFamily: AppFonts.poppins,
    fontWeight: FontWeight.w700,
    fontSize: 28,
    color: AppColors.ink,
  );
  static const h2 = TextStyle(
    fontFamily: AppFonts.poppins,
    fontWeight: FontWeight.w700,
    fontSize: 24,
    color: AppColors.ink,
  );
  static const h3 = TextStyle(
    fontFamily: AppFonts.poppins,
    fontWeight: FontWeight.w700,
    fontSize: 22,
    color: AppColors.ink,
  );
  static const title = TextStyle(
    fontFamily: AppFonts.poppins,
    fontWeight: FontWeight.w600,
    fontSize: 17,
    color: AppColors.ink,
  );
  static const button = TextStyle(
    fontFamily: AppFonts.poppins,
    fontWeight: FontWeight.w600,
    fontSize: 17,
  );

  // Body (Inter)
  static const bodyLarge = TextStyle(
    fontFamily: AppFonts.inter,
    fontSize: 17,
    color: AppColors.muted,
  );
  static const body = TextStyle(
    fontFamily: AppFonts.inter,
    fontSize: 15,
    height: 1.5,
    color: AppColors.muted,
  );
  static const bodyStrong = TextStyle(
    fontFamily: AppFonts.inter,
    fontWeight: FontWeight.w600,
    fontSize: 15,
    color: AppColors.ink,
  );
  static const label = TextStyle(
    fontFamily: AppFonts.inter,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    color: AppColors.ink,
  );
  static const caption = TextStyle(
    fontFamily: AppFonts.inter,
    fontSize: 13,
    color: AppColors.muted,
  );
  static const small = TextStyle(
    fontFamily: AppFonts.inter,
    fontSize: 12,
    color: AppColors.muted,
  );
  static const overline = TextStyle(
    fontFamily: AppFonts.inter,
    fontWeight: FontWeight.w600,
    fontSize: 12,
    letterSpacing: 0.6,
    color: AppColors.muted,
  );
}
