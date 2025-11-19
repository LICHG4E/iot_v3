import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Manages background monitoring and notifications for device sensor thresholds
///
/// This service runs in the background to monitor IoT device sensors and
/// sends notifications when values exceed configured thresholds.
class AlertMonitoringService {
  // Singleton pattern for service management
  static final AlertMonitoringService _instance = AlertMonitoringService._internal();
  factory AlertMonitoringService() => _instance;
  AlertMonitoringService._internal();

  // Notification plugin instance
  static final FlutterLocalNotificationsPlugin _notificationPlugin = FlutterLocalNotificationsPlugin();

  // Background service instance
  static final FlutterBackgroundService _backgroundService = FlutterBackgroundService();

  // Configuration constants
  static const Duration _checkInterval = Duration(minutes: 1);
  static const String _serviceChannelId = 'alert_monitoring_service';
  static const String _deviceAlertChannelId = 'device_alerts';
  static const String _fireAlertChannelId = 'fire_alerts';

  // Notification IDs
  static const int _serviceNotificationId = 1;
  static const int _fireNotificationId = 999;

  // Service communication events
  static const String _setUserIdEvent = 'setUserId';
  static const String _stopServiceEvent = 'stopService';

  /// Initialize notification channels and service configuration
  Future<void> initialize() async {
    _logInfo('Initializing alert monitoring service');

    await _initializeNotifications();
    await _configureBackgroundService();

    _logInfo('Service initialization complete');
  }

