import 'package:flutter/material.dart';

class MyExpansionTileTheme {
  static ExpansionTileThemeData lightExpansionTileTheme = ExpansionTileThemeData(
    iconColor: Colors.green,
    backgroundColor: Colors.white70,
    textColor: Colors.black,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  );

  static ExpansionTileThemeData darkExpansionTileTheme = ExpansionTileThemeData(
    iconColor: Colors.green,
    backgroundColor: Colors.black45,
    textColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  );
}
