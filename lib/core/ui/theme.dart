import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MeireTheme {
  // Dark blue representing technical authority and trust
  // Otimização de Performance: Cores cacheadas e temas imutáveis
  static const Color primaryColor = Color(0xFF004330); // Verde da Logo (Premium)
  static const Color accentColor = Color(0xFFCC8B00);  // Ouro Meiri
  static const Color secondaryColor = Color(0xFF1A5A38); // Verde Suave
  static const Color backgroundColor = Color(0xFFF8FAF9);
  static const Color iceGray = Color(0xFFECF2F0);
  static const Color textBodyColor = Color(0xFF1E293B);

  static ThemeData getTheme(Brightness brightness, bool isCompact) {
    final isDark = brightness == Brightness.dark;
    final baseTheme = isDark ? ThemeData.dark() : ThemeData.light();

    // Scaling factor for compactness
    // Desktop first: everything is slightly smaller (0.9x) by default
    const double baseScale = 0.9;
    final double scale = isCompact ? (baseScale * 0.8) : baseScale;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF00221A) : backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        brightness: brightness,
        seedColor: isDark ? accentColor : primaryColor,
        primary: isDark ? const Color(0xFFE2E8F0) : primaryColor,
        secondary: accentColor,
      ),
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : primaryColor,
          fontSize: 24 * scale,
        ),
        titleLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : primaryColor,
          fontSize: 18 * scale,
        ),
        bodyLarge: GoogleFonts.inter(
          color: isDark ? const Color(0xFFCBD5E1) : textBodyColor,
          fontSize: 14 * scale,
        ),
        bodyMedium: GoogleFonts.inter(
          color: isDark ? const Color(0xFFCBD5E1) : textBodyColor,
          fontSize: 12 * scale,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF003326) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: isDark ? accentColor : primaryColor, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12 * scale,
          vertical: 12 * scale,
        ),
        labelStyle: TextStyle(
            color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
            fontSize: 12 * scale),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? accentColor : primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.symmetric(vertical: 16 * scale),
          textStyle: TextStyle(
            fontSize: 16 * scale,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : primaryColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        selectedItemColor: isDark ? accentColor : primaryColor,
        unselectedItemColor: isDark ? const Color(0xFF64748B) : Colors.grey,
        selectedLabelStyle: TextStyle(fontSize: 10 * scale),
        unselectedLabelStyle: TextStyle(fontSize: 10 * scale),
      ),
    );
  }

  static ThemeData lightTheme(bool isCompact) =>
      getTheme(Brightness.light, isCompact);
  static ThemeData darkTheme(bool isCompact) =>
      getTheme(Brightness.dark, isCompact);
}
