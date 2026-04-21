import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design System — "Helpdesk UNAIR" Style
class AppTheme {
  AppTheme._();

  // ─── Brand Colors ──────────────────────────────────────────────
  static const Color primary = Color(0xFF3B82F6); // Blue
  static const Color primaryLight = Color(0xFFDBEAFE);
  static const Color primaryDark = Color(0xFF2563EB);
  static const Color background = Color(0xFFF8FAFC); // Very light gray
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
  
  static const Color inputFill = Color(0xFFF1F5F9); // Light gray for inputs
  static const Color border = Color(0xFFE2E8F0);

  // Dark mode
  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkInputFill = Color(0xFF334155);

  // ─── Status Colors ─────────────────────────────────────────────
  static const Color statusOpen = Color(0xFF8B5CF6);
  static const Color statusOpenBg = Color(0xFFEDE9FE);
  
  static const Color statusInProgress = Color(0xFFD97706); // Orange/Brown text
  static const Color statusInProgressBg = Color(0xFFFEF3C7); // Light orange bg
  
  static const Color statusResolved = Color(0xFF059669); // Green
  static const Color statusResolvedBg = Color(0xFFD1FAE5);
  
  static const Color statusCancelled = Color(0xFFE11D48); // Red
  static const Color statusCancelledBg = Color(0xFFFFE4E6);

  // Priority
  static const Color priorityHigh = Color(0xFFEF4444);
  static const Color priorityHighBg = Color(0xFFFEE2E2);
  static const Color priorityMid = Color(0xFFF59E0B);
  static const Color priorityMidBg = Color(0xFFFED7AA);
  static const Color priorityLow = Color(0xFF10B981);
  static const Color priorityLowBg = Color(0xFFD1FAE5);

  // ─── Shadows ───────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  // ─── Border Radius ─────────────────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 16;
  static const double radiusLg = 24;
  static const double radiusXl = 32;
  static const double radiusPill = 50;

  // ─── Status helpers ────────────────────────────────────────────
  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai': return statusResolved;
      case 'dibatalkan': return statusCancelled;
      case 'diproses': return statusInProgress;
      case 'menunggu antrean': 
      case 'dalam antrean':
      default: return statusInProgress; // Reference uses orange/brown for "Dalam Antrean"
    }
  }

  static Color statusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai': return statusResolvedBg;
      case 'dibatalkan': return statusCancelledBg;
      case 'diproses': return statusInProgressBg;
      case 'menunggu antrean':
      case 'dalam antrean':
      default: return priorityMidBg; // Reference uses a peach color for "Dalam Antrean"
    }
  }

  static IconData statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'selesai': return Icons.check_circle_rounded;
      case 'dibatalkan': return Icons.cancel_rounded;
      case 'diproses': return Icons.autorenew_rounded;
      case 'menunggu antrean':
      case 'dalam antrean':
      default: return Icons.schedule_rounded;
    }
  }

  // ─── Light Theme ───────────────────────────────────────────────
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      surface: background,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: primaryDark,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        color: cardColor,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: statusCancelled, width: 1.5),
        ),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        labelStyle: GoogleFonts.plusJakartaSans(color: textSecondary, fontWeight: FontWeight.w500, fontSize: 14),
        hintStyle: GoogleFonts.plusJakartaSans(color: textMuted, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 20,
      ),
    );
  }

  // ─── Dark Theme (Optional, matching structure) ──────────────────
  static ThemeData get darkTheme {
    return lightTheme; // Keeping light theme structure, can be adjusted later if needed
  }
}
