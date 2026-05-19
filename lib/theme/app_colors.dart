import 'package:flutter/material.dart';

class AppColors {
  // Navigation / Sidebar
  static const Color navBg       = Color(0xFF0F1929);

  // Backgrounds
  static const Color bgLight     = Color(0xFFF0F4F8);
  static const Color surface     = Color(0xFFFFFFFF);

  // Brand
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color primary     = Color(0xFF53D6FF);
  static const Color accent      = Color(0xFF53D6FF);

  // Text
  static const Color textDark    = Color(0xFF1A2236);
  static const Color textMid     = Color(0xFF5A6A85);
  static const Color textLight   = Color(0xFF9DAFC8);

  // Borders
  static const Color stroke      = Color(0xFFE2E8F0);
  static const Color border      = Color(0xFFE2E8F0);

  // Status
  static const Color success     = Color(0xFF22C55E);
  static const Color warning     = Color(0xFFF59E0B);
  static const Color error       = Color(0xFFE53935);

  // Aliases kept for backward compatibility
  static const Color white       = Color(0xFFFFFFFF);
  static const Color darkBg      = Color(0xFF0F1929);
  static const Color lightBg     = Color(0xFFF0F4F8);
}

class AppTheme {
  static const double borderRadius   = 12.0;
  static const double borderRadiusMd = 8.0;
  static const double borderRadiusLg = 16.0;

  static const EdgeInsets paddingXs = EdgeInsets.all(4.0);
  static const EdgeInsets paddingSm = EdgeInsets.all(8.0);
  static const EdgeInsets paddingMd = EdgeInsets.all(16.0);
  static const EdgeInsets paddingLg = EdgeInsets.all(20.0);

  static TextStyle headingLarge = const TextStyle(
    fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textDark,
  );
  static TextStyle headingMedium = const TextStyle(
    fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark,
  );
  static TextStyle headingSmall = const TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark,
  );
  static TextStyle bodyLarge = const TextStyle(
    fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDark,
  );
  static TextStyle bodyMedium = const TextStyle(
    fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textDark,
  );
  static TextStyle bodySmall = const TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textLight,
  );
  static TextStyle caption = const TextStyle(
    fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textLight,
  );
}
