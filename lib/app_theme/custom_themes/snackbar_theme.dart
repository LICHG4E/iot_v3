import 'package:flutter/material.dart';

class MySnackBarTheme {
  static SnackBarThemeData lightSnackBarTheme = const SnackBarThemeData(
    showCloseIcon: true,
    closeIconColor: Colors.white,
    elevation: 4,
    backgroundColor: Colors.green,
    contentTextStyle: TextStyle(color: Colors.white),
    behavior: SnackBarBehavior.floating,
    dismissDirection: DismissDirection.horizontal,
  );

  static SnackBarThemeData darkSnackBarTheme = const SnackBarThemeData(
    showCloseIcon: true,
    closeIconColor: Colors.white,
    elevation: 4,
    backgroundColor: Colors.green,
    contentTextStyle: TextStyle(color: Colors.white),
    behavior: SnackBarBehavior.floating,
    dismissDirection: DismissDirection.horizontal,
  );
}
