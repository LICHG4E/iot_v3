import 'package:flutter/material.dart';

class MyListTileTheme {
  static ListTileThemeData lightListTileTheme = const ListTileThemeData(
    tileColor: Color(0xFFF5F5F5),
    textColor: Colors.black,
    iconColor: Colors.black,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
    ),
  );

  static ListTileThemeData darkListTileTheme = const ListTileThemeData(
    tileColor: Color(0xFF121212),
    textColor: Colors.white,
    iconColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
    ),
  );
}
