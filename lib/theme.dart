import 'package:flutter/material.dart';

class AppTheme {
  static const Color primarySeedColor = Colors.blueGrey;

  static const TextTheme appTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'Oswald',
      fontSize: 57,
      fontWeight: FontWeight.bold,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Roboto',
      fontSize: 22,
      fontWeight: FontWeight.w500,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'OpenSans',
      fontSize: 14,
    ),
  );

  static const AppBarTheme appBarTheme = AppBarTheme(
    backgroundColor: primarySeedColor,
    foregroundColor: Colors.white,
    titleTextStyle: TextStyle(
      fontFamily: 'Oswald',
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primarySeedColor,
    ),
    textTheme: appTextTheme,
    appBarTheme: appBarTheme,
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primarySeedColor,
      brightness: Brightness.dark,
    ),
    textTheme: appTextTheme,
    appBarTheme: appBarTheme.copyWith(backgroundColor: Colors.grey[900]),
  );
}
