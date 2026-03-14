import 'package:flutter/material.dart';

class AppTheme {
  // Lithosphere Palette
  static const Color obsidian = Color(0xFF0F1115);
  static const Color mantleGray = Color(0xFF1C1F26);
  static const Color magmaOrange = Color(0xFFFF5722);
  static const Color sulfurYellow = Color(0xFFFFD600);
  static const Color tectonicBlue = Color(0xFF2196F3);
  static const Color basaltLight = Color(0xFFE0E0E0);
  static const Color highVizRed = Color(0xFFFF1744);

  static const TextTheme appTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'Oswald',
      fontSize: 57,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 22,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'OpenSans',
      fontSize: 16,
      letterSpacing: 0.5,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'OpenSans',
      fontSize: 14,
      letterSpacing: 0.25,
    ),
    labelLarge: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 14,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.25,
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: tectonicBlue,
      primary: tectonicBlue,
      secondary: magmaOrange,
      surface: Colors.white,
      error: highVizRed,
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F7FA),
    textTheme: appTextTheme.apply(
      bodyColor: obsidian,
      displayColor: obsidian,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: tectonicBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Oswald',
        fontSize: 22,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE0E4E8)),
      ),
      color: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: tectonicBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: appTextTheme.labelLarge,
        elevation: 0,
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: magmaOrange,
      secondary: tectonicBlue,
      surface: mantleGray,
      error: highVizRed,
      onPrimary: Colors.white,
      onSurface: basaltLight,
    ),
    scaffoldBackgroundColor: obsidian,
    textTheme: appTextTheme.apply(
      bodyColor: basaltLight,
      displayColor: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: obsidian,
      foregroundColor: magmaOrange,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Oswald',
        fontSize: 22,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withAlpha(20)),
      ),
      color: mantleGray,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: obsidian,
      selectedItemColor: magmaOrange,
      unselectedItemColor: Colors.grey,
      elevation: 8,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: magmaOrange,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: appTextTheme.labelLarge,
        elevation: 0,
      ),
    ),
  );
}