  /// Initialize notification plugin with channels
  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_bg_service_small');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notificationPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channels for Android 8.0+
    await _createNotificationChannels();
  }

  /// Create notification channels with appropriate priorities
  Future<void> _createNotificationChannels() async {
    final androidPlugin = _notificationPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Service notification channel (low priority, persistent)
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _serviceChannelId,
          'Background Service',
          description: 'Monitors device sensors in the background',
          importance: Importance.low,
          showBadge: false,
        ),
      );

      // Device alert channel (high priority)
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _deviceAlertChannelId,
          'Device Alerts',
          description: 'Notifications when sensor readings exceed thresholds',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ),
      );

      // Fire alert channel (max priority, critical)
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _fireAlertChannelId,
          'Fire Alerts',
          description: 'Critical alerts for fire detection',
          importance: Importance.max,
          enableVibration: true,
          enableLights: true,
          playSound: true,
        ),
      );
    }
  }

  /// Configure background service parameters
  Future<void> _configureBackgroundService() async {
    await _backgroundService.configure(
      androidConfiguration: AndroidConfiguration(
        autoStart: true,
        onStart: _onServiceStart,
        isForegroundMode: true,
        autoStartOnBoot: true,
        notificationChannelId: _serviceChannelId,
        initialNotificationTitle: 'PlantCare Monitoring',
        initialNotificationContent: 'Monitoring your devices...',
        foregroundServiceNotificationId: _serviceNotificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: _onServiceStart,
      ),
    );
  }

  /// Start the background monitoring service
  void start(String userId) {
    if (userId.isEmpty) {
      _logError('Cannot start service: userId is empty');
      return;
    }

    _logInfo('Starting service for user: $userId');
    _backgroundService.startService();
    _backgroundService.invoke(_setUserIdEvent, {"userId": userId});
  }

  /// Stop the background monitoring service
  void stop() {
    _logInfo('Stopping background service');
    _backgroundService.invoke(_stopServiceEvent);
  }

  /// Entry point for background service execution
  @pragma('vm:entry-point')
  static Future<void> _onServiceStart(ServiceInstance service) async {
    _logInfo('Background service started');

    // Initialize Firebase for background operations
    await Firebase.initializeApp();
    _logInfo('Firebase initialized in background');

    String? userId;
    final Set<String> notifiedDevices = {};
    DateTime? lastNotificationCheck;

    if (service is AndroidServiceInstance) {
      // Listen for user ID from main isolate
      service.on(_setUserIdEvent).listen((event) {
        service.setAsForegroundService();
        userId = event?['userId'] as String?;
        _logInfo('User ID received: $userId');
      });

      // Listen for stop command
      service.on(_stopServiceEvent).listen((event) {
        _logInfo('Service stop requested');
        service.stopSelf();
      });

      // Wait for userId to be set
      while (userId == null || userId!.isEmpty) {
        await Future.delayed(const Duration(seconds: 1));
      }

      // Main monitoring loop
      Timer.periodic(_checkInterval, (timer) async {
        try {
          _logInfo('Running periodic check for user: $userId');

          // Load fresh settings
          final settings = await _UserSettings.load(userId!);

          if (!settings.pushNotifications) {
            _logInfo('Push notifications disabled, skipping check');
            return;
          }

          // Check devices and notify if needed
          await _checkAllDevices(
            userId: userId!,
            settings: settings,
            notifiedDevices: notifiedDevices,
            lastCheck: lastNotificationCheck,
          );

          lastNotificationCheck = DateTime.now();

          // Clean up old notification tracking (after 5 minutes)
          final lastCheck = lastNotificationCheck;
          if (lastCheck != null && DateTime.now().difference(lastCheck).inMinutes > 5) {
            notifiedDevices.clear();
          }
        } catch (e, stackTrace) {
          _logError('Error in monitoring loop: $e\n$stackTrace');
        }
      });
    }
  }

  /// Check all devices for a user
  static Future<void> _checkAllDevices({
    required String userId,
    required _UserSettings settings,
    required Set<String> notifiedDevices,
    DateTime? lastCheck,
  }) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        _logWarning('User document not found: $userId');
        return;
      }

      final deviceIds = List<String>.from(userDoc.data()?['devices'] ?? []);
      _logInfo('Checking ${deviceIds.length} devices');

      for (final deviceId in deviceIds) {
        await _checkDevice(
          deviceId: deviceId,
          settings: settings,
          notifiedDevices: notifiedDevices,
        );
      }
    } catch (e, stackTrace) {
      _logError('Error checking devices: $e\n$stackTrace');
    }
  }

  /// Check a single device for threshold violations
  static Future<void> _checkDevice({
    required String deviceId,
    required _UserSettings settings,
    required Set<String> notifiedDevices,
  }) async {
    try {
      final latestData = await _fetchLatestDeviceData(deviceId);

      if (latestData == null) {
        _logWarning('No data found for device: $deviceId');
        return;
      }

      final readings = _DeviceReadings.fromFirestore(latestData);
      final violations = _checkThresholdViolations(readings, settings);

      // Send notifications for violations
      for (final violation in violations) {
        final notificationKey = '$deviceId:${violation.type}';

        // Avoid duplicate notifications (debounce for 5 minutes)
        if (!notifiedDevices.contains(notificationKey)) {
          await _sendDeviceAlert(
            deviceId: deviceId,
            title: violation.title,
            body: violation.message,
          );
          notifiedDevices.add(notificationKey);
        }
      }

      // Check for fire alert (always notify immediately)
      if (settings.pushFireNotifications && readings.fireDetected) {
        await _sendFireAlert();
      }
    } catch (e, stackTrace) {
      _logError('Error checking device $deviceId: $e\n$stackTrace');
    }
  }

  /// Fetch latest data from Firestore for a device
  static Future<Map<String, dynamic>?> _fetchLatestDeviceData(String deviceId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('beaglebones').doc(deviceId).collection('data').orderBy('timestamp', descending: true).limit(1).get();

      return querySnapshot.docs.isNotEmpty ? querySnapshot.docs.first.data() : null;
    } catch (e) {
      _logError('Error fetching device data: $e');
      return null;
    }
  }

  /// Check all threshold violations
  static List<_ThresholdViolation> _checkThresholdViolations(
    _DeviceReadings readings,
    _UserSettings settings,
  ) {
    final violations = <_ThresholdViolation>[];

    // Temperature check
    if (settings.isTemperatureRangeEnabled) {
      if (readings.temperature < settings.minTemperature) {
        violations.add(_ThresholdViolation(
          type: 'temperature_low',
          title: 'Temperature Alert',
          message: 'Temperature is too low: ${readings.temperature}°C',
        ));
      } else if (readings.temperature > settings.maxTemperature) {
        violations.add(_ThresholdViolation(
          type: 'temperature_high',
          title: 'Temperature Alert',
          message: 'Temperature is too high: ${readings.temperature}°C',
        ));
      }
    }

    // Humidity check
    if (settings.isHumidityRangeEnabled) {
      if (readings.humidity < settings.minHumidity) {
        violations.add(_ThresholdViolation(
          type: 'humidity_low',
          title: 'Humidity Alert',
          message: 'Humidity is too low: ${readings.humidity}%',
        ));
      } else if (readings.humidity > settings.maxHumidity) {
        violations.add(_ThresholdViolation(
          type: 'humidity_high',
          title: 'Humidity Alert',
          message: 'Humidity is too high: ${readings.humidity}%',
        ));
      }
    }

    // Pressure check
    if (settings.isPressureRangeEnabled) {
      if (readings.pressure < settings.minPressure) {
        violations.add(_ThresholdViolation(
          type: 'pressure_low',
          title: 'Pressure Alert',
          message: 'Pressure is too low: ${readings.pressure} hPa',
        ));
      } else if (readings.pressure > settings.maxPressure) {
        violations.add(_ThresholdViolation(
          type: 'pressure_high',
          title: 'Pressure Alert',
          message: 'Pressure is too high: ${readings.pressure} hPa',
        ));
      }
    }

    // Light check
    if (settings.isLightRangeEnabled) {
      if (readings.light < settings.minLightPercentage) {
        violations.add(_ThresholdViolation(
          type: 'light_low',
          title: 'Light Alert',
          message: 'Light level is too low: ${readings.light}%',
        ));
      } else if (readings.light > settings.maxLightPercentage) {
        violations.add(_ThresholdViolation(
          type: 'light_high',
          title: 'Light Alert',
          message: 'Light level is too high: ${readings.light}%',
        ));
      }
    }

    return violations;
  }

  /// Send device threshold alert notification
  static Future<void> _sendDeviceAlert({
    required String deviceId,
    required String title,
    required String body,
  }) async {
    _logInfo('Sending device alert: $deviceId - $title');

    const androidDetails = AndroidNotificationDetails(
      _deviceAlertChannelId,
      'Device Alerts',
      channelDescription: 'Notifications when sensor readings exceed thresholds',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    // Generate unique ID from device and title
    final notificationId = (deviceId.hashCode ^ title.hashCode) & 0x7FFFFFFF;

    await _notificationPlugin.show(
      notificationId,
      deviceId,
      '$title\n$body',
      notificationDetails,
      payload: deviceId,
    );
  }

  /// Send critical fire alert notification
  static Future<void> _sendFireAlert() async {
    _logInfo('Sending fire alert notification');

    const androidDetails = AndroidNotificationDetails(
      _fireAlertChannelId,
      'Fire Alerts',
      channelDescription: 'Critical alerts for fire detection',
      importance: Importance.max,
      priority: Priority.max,
      enableVibration: true,
      enableLights: true,
      playSound: true,
      ongoing: false,
      autoCancel: false,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationPlugin.show(
      _fireNotificationId,
      '🔥 FIRE ALERT',
      'Fire has been detected! Please check your device immediately.',
      notificationDetails,
    );
  }

  /// Handle notification tap
  static void _onNotificationTap(NotificationResponse response) {
    _logInfo('Notification tapped: ${response.payload}');
    // TODO: Navigate to device details page if needed
  }

  // Logging utilities
  static void _logInfo(String message) {
    debugPrint('[AlertService] ℹ️ $message');
  }

  static void _logWarning(String message) {
    debugPrint('[AlertService] ⚠️ $message');
  }

  static void _logError(String message) {
    debugPrint('[AlertService] ❌ $message');
  }
}

/// User settings model for threshold configuration
class _UserSettings {
  final bool pushNotifications;
  final bool pushFireNotifications;
  final bool isTemperatureRangeEnabled;
  final double minTemperature;
  final double maxTemperature;
  final bool isHumidityRangeEnabled;
  final double minHumidity;
  final double maxHumidity;
  final bool isPressureRangeEnabled;
  final double minPressure;
  final double maxPressure;
  final bool isLightRangeEnabled;
  final double minLightPercentage;
  final double maxLightPercentage;

  const _UserSettings({
    required this.pushNotifications,
    required this.pushFireNotifications,
    required this.isTemperatureRangeEnabled,
    required this.minTemperature,
    required this.maxTemperature,
    required this.isHumidityRangeEnabled,
    required this.minHumidity,
    required this.maxHumidity,
    required this.isPressureRangeEnabled,
    required this.minPressure,
    required this.maxPressure,
    required this.isLightRangeEnabled,
    required this.minLightPercentage,
    required this.maxLightPercentage,
  });

  /// Load settings from SharedPreferences
  static Future<_UserSettings> load(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // Ensure fresh data

    return _UserSettings(
      pushNotifications: prefs.getBool('${userId}_pushNotifications') ?? true,
      pushFireNotifications: prefs.getBool('${userId}_pushFireNotifications') ?? true,
      isTemperatureRangeEnabled: prefs.getBool('${userId}_isTempNotifications') ?? true,
      minTemperature: prefs.getDouble('${userId}_minTemperature') ?? 15.0,
      maxTemperature: prefs.getDouble('${userId}_maxTemperature') ?? 35.0,
      isHumidityRangeEnabled: prefs.getBool('${userId}_isHumidityRangeEnabled') ?? true,
      minHumidity: prefs.getDouble('${userId}_minHumidity') ?? 30.0,
      maxHumidity: prefs.getDouble('${userId}_maxHumidity') ?? 70.0,
      isPressureRangeEnabled: prefs.getBool('${userId}_isPressureRangeEnabled') ?? true,
      minPressure: prefs.getDouble('${userId}_minPressure') ?? 980.0,
      maxPressure: prefs.getDouble('${userId}_maxPressure') ?? 1030.0,
      isLightRangeEnabled: prefs.getBool('${userId}_isLightRangeEnabled') ?? true,
      minLightPercentage: prefs.getDouble('${userId}_minLightPercentage') ?? 20.0,
      maxLightPercentage: prefs.getDouble('${userId}_maxLightPercentage') ?? 80.0,
    );
  }
}

/// Device sensor readings model
class _DeviceReadings {
  final double temperature;
  final double humidity;
  final double pressure;
  final double light;
  final bool fireDetected;

  const _DeviceReadings({
    required this.temperature,
    required this.humidity,
    required this.pressure,
    required this.light,
    required this.fireDetected,
  });

  /// Parse readings from Firestore document
  factory _DeviceReadings.fromFirestore(Map<String, dynamic> data) {
    return _DeviceReadings(
      temperature: _parseDouble(data['temperature_celsius']),
      humidity: _parseDouble(data['humidity_percent']),
      pressure: _parseDouble(data['pressure_hpa']),
      light: 100.0 - _parseDouble(data['light_intensity_percent']),
      fireDetected: data['fire_status'] == 'Fire Detected!',
    );
  }

  /// Safely parse double values with fallback
  static double _parseDouble(dynamic value) {
    try {
      if (value == null) return 0.0;
      final parsed = double.parse(value.toString());
      return double.parse(parsed.toStringAsFixed(1));
    } catch (e) {
      return 0.0;
    }
  }
}

/// Threshold violation model
class _ThresholdViolation {
  final String type;
  final String title;
  final String message;

  const _ThresholdViolation({
    required this.type,
    required this.title,
    required this.message,
  });
}

// Backward compatibility exports (deprecated - use AlertMonitoringService instead)
@Deprecated('Use AlertMonitoringService instead')
class NotificationTask {
  static Future<void> initializeService() => AlertMonitoringService().initialize();

  static void startService(String userId) => AlertMonitoringService().start(userId);

  static void stopService() => AlertMonitoringService().stop();
}
