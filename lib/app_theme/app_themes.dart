import 'package:flutter/material.dart';
import 'package:iot_v3/app_theme/custom_themes/elevated_button_theme.dart';
import 'package:iot_v3/app_theme/custom_themes/list_tile_theme.dart';
import 'package:iot_v3/app_theme/custom_themes/text_theme.dart';

import 'custom_themes/input_decoration_theme.dart';

class AppThemes {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: Colors.green,
    inputDecorationTheme: MyInputDecorationTheme.lightInputDecorationTheme,
    hintColor: const Color(0xFF3E853E),
    scaffoldBackgroundColor: Colors.white,
    textTheme: MyTextTheme.lightTextTheme,
    iconTheme: const IconThemeData(color: Colors.black),
    elevatedButtonTheme: MyElevatedButtonTheme.lightElevatedButtonTheme,
    listTileTheme: MyListTileTheme.lightListTileTheme,
    snackBarTheme: const SnackBarThemeData(
      showCloseIcon: true,
      closeIconColor: Colors.white,
      elevation: 4,
      backgroundColor: Colors.green,
      contentTextStyle: TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      dismissDirection: DismissDirection.horizontal,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: Colors.green,
    inputDecorationTheme: MyInputDecorationTheme.darkInputDecorationTheme,
    hintColor: const Color(0xFF3E853E),
    scaffoldBackgroundColor: Colors.black54,
    textTheme: MyTextTheme.darkTextTheme,
    iconTheme: const IconThemeData(color: Colors.white),
    elevatedButtonTheme: MyElevatedButtonTheme.darkElevatedButtonTheme,
    listTileTheme: MyListTileTheme.darkListTileTheme,
    snackBarTheme: const SnackBarThemeData(
      showCloseIcon: true,
      closeIconColor: Colors.white,
      elevation: 4,
      backgroundColor: Colors.green,
      contentTextStyle: TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      dismissDirection: DismissDirection.horizontal,
    ),
  );
}
