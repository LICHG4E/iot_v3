import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationTask {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initializeService() async {
    print("[NotificationTask] Initializing notifications");

    var initializationSettingsAndroid = const AndroidInitializationSettings('@mipmap/ic_bg_service_small');
    var initializationSettings = InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        autoStart: true,
        onStart: onStart,
        isForegroundMode: true,
        autoStartOnBoot: true,
      ),
      iosConfiguration: IosConfiguration(),
    );

    print("[NotificationTask] Service initialized");
  }

  static void startService(String userId) {
    print("[NotificationTask] Starting service with userId: $userId");

    final service = FlutterBackgroundService();
    service.startService();

    service.invoke('setUserId', {"userId": userId});
  }

  static void stopService() {
    print("[NotificationTask] Stopping service");

    final service = FlutterBackgroundService();

    service.invoke("stop");
    print("[NotificationTask] Service stopped");
  }

  @pragma('vm:entry-point')
  static Future<void> onStart(ServiceInstance service) async {
    print("[NotificationTask] Service started");
    await Firebase.initializeApp();
    print("[NotificationTask] Firebase initialized");
    // await _showPersistentNotification();
    String? userId;
    if (service is AndroidServiceInstance) {
      service.on('setUserId').listen((event) {
        service.setAsForegroundService();
        userId = event?['userId'];
        print("[NotificationTask] Received userId: $userId");
      });

      service.on('stop').listen((event) {
        print("[NotificationTask] Stopping service...");
        service.stopSelf(); // Terminates the service.
      });

      while (userId == null || userId!.isEmpty) {
        await Future.delayed(const Duration(seconds: 1));
      }

      Timer.periodic(const Duration(minutes: 1), (timer) async {
        print("[NotificationTask] Loading settings for userId: $userId");

        // Always reload settings to ensure fresh data
        final userSettings = await _loadSettings(userId!);
        print("[NotificationTask] Loaded settings: $userSettings");

        // Proceed with checking devices after settings are loaded
        print("[NotificationTask] Checking devices for userId: $userId");
        await checkDevicesForThresholds(userId!, userSettings);
      });
    }
  }

  static Future<void> checkDevicesForThresholds(String userId, Map<String, dynamic> userSettings) async {
    try {
      print("[NotificationTask] Fetching devices for userId: $userId");

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

      if (userDoc.exists) {
        List<String> deviceIds = List<String>.from(userDoc['devices']);

        for (String deviceId in deviceIds) {
          print("[NotificationTask] Checking device: $deviceId");
          await fetchDeviceDataAndCheckThresholds(deviceId, userSettings);
        }
      } else {
        print("[NotificationTask] User document not found");
      }
    } catch (e) {
      print("[NotificationTask] Error checking devices: $e");
    }
  }

  static Future<void> fetchDeviceDataAndCheckThresholds(String deviceId, Map<String, dynamic> userSettings) async {
    try {
      print("[NotificationTask] Fetching data for device: $deviceId");

      final querySnapshot = await FirebaseFirestore.instance
          .collection('beaglebones')
          .doc(deviceId)
          .collection('data')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final latestData = querySnapshot.docs.first.data();
        print("[NotificationTask] Latest data for device $deviceId: $latestData");

        checkThresholdsAndNotify(deviceId, latestData, userSettings);
      } else {
        print("[NotificationTask] No data found for device: $deviceId");
      }
    } catch (e) {
      print("[NotificationTask] Error fetching data for device $deviceId: $e");
    }
  }

  static double formatValue(dynamic value) {
    try {
      return double.parse(value.toStringAsFixed(1));
    } catch (e) {
      return 0;
    }
  }

  static void checkThresholdsAndNotify(String deviceId, Map<String, dynamic> latestData, Map<String, dynamic> userSettings) {
    try {
      print("[NotificationTask] Checking thresholds for device: $deviceId");

      // Extract device readings
      double temperature = formatValue(latestData['temperature_celsius']);
      double humidity = formatValue(latestData['humidity_percent']);
      double pressure = formatValue(latestData['pressure_hpa']);
      double light = formatValue((100 - latestData['light_intensity_percent']));

      // Check thresholds
      if (userSettings['pushNotifications'] && userSettings['isTemperatureRangeEnabled']) {
        if (temperature < userSettings['minTemperature'] || temperature > userSettings['maxTemperature']) {
          print("[NotificationTask] Temperature out of range: $temperature°C");
          _showLocalNotification(deviceId, "Temperature Alert", "Temperature is out of range: $temperature°C");
        }
      }

      if (userSettings['pushNotifications'] && userSettings['isHumidityRangeEnabled']) {
        if (humidity < userSettings['minHumidity'] || humidity > userSettings['maxHumidity']) {
          print("[NotificationTask] Humidity out of range: $humidity%");
          _showLocalNotification(deviceId, "Humidity Alert", "Humidity is out of range: $humidity%");
        }
      }

      if (userSettings['pushNotifications'] && userSettings['isPressureRangeEnabled']) {
        if (pressure < userSettings['minPressure'] || pressure > userSettings['maxPressure']) {
          print("[NotificationTask] Pressure out of range: $pressure hPa");
          _showLocalNotification(deviceId, "Pressure Alert", "Pressure is out of range: $pressure hPa");
        }
      }

      if (userSettings['pushNotifications'] && userSettings['isLightRangeEnabled']) {
        if (light < userSettings['minLightPercentage'] || light > userSettings['maxLightPercentage']) {
          print("[NotificationTask] Light out of range: $light%");
          _showLocalNotification(deviceId, "Light Alert", "Light is out of range: $light%");
        }
      }

      if (userSettings['pushNotifications'] &&
          userSettings["pushFireNotifications"] &&
          latestData['fire_status'] == 'Fire Detected!') {
        print("[NotificationTask] Fire detected for device: $deviceId");
        showFireAlertNotification(latestData['fire_status']);
      }
    } catch (e) {
      print("[NotificationTask] Error checking thresholds for device $deviceId: $e");
    }
  }

  static Future<void> showFireAlertNotification(String fireStatus) async {
    print("[NotificationTask] Fire alert triggered with status: $fireStatus");

    var androidDetails = const AndroidNotificationDetails(
      'fire_alert_channel', // Unique channel ID
      'Fire Alerts', // Channel name
      channelDescription: 'Alerts for fire detection.', // Channel description
      importance: Importance.high, // High importance for heads-up notification
      priority: Priority.high, // High priority
      sound: UriAndroidNotificationSound("assets/sounds/fire_alarm.mp3"), // Custom sound
      playSound: true, // Enable sound playback
      enableVibration: true, // Enable vibration
      ongoing: false, // Allow dismissal
    );

    var notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      2, // Unique ID for the fire alert
      "Fire Alert", // Title
      "Warning: $fireStatus", // Body with the fire status
      notificationDetails,
    );
  }

  static Future<void> _showPersistentNotification() async {
    print("[NotificationTask] Showing persistent notification");

    var androidDetails = const AndroidNotificationDetails(
      'persistent_service_channel', // Unique channel ID
      'App Service', // Channel name
      channelDescription: 'Indicates that the app service is running.', // Channel description
      importance: Importance.low, // Low importance for persistent notifications
      priority: Priority.low, // Low priority to keep it unobtrusive
      ongoing: true, // Mark as ongoing to make it persistent
    );

    var notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      1, // Unique notification ID for the persistent notification
      "PlantCare", // Title
      "Service is running in the background.", // Body
      notificationDetails,
    );
  }

  static Future<void> _showLocalNotification(String deviceId, String title, String body) async {
    print("[NotificationTask] Showing notification: $deviceId - $title \n $body");

    var androidDetails = const AndroidNotificationDetails(
      'device_alert_channel',
      'Device Alerts',
      channelDescription: 'Notifications for device threshold breaches.',
      importance: Importance.max,
      priority: Priority.high,
    );

    var notificationDetails = NotificationDetails(android: androidDetails);

    // Generate a unique notification ID based on the device ID and title
    int notificationId = deviceId.hashCode ^ title.hashCode;

    await flutterLocalNotificationsPlugin.show(
      notificationId, // Use a unique ID for each notification
      deviceId,
      "$title \n $body",
      payload: deviceId,
      notificationDetails,
    );
  }

  static Future<Map<String, dynamic>> _loadSettings(String userId) async {
    print("[NotificationTask] Loading settings from SharedPreferences for userId: $userId");

    final prefs = await SharedPreferences.getInstance();
    prefs.reload();
    print("[NotificationTask] prefs ${userId}_pushNotifications : ${prefs.getBool('${userId}_pushNotifications')}");
    Map<String, dynamic> userSettings = {
      'pushNotifications': prefs.getBool('${userId}_pushNotifications') ?? true,
      'isTemperatureRangeEnabled': prefs.getBool('${userId}_isTempNotifications') ?? true,
      'pushFireNotifications': prefs.getBool('${userId}_pushFireNotifications') ?? true,
      'minTemperature': prefs.getDouble('${userId}_minTemperature') ?? 20,
      'maxTemperature': prefs.getDouble('${userId}_maxTemperature') ?? 30,
      'isHumidityRangeEnabled': prefs.getBool('${userId}_isHumidityRangeEnabled') ?? true,
      'minHumidity': prefs.getDouble('${userId}_minHumidity') ?? 40,
      'maxHumidity': prefs.getDouble('${userId}_maxHumidity') ?? 60,
      'isPressureRangeEnabled': prefs.getBool('${userId}_isPressureRangeEnabled') ?? true,
      'minPressure': prefs.getDouble('${userId}_minPressure') ?? 1000,
      'maxPressure': prefs.getDouble('${userId}_maxPressure') ?? 1020,
      'isLightRangeEnabled': prefs.getBool('${userId}_isLightRangeEnabled') ?? true,
      'minLightPercentage': prefs.getDouble('${userId}_minLightPercentage') ?? 30,
      'maxLightPercentage': prefs.getDouble('${userId}_maxLightPercentage') ?? 70,
    };

    return userSettings;
  }
}
