import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Ana Renk Paleti (sağlık teması)
  static const Color tealBlue = Color(0xFF0EA5E9); // Medical Blue
  static const Color deepCyan = Color(0xFF0369A1); // Daha koyu mavi vurgular
  static const Color mintBlue = Color(0xFF10B981); // Medical Green
  static const Color turquoiseSoft = Color(0xFFD1FAE5); // Pastel yeşil
  static const Color lightTurquoise = Color(0xFFE0F2FE); // Pastel mavi
  static const Color mediumTurquoise = Color(0xFFBAE6FD);
  static const Color white = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF0F172A);
  static const Color grayText = Color(0xFF475569);
  static const Color lightText = Color(0xFF94A3B8);
  static const Color accentYellow = Color(0xFFFCD34D);
  static const Color warningOrange = Color(0xFFF97316);

  // Ek Arayüz Renkleri
  static const Color backgroundLight = Color(0xFFF6FBFF);
  static const Color backgroundSecondary = Color(0xFFFFFFFF);
  static const Color inputFieldGray = Color(0xFFF1F5F9);
  static const Color iconGray = Color(0xFF94A3B8);
  static const Color dividerLight = Color(0xFFE2E8F0);
  static const Color successGreen = Color(0xFF10B981);

  // Gradient renkleri
  static const Color lightAquaGradientStart = Color(0xFF0EA5E9);
  static const Color aquaGradientEnd = Color(0xFF10B981);
  static const Color lavenderGradient = Color(0xFFE0EAFF);

  // Legacy aliases to keep older widgets compiling during transition
  static const Color inputBackground = inputFieldGray;
  static const Color iconSecondary = iconGray;
  static const Color backgroundPrimary = backgroundLight;
  static const Color accentTeal = tealBlue;
  static const Color primaryBlue = tealBlue;

  // Gradient yardımcıları
  static LinearGradient get backgroundGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lightAquaGradientStart, aquaGradientEnd],
      );

  static LinearGradient get cardGradient => const LinearGradient(
        colors: [Color(0xFFF0F9FF), Color(0xFFE0F7F4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get accentGradient => const LinearGradient(
        colors: [tealBlue, mintBlue],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  // Text Styles
  static TextStyle get headingLarge => GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: darkText,
  );

  static TextStyle get headingMedium => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: darkText,
  );

  static TextStyle get headingSmall => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: darkText,
  );

  static TextStyle get bodyLarge => GoogleFonts.poppins(
    fontSize: 14,
    color: darkText,
  );

  static TextStyle get bodyMedium => GoogleFonts.poppins(
    fontSize: 13,
    color: darkText,
  );

  static TextStyle get bodySmall => GoogleFonts.poppins(
    fontSize: 11,
    color: grayText,
  );

  // Theme Data
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    textTheme: GoogleFonts.poppinsTextTheme(),
    colorScheme: ColorScheme.light(
          primary: tealBlue,
          secondary: mintBlue,
          surface: white,
          background: backgroundLight,
          error: Colors.red,
          onPrimary: white,
          onSecondary: white,
          onSurface: darkText,
          onBackground: darkText,
        ),
    scaffoldBackgroundColor: backgroundLight,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: darkText,
      iconTheme: const IconThemeData(color: darkText),
      titleTextStyle: GoogleFonts.poppins(
        color: darkText,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: white,
      elevation: 0,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: dividerLight),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: inputFieldGray,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: tealBlue, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: tealBlue,
        foregroundColor: white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
