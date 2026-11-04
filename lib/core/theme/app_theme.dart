import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    fontFamily: AppFonts.inter,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.purple,
      primary: AppColors.purple,
      secondary: AppColors.pink,
      surface: AppColors.white,
      onSurface: AppColors.ink,
      error: AppColors.pinkDark,
    ),
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    textTheme: const TextTheme(
      displayLarge: AppTextStyles.display,
      headlineLarge: AppTextStyles.h1,
      headlineMedium: AppTextStyles.h2,
      headlineSmall: AppTextStyles.h3,
      titleMedium: AppTextStyles.title,
      bodyLarge: AppTextStyles.bodyLarge,
      bodyMedium: AppTextStyles.body,
      bodySmall: AppTextStyles.caption,
      labelLarge: AppTextStyles.label,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      modalBarrierColor: AppColors.scrim,
      elevation: 0,
    ),
    dialogTheme: const DialogThemeData(barrierColor: AppColors.scrim),
  );
}
