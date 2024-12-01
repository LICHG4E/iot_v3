import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_themes.dart';

class ThemeProvider with ChangeNotifier {
  ThemeData _themeData = AppThemes.lightTheme;
  bool _isLight = true;

  ThemeProvider() {
    _loadThemeFromPreferences();
  }

  ThemeData get themeData => _themeData;
  bool get isLight => _isLight;

  set themeData(ThemeData themeData) {
    _themeData = themeData;
    notifyListeners();
  }

  void toggleTheme(bool isLightMode) {
    _isLight = isLightMode;
    themeData = isLightMode ? AppThemes.lightTheme : AppThemes.darkTheme;
    _saveThemeToPreferences();
  }

  Future<void> _saveThemeToPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLight', _isLight);
  }

  Future<void> _loadThemeFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isLight = prefs.getBool('isLight') ?? true;
    themeData = _isLight ? AppThemes.lightTheme : AppThemes.darkTheme;
    notifyListeners();
  }
}
