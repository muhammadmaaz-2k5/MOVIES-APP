import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// THEME LOCK: dark — source: domain signal (entertainment/streaming)
// Scaffold.backgroundColor = AppTheme.backgroundDark — ALL screens

class AppTheme {
  // Primary palette
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryContainer = Color(0xFF3D2F9E);
  static const Color secondary = Color(0xFF00CEC9);
  static const Color accent = Color(0xFFFDCB6E);

  // Semantic colors
  static const Color success = Color(0xFF00B894);
  static const Color warning = Color(0xFFFDCB6E);
  static const Color error = Color(0xFFE17055);

  // Dark surfaces
  static const Color backgroundDark = Color(0xFF12121A);
  static const Color surfaceDark = Color(0xFF1E1E2E);
  static const Color surfaceVariantDark = Color(0xFF2A2A3E);
  static const Color cardDark = Color(0xFF252538);

  // Light surfaces (required even for dark-primary app)
  static const Color backgroundLight = Color(0xFFF4F4F8);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF0F0F5);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFEDE9FF),
      onPrimaryContainer: Color(0xFF1A0066),
      secondary: secondary,
      onSecondary: Colors.white,
      surface: surfaceLight,
      onSurface: Color(0xFF1A1A2E),
      error: error,
      onError: Colors.white,
      outline: Color(0xFFCCCCDD),
      outlineVariant: Color(0xFFEEEEF5),
    ),
    scaffoldBackgroundColor: backgroundLight,
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
    appBarTheme: AppBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      color: surfaceLight,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryContainer,
      onPrimaryContainer: Color(0xFFE8E0FF),
      secondary: secondary,
      onSecondary: Color(0xFF003333),
      surface: surfaceDark,
      onSurface: Color(0xFFE6E6F0),
      error: error,
      onError: Colors.white,
      outline: Color(0xFF444466),
      outlineVariant: Color(0xFF2A2A3E),
    ),
    scaffoldBackgroundColor: backgroundDark,
    textTheme: GoogleFonts.outfitTextTheme(
      ThemeData.dark().textTheme,
    ).apply(bodyColor: Color(0xFFE6E6F0), displayColor: Color(0xFFE6E6F0)),
    appBarTheme: AppBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.outfit(
        color: Color(0xFFE6E6F0),
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(color: Color(0xFFE6E6F0)),
    ),
    cardTheme: CardThemeData(
      color: surfaceDark,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surfaceVariantDark,
      selectedColor: primary,
      labelStyle: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(color: Color(0xFF444466)),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: surfaceVariantDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Color(0xFF444466)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primary, width: 1.5),
      ),
      hintStyle: GoogleFonts.outfit(color: Color(0xFF888899), fontSize: 14),
    ),
    dividerTheme: DividerThemeData(color: Color(0xFF2A2A3E), thickness: 1),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
  );

  // Extended color helpers
  static Color ratingColor(double rating) {
    if (rating >= 7.5) return success;
    if (rating >= 6.0) return warning;
    return error;
  }
}
