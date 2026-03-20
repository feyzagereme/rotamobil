import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color primary = Color(0xFF52B7D9);
  static const Color accent = Color(0xFF00BCD4);
  static const Color darkBg = Color(0xFF1A1E2E);
  static const Color lightBg = Color(0xFFF5F5F5);
  static const Color border = Color(0xFFE0E0E0);
  static const Color textDark = Color(0xFF333333);
  static const Color textLight = Color(0xFF666666);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color white = Color(0xFFFFFFFF);
}

class AppTheme {
  static const double borderRadius = 12.0;
  static const double borderRadiusMd = 8.0;
  static const double borderRadiusLg = 16.0;

  static const EdgeInsets paddingXs = EdgeInsets.all(4.0);
  static const EdgeInsets paddingSm = EdgeInsets.all(8.0);
  static const EdgeInsets paddingMd = EdgeInsets.all(16.0);
  static const EdgeInsets paddingLg = EdgeInsets.all(20.0);

  static TextStyle headingLarge = const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static TextStyle headingMedium = const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static TextStyle headingSmall = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static TextStyle bodyLarge = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textDark,
  );

  static TextStyle bodyMedium = const TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textDark,
  );

  static TextStyle bodySmall = const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textLight,
  );

  static TextStyle caption = const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textLight,
  );
}
