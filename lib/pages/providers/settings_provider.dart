import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  String userId = '';

  bool pushNotifications = true;
  bool pushFireNotifications = true;
  int chartUpdateInterval = 1;
  int chartPoints = 6;
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

  bool get getPushNotifications => pushNotifications;

  bool get getPushFireNotifications => pushFireNotifications;

  int get getChartUpdateInterval => chartUpdateInterval;

  int get getChartPoints => chartPoints;

  bool get getIsTemperatureRangeEnabled => isTemperatureRangeEnabled;

  double get getMinTemperature => minTemperature;

  double get getMaxTemperature => maxTemperature;

  bool get getIsHumidityRangeEnabled => isHumidityRangeEnabled;

  double get getMinHumidity => minHumidity;

  double get getMaxHumidity => maxHumidity;

  bool get getIsPressureRangeEnabled => isPressureRangeEnabled;

  double get getMinPressure => minPressure;

  double get getMaxPressure => maxPressure;

  bool get getIsLightRangeEnabled => isLightRangeEnabled;

  double get getMinLightPercentage => minLightPercentage;

  double get getMaxLightPercentage => maxLightPercentage;

  void setUserId(String value) {
    userId = value;
  }

  void setPushNotifications(bool value) {
    pushNotifications = value;
    _saveSettingsToPreferences();
    print("set pushNotifications in settings provider : $value");
    notifyListeners();
  }

  void setPushFireNotifications(bool value) {
    pushFireNotifications = value;
    _saveSettingsToPreferences();
    notifyListeners();
  }

  void setChartUpdateInterval(int value) {
    chartUpdateInterval = value;
    _saveSettingsToPreferences();
    notifyListeners();
  }

  void setChartPoints(int value) {
    chartPoints = value;
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

  // Load settings from SharedPreferences
  Future<void> _loadSettingsFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    print("load settings : ${prefs.getBool('${userId}_pushNotifications')}");
    pushNotifications = prefs.getBool('${userId}_pushNotifications') ?? true;
    pushFireNotifications = prefs.getBool('${userId}_pushFireNotifications') ?? true;
    chartUpdateInterval = prefs.getInt('${userId}_chartUpdateInterval') ?? 1;
    chartPoints = prefs.getInt('${userId}_chartPoints') ?? 6;
    isTemperatureRangeEnabled = prefs.getBool('${userId}_isTemperatureRangeEnabled') ?? true;
    minTemperature = prefs.getDouble('${userId}_minTemperature') ?? 20;
    maxTemperature = prefs.getDouble('${userId}_maxTemperature') ?? 30;
    isHumidityRangeEnabled = prefs.getBool('${userId}_isHumidityRangeEnabled') ?? true;
    minHumidity = prefs.getDouble('${userId}_minHumidity') ?? 40;
    maxHumidity = prefs.getDouble('${userId}_maxHumidity') ?? 60;
    isPressureRangeEnabled = prefs.getBool('${userId}_isPressureRangeEnabled') ?? true;
    minPressure = prefs.getDouble('${userId}_minPressure') ?? 1000;
    maxPressure = prefs.getDouble('${userId}_maxPressure') ?? 1020;
    isLightRangeEnabled = prefs.getBool('${userId}_isLightRangeEnabled') ?? true;
    minLightPercentage = prefs.getDouble('${userId}_minLightPercentage') ?? 30;
    maxLightPercentage = prefs.getDouble('${userId}_maxLightPercentage') ?? 70;
    prefs.reload();
    notifyListeners();
  }

  // Save settings to SharedPreferences
  Future<void> _saveSettingsToPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
    await prefs.setBool('${userId}_pushNotifications', pushNotifications);
    await prefs.setBool('${userId}_pushFireNotifications', pushFireNotifications);
    await prefs.setInt('${userId}_chartUpdateInterval', chartUpdateInterval);
    await prefs.setInt('${userId}_chartPoints', chartPoints);
    await prefs.setBool('${userId}_isTemperatureRangeEnabled', isTemperatureRangeEnabled);
    await prefs.setDouble('${userId}_minTemperature', minTemperature);
    await prefs.setDouble('${userId}_maxTemperature', maxTemperature);
    await prefs.setBool('${userId}_isHumidityRangeEnabled', isHumidityRangeEnabled);
    await prefs.setDouble('${userId}_minHumidity', minHumidity);
    await prefs.setDouble('${userId}_maxHumidity', maxHumidity);
    await prefs.setBool('${userId}_isPressureRangeEnabled', isPressureRangeEnabled);
    await prefs.setDouble('${userId}_minPressure', minPressure);
    await prefs.setDouble('${userId}_maxPressure', maxPressure);
    await prefs.setBool('${userId}_isLightRangeEnabled', isLightRangeEnabled);
    await prefs.setDouble('${userId}_minLightPercentage', minLightPercentage);
    await prefs.setDouble('${userId}_maxLightPercentage', maxLightPercentage);

    prefs.reload();
  }
}
