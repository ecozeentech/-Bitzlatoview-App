import 'package:flutter/material.dart';

class AppTheme {
  // Matches app.bitzlatoview.com manifest + CSS brand tokens
  static const Color brandGold = Color(0xFFF5B301);
  static const Color brandGoldLight = Color(0xFFFFE08A);
  static const Color primaryGold = brandGold;
  static const Color darkBackground = Color(0xFF0B0F1A);
  static const Color darkSurface = Color(0xFF0E1422);
  static const Color darkCard = Color(0xFF151C2E);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textOnBrand = Color(0xFF070A12);
  static const Color errorColor = Color(0xFFE53935);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandGold, brandGoldLight],
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: brandGold,
        secondary: brandGoldLight,
        surface: darkSurface,
        error: errorColor,
        onPrimary: textOnBrand,
        onSecondary: textOnBrand,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandGold,
          foregroundColor: textOnBrand,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textSecondary),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: brandGold),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkCard,
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
