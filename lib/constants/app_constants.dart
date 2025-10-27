/// Application-wide constants and configuration
class AppConstants {
  // App Information
  static const String appName = 'PlantCare IoT';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Monitor and care for your plants with IoT devices';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String beaglebonesCollection = 'beaglebones';
  static const String dataSubcollection = 'data';

  // Default Settings
  static const int defaultChartUpdateInterval = 1; // minutes
  static const int defaultChartPoints = 6;
  static const double defaultMinTemperature = 20.0;
  static const double defaultMaxTemperature = 30.0;
  static const double defaultMinHumidity = 40.0;
  static const double defaultMaxHumidity = 60.0;
  static const double defaultMinPressure = 1000.0;
  static const double defaultMaxPressure = 1020.0;
  static const double defaultMinLight = 30.0;
  static const double defaultMaxLight = 70.0;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double cardElevation = 2.0;
  static const int gridCrossAxisCountPortrait = 2;
  static const int gridCrossAxisCountLandscape = 3;

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Validation
  static const int minPasswordLength = 6;
  static const String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';

  // Error Messages
  static const String genericErrorMessage = 'An error occurred. Please try again.';
  static const String networkErrorMessage = 'Network error. Please check your connection.';
  static const String authErrorMessage = 'Authentication failed. Please check your credentials.';

  // Success Messages
  static const String loginSuccessMessage = 'Login successful!';
  static const String registrationSuccessMessage = 'Registration successful!';
  static const String dataFetchedSuccessMessage = 'Data fetched successfully';

  // Asset Paths
  static const String plantAnimationPath = 'assets/animations/plants.riv';
  static const String mailAnimationPath = 'assets/animations/mail.riv';
  static const String plantLogoLightPath = 'assets/animations/plant_logo_loading_in_lightmode.riv';
  static const String plantLogoDarkPath = 'assets/animations/plant_logo_loading_in_darkmode.riv';
  static const String fireAlarmSoundPath = 'assets/sounds/fire_alarm.mp3';

  // Shared Preferences Keys
  static const String themePreferenceKey = 'isLight';
  static const String userIdPreferenceKey = 'userId';
  static const String pushNotificationsKey = 'pushNotifications';
  static const String chartUpdateIntervalKey = 'chartUpdateInterval';
  static const String chartPointsKey = 'chartPoints';

  // Private constructor to prevent instantiation
  AppConstants._();
}
