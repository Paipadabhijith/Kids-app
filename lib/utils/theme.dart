import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Modern, high-contrast kid-friendly palette inspired by top learning apps.
  static const Color primaryColor = Color(0xFF6C63FF); // Indigo-violet
  static const Color secondaryColor = Color(0xFF00B8D9); // Aqua
  static const Color accentColor = Color(0xFFFF9F1C); // Warm orange
  static const Color purpleAccent = Color(0xFF9D7BFF);
  static const Color pinkAccent = Color(0xFFFF5FA2);
  static const Color yellowAccent = Color(0xFFFFD166);
  static const Color errorColor = Color(0xFFFF4D6D);
  static const Color backgroundColor = Color(0xFFF5F7FF);
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF1F2440);
  static const Color textSecondaryColor = Color(0xFF5C6280);
  static const Color darkBackgroundColor = Color(0xFF0E1424);
  static const Color darkCardColor = Color(0xFF18233A);
  static const Color darkTextColor = Color(0xFFEAF0FF);
  static const Color darkTextSecondaryColor = Color(0xFFB4C0DD);
  static const double standardBorderWidth = 1.6;
  static const double focusedBorderWidth = 2.0;
  static const double standardRadius = 18;
  static const double fieldRadius = 14;

  static TextTheme _buildTextTheme({
    required Color bodyColor,
    required Color secondaryBodyColor,
  }) {
    return GoogleFonts.nunitoTextTheme(
      TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: bodyColor,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: bodyColor,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: bodyColor,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: bodyColor,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: bodyColor,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: bodyColor,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: bodyColor,
          height: 1.35,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: bodyColor,
          height: 1.3,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: secondaryBodyColor,
          height: 1.25,
        ),
        labelLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: bodyColor,
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    final textTheme = _buildTextTheme(
      bodyColor: textColor,
      secondaryBodyColor: textSecondaryColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        background: backgroundColor,
        surface: cardColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(standardRadius),
        ),
        shadowColor: const Color(0xFF3A4A99).withOpacity(0.14),
        surfaceTintColor: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shadowColor: Colors.transparent,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        iconTheme: const IconThemeData(color: textColor),
        actionsIconTheme: const IconThemeData(color: textColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(standardRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
          minimumSize: const Size(120, 56), // Large touch targets
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(
            color: primaryColor.withOpacity(0.25),
            width: standardBorderWidth,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(standardRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          minimumSize: const Size(100, 48),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: BorderSide(
            color: primaryColor.withOpacity(0.25),
            width: standardBorderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: BorderSide(
            color: primaryColor.withOpacity(0.18),
            width: standardBorderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: const BorderSide(
            color: primaryColor,
            width: focusedBorderWidth,
          ),
        ),
        hintStyle: const TextStyle(
          color: textSecondaryColor,
          fontWeight: FontWeight.w600,
        ),
        labelStyle: const TextStyle(
          color: textSecondaryColor,
          fontWeight: FontWeight.w700,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: textColor,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      dividerTheme: DividerThemeData(
        color: primaryColor.withOpacity(0.12),
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: textSecondaryColor,
        textColor: textColor,
        titleTextStyle: textTheme.titleMedium?.copyWith(fontSize: 16),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(color: textSecondaryColor),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: primaryColor.withOpacity(0.16),
        disabledColor: Colors.grey.shade200,
        side: BorderSide(
          color: primaryColor.withOpacity(0.22),
          width: standardBorderWidth,
        ),
        labelStyle: const TextStyle(color: textColor, fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(color: textColor),
        brightness: Brightness.light,
      ),
    );
  }

  static ThemeData get darkTheme {
    final textTheme = _buildTextTheme(
      bodyColor: darkTextColor,
      secondaryBodyColor: darkTextSecondaryColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        background: darkBackgroundColor,
        surface: darkCardColor,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: darkBackgroundColor,
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: darkCardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(standardRadius),
          side: BorderSide(
            color: Colors.white.withOpacity(0.08),
            width: standardBorderWidth,
          ),
        ),
        shadowColor: Colors.black.withOpacity(0.35),
        surfaceTintColor: Colors.transparent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackgroundColor,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        foregroundColor: darkTextColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: darkTextColor,
        ),
        iconTheme: const IconThemeData(color: darkTextColor),
        actionsIconTheme: const IconThemeData(color: darkTextColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(standardRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
          minimumSize: const Size(120, 56),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkTextColor,
          side: BorderSide(
            color: Colors.white.withOpacity(0.22),
            width: standardBorderWidth,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(standardRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: secondaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          minimumSize: const Size(100, 48),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.22),
            width: standardBorderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.14),
            width: standardBorderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: const BorderSide(
            color: secondaryColor,
            width: focusedBorderWidth,
          ),
        ),
        hintStyle: const TextStyle(
          color: darkTextSecondaryColor,
          fontWeight: FontWeight.w600,
        ),
        labelStyle: const TextStyle(
          color: darkTextSecondaryColor,
          fontWeight: FontWeight.w700,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: darkCardColor,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.12),
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: darkTextSecondaryColor,
        textColor: darkTextColor,
        titleTextStyle: textTheme.titleMedium?.copyWith(fontSize: 16),
        subtitleTextStyle: textTheme.bodySmall?.copyWith(color: darkTextSecondaryColor),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkCardColor,
        selectedColor: primaryColor.withOpacity(0.25),
        disabledColor: Colors.white.withOpacity(0.08),
        side: BorderSide(
          color: Colors.white.withOpacity(0.12),
          width: standardBorderWidth,
        ),
        labelStyle: const TextStyle(color: darkTextColor, fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(color: darkTextColor),
        brightness: Brightness.dark,
      ),
    );
  }
}

