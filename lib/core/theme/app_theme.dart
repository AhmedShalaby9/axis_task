import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTheme {
  // ── Palette ────────────────────────────────────────────────────────────────

  static const Color background = Color(0xFF0D0F14);
  static const Color cardSurface = Color(0xFF1A1D24);
  static const Color green = Color(0xFF22C55E); // EGP strengthening
  static const Color red = Color(0xFFEF4444);   // EGP weakening
  static const Color amber = Color(0xFFF59E0B); // offline / cached
  static const Color textPrimary = Color(0xFFE2E8F0);
  static const Color textSecondary = Color(0xFF64748B);

  // ── Theme ──────────────────────────────────────────────────────────────────

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final baseText = GoogleFonts.interTextTheme(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        surface: cardSurface,
        primary: green,
        onSurface: textPrimary,
      ),
      textTheme: baseText,
      cardTheme: CardThemeData(
        color: cardSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      dividerColor: Colors.white12,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardSurface,
        contentTextStyle: GoogleFonts.inter(color: textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: green,
          foregroundColor: Colors.black,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ── Typography helpers ─────────────────────────────────────────────────────

  /// Inter with tabular (monospaced) digit alignment.
  /// Use for any text that displays numbers that update on refresh,
  /// so individual digits don't cause horizontal layout jitter.
  static TextStyle numeric({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w500,
    Color color = textPrimary,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
