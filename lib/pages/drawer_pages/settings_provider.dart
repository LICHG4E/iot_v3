import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool pushNotifications = true;
  int chartUpdateInterval = 6;
  bool isTemperatureRangeEnabled = true;
  double minTemperature = 20;
  double maxTemperature = 30;
  bool isHumidityRangeEnabled = true;
  double minHumidity = 40;
  double maxHumidity = 60;
  bool isPressureRangeEnabled = true;
  double minPressure = 1000;
  double maxPressure = 1020;
  bool isLightRangeEnabled = true;
  double minLightPercentage = 30;
  double maxLightPercentage = 70;

  SettingsProvider() {
    _loadSettingsFromPreferences();
  }

  void setPushNotifications(bool value) {
    pushNotifications = value;
    _saveSettingsToPreferences();
    notifyListeners();
  }

  void setNumberOfMinutes(int value) {
    chartUpdateInterval = value;
    _saveSettingsToPreferences();
    notifyListeners();
  }

  void setIsTemperatureRangeEnabled(bool value) {
    isTemperatureRangeEnabled = value;
    _saveSettingsToPreferences();
    notifyListeners();
  }

  void setMinTemperature(double value) {
    minTemperature = value;
    _saveSettingsToPreferences();
    notifyListeners();
  }

  void setMaxTemperature(double value) {
    maxTemperature = value;
    _saveSettingsToPreferences();
    notifyListeners();
  }

  void setIsHumidityRangeEnabled(bool value) {
    isHumidityRangeEnabled = value;
    _saveSettingsToPreferences();
    notifyListeners();
  }

  void setMinHumidity(double value) {
    minHumidity = value;
    _saveSettingsToPreferences();
    notifyListeners();
  }

  void setMaxHumidity(double value) {
    maxHumidity = value;
    _saveSettingsToPreferences();
    notifyListeners();
  }

  void setIsPressureRangeEnabled(bool value) {
    isPressureRangeEnabled = value;
    _saveSettingsToPreferences();
    notifyListeners();
  }

  void setMinPressure(double value) {
    minPressure = value;
    _saveSettingsToPreferences();
    notifyListeners();
  }

  void setMaxPressure(double value) {
    maxPressure = value;
    _saveSettingsToPreferences();
    notifyListeners();
  }

  void setIsLightRangeEnabled(bool value) {
    isLightRangeEnabled = value;
    _saveSettingsToPreferences();
    notifyListeners();
  }

  void setMinLightPercentage(double value) {
    minLightPercentage = value;
    _saveSettingsToPreferences();
    notifyListeners();
  }

  void setMaxLightPercentage(double value) {
    maxLightPercentage = value;
    _saveSettingsToPreferences();
    notifyListeners();
  }

  Future<void> _loadSettingsFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    pushNotifications = prefs.getBool('pushNotifications') ?? true;
    chartUpdateInterval = prefs.getInt('numberOfMinutes') ?? 6;
    isTemperatureRangeEnabled = prefs.getBool('isTemperatureRangeEnabled') ?? true;
    minTemperature = prefs.getDouble('minTemperature') ?? 20;
    maxTemperature = prefs.getDouble('maxTemperature') ?? 30;
    isHumidityRangeEnabled = prefs.getBool('isHumidityRangeEnabled') ?? true;
    minHumidity = prefs.getDouble('minHumidity') ?? 40;
    maxHumidity = prefs.getDouble('maxHumidity') ?? 60;
    isPressureRangeEnabled = prefs.getBool('isPressureRangeEnabled') ?? true;
    minPressure = prefs.getDouble('minPressure') ?? 1000;
    maxPressure = prefs.getDouble('maxPressure') ?? 1020;
    isLightRangeEnabled = prefs.getBool('isLightRangeEnabled') ?? true;
    minLightPercentage = prefs.getDouble('minLightPercentage') ?? 30;
    maxLightPercentage = prefs.getDouble('maxLightPercentage') ?? 70;
    notifyListeners();
  }

  Future<void> _saveSettingsToPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pushNotifications', pushNotifications);
    await prefs.setInt('numberOfMinutes', chartUpdateInterval);
    await prefs.setBool('isTemperatureRangeEnabled', isTemperatureRangeEnabled);
    await prefs.setDouble('minTemperature', minTemperature);
    await prefs.setDouble('maxTemperature', maxTemperature);
    await prefs.setBool('isHumidityRangeEnabled', isHumidityRangeEnabled);
    await prefs.setDouble('minHumidity', minHumidity);
    await prefs.setDouble('maxHumidity', maxHumidity);
    await prefs.setBool('isPressureRangeEnabled', isPressureRangeEnabled);
    await prefs.setDouble('minPressure', minPressure);
    await prefs.setDouble('maxPressure', maxPressure);
    await prefs.setBool('isLightRangeEnabled', isLightRangeEnabled);
    await prefs.setDouble('minLightPercentage', minLightPercentage);
    await prefs.setDouble('maxLightPercentage', maxLightPercentage);
  }
}
