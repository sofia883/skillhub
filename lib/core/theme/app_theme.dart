import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary Colors
  static const Color primaryColor = Color(0xFF6B4EFF); // Purple
  static const Color primaryLightColor = Color(0xFFF1EEFF); // Light purple
  static const Color backgroundColor = Colors.white;
  static const Color textColor = Color(0xFF1A1A1A);
  static const Color secondaryTextColor = Color(0xFF666666);

  // Text Colors
  static const Color textPrimaryColor = Color(0xFF1A1A1A);
  static const Color textSecondaryColor = Color(0xFF666666);
  static const Color textLightColor = Color(0xFF999999);

  // Accent Colors
  static const Color accentColor = Color(0xFF00B894); // Mint green
  static const Color successColor = Color(0xFF00B894); // Mint green
  static const Color errorColor = Color(0xFF000000); // Black
  static const Color warningColor = Color(0xFF000000); // Black

  // Font Sizes (extra small)
  static const double fontSizeXSmall = 7.0;
  static const double fontSizeSmall = 9.0;
  static const double fontSizeMedium = 11.0;
  static const double fontSizeLarge = 13.0;
  static const double fontSizeXLarge = 15.0;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: primaryLightColor,
        onSecondary: primaryColor,
        background: backgroundColor,
        surface: backgroundColor,
        onSurface: textColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 12,
          color: textColor,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 11,
          color: textColor,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 10,
          color: secondaryTextColor,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        toolbarHeight: 48, // Smaller toolbar height
        iconTheme: const IconThemeData(
          size: 20, // Smaller icons
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: textLightColor,
        selectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w400,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: primaryLightColor.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        hintStyle: TextStyle(
          fontSize: 11,
          color: textColor.withOpacity(0.5),
        ),
        isDense: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          minimumSize: const Size(double.infinity, 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardTheme(
        color: backgroundColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: primaryColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      iconTheme: const IconThemeData(
        size: 20,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primaryLightColor,
        selectedColor: primaryColor,
        labelStyle: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  // Text Styles (all reduced sizes)
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 16, // Reduced from 18
    fontWeight: FontWeight.w500,
    color: textPrimaryColor,
    letterSpacing: -0.5,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 14, // Reduced from 16
    fontWeight: FontWeight.w500,
    color: textPrimaryColor,
    letterSpacing: -0.5,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 13, // Reduced from 14
    fontWeight: FontWeight.w500,
    color: textPrimaryColor,
    letterSpacing: -0.5,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 12, // Reduced from 14
    fontWeight: FontWeight.w500,
    color: textPrimaryColor,
    letterSpacing: -0.3,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 11, // Reduced from 12
    fontWeight: FontWeight.w500,
    color: textPrimaryColor,
    letterSpacing: -0.3,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 11, // Reduced from 12
    color: textPrimaryColor,
    letterSpacing: -0.3,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 10, // Reduced from 11
    color: textSecondaryColor,
    letterSpacing: -0.3,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 9, // Reduced from 10
    color: textSecondaryColor,
    letterSpacing: -0.3,
  );
}
