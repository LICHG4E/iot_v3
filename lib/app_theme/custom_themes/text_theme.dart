import 'package:flutter/material.dart';

class MyTextTheme {
  static TextTheme lightTextTheme = const TextTheme(
    displayLarge: TextStyle(
      fontSize: 96,
      fontWeight: FontWeight.w300,
      letterSpacing: -1.5,
    ),
    displayMedium: TextStyle(
      fontSize: 60,
      fontWeight: FontWeight.w300,
      letterSpacing: -0.5,
    ),
    displaySmall: TextStyle(
      fontSize: 48,
      fontWeight: FontWeight.w400,
    ),
    headlineMedium: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
    ),
    headlineSmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w400,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 1.25,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
    ),
    labelSmall: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w400,
      letterSpacing: 1.5,
    ),
  );

  static TextTheme darkTextTheme = TextTheme(
    displayLarge: lightTextTheme.displayLarge?.copyWith(color: Colors.white),
    displayMedium: lightTextTheme.displayMedium?.copyWith(color: Colors.white),
    displaySmall: lightTextTheme.displaySmall?.copyWith(color: Colors.white),
    headlineMedium:
        lightTextTheme.headlineMedium?.copyWith(color: Colors.white),
    headlineSmall: lightTextTheme.headlineSmall?.copyWith(color: Colors.white),
    titleLarge: lightTextTheme.titleLarge?.copyWith(color: Colors.white),
    titleMedium: lightTextTheme.titleMedium?.copyWith(color: Colors.white),
    titleSmall: lightTextTheme.titleSmall?.copyWith(color: Colors.white),
    bodyLarge: lightTextTheme.bodyLarge?.copyWith(color: Colors.white),
    bodyMedium: lightTextTheme.bodyMedium?.copyWith(color: Colors.white),
    labelLarge: lightTextTheme.labelLarge?.copyWith(color: Colors.white),
    bodySmall: lightTextTheme.bodySmall?.copyWith(color: Colors.white),
    labelSmall: lightTextTheme.labelSmall?.copyWith(color: Colors.white),
  );
}
