import 'package:flutter/material.dart';

/// Dark, gold-accented theme mirroring the branding of the
/// app.bitzlatoview.com web platform so the native chrome (splash screen,
/// settings, offline/error states) blends seamlessly with the WebView
/// content.
class AppTheme {
  AppTheme._();

  static const Color background = Color(0xFF0B0D12);
  static const Color surface = Color(0xFF15181F);
  static const Color surfaceVariant = Color(0xFF1E222B);
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFE9CD73);
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFA0A5B1);
  static const Color error = Color(0xFFE5484D);
  static const Color success = Color(0xFF3DD68C);

  static ThemeData get darkTheme {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: gold,
      brightness: Brightness.dark,
      primary: gold,
      onPrimary: Colors.black,
      surface: surface,
      error: error,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: colorScheme,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textSecondary),
      ),
      iconTheme: const IconThemeData(color: gold),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: gold),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: gold,
          side: const BorderSide(color: gold),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceVariant,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: gold,
        textColor: textPrimary,
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF272B35)),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? gold : textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? gold.withValues(alpha: 0.4)
              : surfaceVariant,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: surfaceVariant,
        contentTextStyle: TextStyle(color: textPrimary),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
