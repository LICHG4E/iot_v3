import 'package:flutter/material.dart';
import 'package:iot_v3/app_theme/custom_themes/elevated_button_theme.dart';
import 'package:iot_v3/app_theme/custom_themes/list_tile_theme.dart';
import 'package:iot_v3/app_theme/custom_themes/snackbar_theme.dart';
import 'package:iot_v3/app_theme/custom_themes/text_theme.dart';

import 'custom_themes/expansion_tile_theme.dart';
import 'custom_themes/input_decoration_theme.dart';

class AppThemes {
  // Primary color scheme
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color secondaryGreen = Color(0xFF66BB6A);
  static const Color accentGreen = Color(0xFF81C784);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryGreen,
      brightness: Brightness.light,
      primary: primaryGreen,
      secondary: secondaryGreen,
      tertiary: accentGreen,
    ),
    primaryColor: primaryGreen,
    inputDecorationTheme: MyInputDecorationTheme.lightInputDecorationTheme,
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    cardTheme: CardTheme(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Color(0xFFF5F5F5),
      foregroundColor: Colors.black87,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    textTheme: MyTextTheme.lightTextTheme,
    iconTheme: const IconThemeData(color: Colors.black87),
    elevatedButtonTheme: MyElevatedButtonTheme.lightElevatedButtonTheme,
    listTileTheme: MyListTileTheme.lightListTileTheme,
    snackBarTheme: MySnackBarTheme.lightSnackBarTheme,
    expansionTileTheme: MyExpansionTileTheme.lightExpansionTileTheme,
    dividerTheme: DividerThemeData(
      color: Colors.grey.shade300,
      thickness: 1,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryGreen,
      brightness: Brightness.dark,
      primary: secondaryGreen,
      secondary: accentGreen,
      tertiary: primaryGreen,
    ),
    primaryColor: secondaryGreen,
    inputDecorationTheme: MyInputDecorationTheme.darkInputDecorationTheme,
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardTheme: CardTheme(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: const Color(0xFF1E1E1E),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Color(0xFF121212),
      foregroundColor: Colors.white,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: secondaryGreen,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    textTheme: MyTextTheme.darkTextTheme,
    iconTheme: const IconThemeData(color: Colors.white),
    elevatedButtonTheme: MyElevatedButtonTheme.darkElevatedButtonTheme,
    listTileTheme: MyListTileTheme.darkListTileTheme,
    snackBarTheme: MySnackBarTheme.darkSnackBarTheme,
    expansionTileTheme: MyExpansionTileTheme.darkExpansionTileTheme,
    dividerTheme: DividerThemeData(
      color: Colors.grey.shade800,
      thickness: 1,
    ),
  );
}
