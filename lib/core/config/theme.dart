import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xFF1A1A2E);
  static const Color accentColor = Color(0xFFE94560);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);

  // Reading Theme Colors
  static const Color sepiaBackground = Color(0xFFFBF0D9);
  static const Color sepiaText = Color(0xFF5B4636);
  static const Color darkBackground = Color(0xFF1A1A1A);
  static const Color darkText = Color(0xFFE5E5E5);

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
      surface: surfaceColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: surfaceColor,
      foregroundColor: textPrimary,
      titleTextStyle: GoogleFonts.merriweather(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.merriweather(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      displayMedium: GoogleFonts.merriweather(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      titleLarge: GoogleFonts.merriweather(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        color: textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        color: textSecondary,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[100],
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
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: textSecondary,
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: Colors.white,
    scaffoldBackgroundColor: darkBackground,
    colorScheme: ColorScheme.dark(
      primary: Colors.white,
      secondary: accentColor,
      surface: const Color(0xFF2A2A2A),
      onPrimary: darkBackground,
      onSecondary: Colors.white,
      onSurface: darkText,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: darkBackground,
      foregroundColor: darkText,
      titleTextStyle: GoogleFonts.merriweather(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: darkText,
      ),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.merriweather(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: darkText,
      ),
      titleLarge: GoogleFonts.merriweather(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: darkText,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        color: darkText,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        color: Colors.grey[400],
      ),
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF2A2A2A),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}

// Reading Theme Enum
enum ReadingTheme {
  light,
  dark,
  sepia,
  blue,
  green,
  cream,
}

extension ReadingThemeExtension on ReadingTheme {
  Color get backgroundColor {
    switch (this) {
      case ReadingTheme.light:
        return Colors.white;
      case ReadingTheme.dark:
        return AppTheme.darkBackground;
      case ReadingTheme.sepia:
        return AppTheme.sepiaBackground;
      case ReadingTheme.blue:
        return const Color(0xFFE3F2FD); // Light blue
      case ReadingTheme.green:
        return const Color(0xFFE8F5E9); // Light green
      case ReadingTheme.cream:
        return const Color(0xFFFFFDE7); // Cream/yellow
    }
  }

  Color get textColor {
    switch (this) {
      case ReadingTheme.light:
        return AppTheme.textPrimary;
      case ReadingTheme.dark:
        return AppTheme.darkText;
      case ReadingTheme.sepia:
        return AppTheme.sepiaText;
      case ReadingTheme.blue:
        return const Color(0xFF1A237E); // Dark blue
      case ReadingTheme.green:
        return const Color(0xFF1B5E20); // Dark green
      case ReadingTheme.cream:
        return const Color(0xFF3E2723); // Dark brown
    }
  }

  String get displayName {
    switch (this) {
      case ReadingTheme.light:
        return 'Light';
      case ReadingTheme.dark:
        return 'Dark';
      case ReadingTheme.sepia:
        return 'Sepia';
      case ReadingTheme.blue:
        return 'Blue';
      case ReadingTheme.green:
        return 'Green';
      case ReadingTheme.cream:
        return 'Cream';
    }
  }
}

// Scroll Direction Enum for Reading
enum ScrollDirection {
  horizontal,
  vertical,
  continuous,
}

extension ScrollDirectionExtension on ScrollDirection {
  String get displayName {
    switch (this) {
      case ScrollDirection.horizontal:
        return 'Horizontal';
      case ScrollDirection.vertical:
        return 'Vertical';
      case ScrollDirection.continuous:
        return 'Continuous';
    }
  }

  IconData get icon {
    switch (this) {
      case ScrollDirection.horizontal:
        return Icons.swap_horiz;
      case ScrollDirection.vertical:
        return Icons.swap_vert;
      case ScrollDirection.continuous:
        return Icons.view_day;
    }
  }
}
