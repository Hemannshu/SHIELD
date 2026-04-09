import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modern design system for SHIELD app
/// Inspired by noonlight, bSafe, Life360, and premium fintech apps
class AppTheme {
  // ─── Brand Colors ────────────────────────────────────────────
  static const Color primaryPink = Color(0xFFE91E63);
  static const Color primaryPinkLight = Color(0xFFF06292);
  static const Color primaryPinkDark = Color(0xFFC2185B);
  static const Color accentCoral = Color(0xFFFF6B6B);
  static const Color accentPeach = Color(0xFFFFAB91);
  static const Color accentViolet = Color(0xFF7C4DFF);
  static const Color accentTeal = Color(0xFF26C6DA);

  // ─── Neutral Colors ──────────────────────────────────────────
  static const Color neutralWhite = Color(0xFFFFFBFE);
  static const Color neutralGrey50 = Color(0xFFFAFAFA);
  static const Color neutralGrey100 = Color(0xFFF5F5F5);
  static const Color neutralGrey200 = Color(0xFFEEEEEE);
  static const Color neutralGrey300 = Color(0xFFE0E0E0);
  static const Color neutralGrey400 = Color(0xFFBDBDBD);
  static const Color neutralGrey500 = Color(0xFF9E9E9E);
  static const Color neutralGrey600 = Color(0xFF757575);
  static const Color neutralGrey700 = Color(0xFF616161);
  static const Color neutralGrey800 = Color(0xFF424242);
  static const Color neutralGrey900 = Color(0xFF212121);

  // ─── Dark Mode Colors ────────────────────────────────────────
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkCard = Color(0xFF16213E);
  static const Color darkElevated = Color(0xFF0F3460);
  static const Color darkBackground = Color(0xFF0D1117);

  // ─── Gradients ───────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFE91E63), Color(0xFFFF6B6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF7C4DFF), Color(0xFFE91E63)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient meshGradient = LinearGradient(
    colors: [
      Color(0xFFFCE4EC),
      Color(0xFFF3E5F5),
      Color(0xFFE8EAF6),
      Color(0xFFFFF3E0),
    ],
    stops: [0.0, 0.33, 0.66, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sosGradient = LinearGradient(
    colors: [Color(0xFFFF1744), Color(0xFFF50057)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Spacing ─────────────────────────────────────────────────
  static const double spacingXS = 4;
  static const double spacingSM = 8;
  static const double spacingMD = 16;
  static const double spacingLG = 24;
  static const double spacingXL = 32;
  static const double spacingXXL = 48;

  // ─── Radius ──────────────────────────────────────────────────
  static const double radiusSM = 8;
  static const double radiusMD = 12;
  static const double radiusLG = 16;
  static const double radiusXL = 24;
  static const double radiusFull = 100;

  // ─── Light Theme ─────────────────────────────────────────────
  static ThemeData lightTheme(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.5,
          color: neutralGrey900,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: neutralGrey900,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: neutralGrey900,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: neutralGrey900,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: neutralGrey900,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: neutralGrey800,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: neutralGrey800,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: neutralGrey600,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: neutralWhite,
        ),
      ),
      colorScheme: const ColorScheme.light(
        primary: primaryPink,
        onPrimary: neutralWhite,
        secondary: accentViolet,
        onSecondary: neutralWhite,
        tertiary: accentCoral,
        surface: neutralWhite,
        onSurface: neutralGrey900,
        surfaceContainerHighest: neutralGrey100,
        error: Color(0xFFB00020),
        outline: neutralGrey200,
      ),
      scaffoldBackgroundColor: neutralGrey50,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
        ),
        color: neutralWhite,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: neutralGrey900,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: neutralGrey100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: primaryPink, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: Color(0xFFB00020)),
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: neutralGrey400,
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          color: neutralGrey600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
        backgroundColor: primaryPink,
        foregroundColor: neutralWhite,
      ),
      dividerTheme: const DividerThemeData(
        color: neutralGrey200,
        thickness: 1,
      ),
    );
  }

  // ─── Dark Theme ──────────────────────────────────────────────
  static ThemeData darkTheme(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.5,
          color: neutralWhite,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: neutralWhite,
        ),
        headlineLarge: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: neutralWhite,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: neutralWhite,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: neutralWhite,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFFB0B0B0),
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Color(0xFFB0B0B0),
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFF8A8A8A),
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: neutralWhite,
        ),
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryPinkLight,
        onPrimary: neutralWhite,
        secondary: accentViolet,
        onSecondary: neutralWhite,
        tertiary: accentCoral,
        surface: darkSurface,
        onSurface: neutralWhite,
        surfaceContainerHighest: darkCard,
        error: Color(0xFFCF6679),
        outline: Color(0xFF2A2A40),
      ),
      scaffoldBackgroundColor: darkBackground,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
        ),
        color: darkCard,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: neutralWhite,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: Color(0xFF2A2A40), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: primaryPinkLight, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: Color(0xFF5A5A7A)),
        labelStyle: GoogleFonts.inter(fontSize: 14, color: Color(0xFF8A8A8A)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
        backgroundColor: primaryPinkLight,
        foregroundColor: neutralWhite,
      ),
    );
  }

  // ─── Glass Card Decoration ───────────────────────────────────
  static BoxDecoration glassCard({bool isDark = false}) {
    return BoxDecoration(
      color: isDark
          ? Colors.white.withOpacity(0.05)
          : Colors.white.withOpacity(0.7),
      borderRadius: BorderRadius.circular(radiusXL),
      border: Border.all(
        color: isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.white.withOpacity(0.3),
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.05),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  // ─── Elevated Card Decoration ────────────────────────────────
  static BoxDecoration elevatedCard({bool isDark = false}) {
    return BoxDecoration(
      color: isDark ? darkCard : neutralWhite,
      borderRadius: BorderRadius.circular(radiusLG),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.06),
          blurRadius: 16,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // ─── Gradient Button Decoration ──────────────────────────────
  static BoxDecoration gradientButton({double radius = radiusMD}) {
    return BoxDecoration(
      gradient: primaryGradient,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: primaryPink.withOpacity(0.3),
          blurRadius: 12,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
