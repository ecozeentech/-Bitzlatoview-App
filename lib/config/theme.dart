import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Dark gold fintech theme aligned with the Bitzlatoview web platform.
class AppTheme {
  AppTheme._();

  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF141414);
  static const Color surfaceElevated = Color(0xFF1C1C1C);
  static const Color gold = Color(0xFFC9A227);
  static const Color goldLight = Color(0xFFE0C35A);
  static const Color goldMuted = Color(0xFF8A7020);
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textMuted = Color(0xFF6E6E6E);
  static const Color error = Color(0xFFE85D5D);
  static const Color success = Color(0xFF3D9B6E);
  static const Color border = Color(0xFF2A2A2A);

  static ThemeData get dark {
    final baseText = GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: gold,
        onPrimary: background,
        secondary: goldLight,
        onSecondary: background,
        surface: surface,
        onSurface: textPrimary,
        error: error,
        onError: textPrimary,
      ),
      textTheme: baseText.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: background,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: gold,
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: gold,
        textColor: textPrimary,
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: gold,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceElevated,
        contentTextStyle: GoogleFonts.outfit(color: textPrimary),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
