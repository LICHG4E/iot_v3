import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:iot_v3/app_theme/theme_provider.dart';
import 'package:iot_v3/constants/routes.dart';
import 'package:iot_v3/pages/auth_pages/register_page.dart';
import 'package:iot_v3/pages/camera_screen.dart';
import 'package:iot_v3/pages/device_data.dart';
import 'package:iot_v3/pages/device_qr_scanner.dart';
import 'package:iot_v3/pages/auth_pages/forgot_pass_page.dart';
import 'package:iot_v3/pages/drawer_pages/profile_page.dart';
import 'package:iot_v3/pages/drawer_pages/setting_page.dart';
import 'package:iot_v3/pages/drawer_pages/settings_provider.dart';
import 'package:iot_v3/pages/home_page.dart';
import 'package:iot_v3/pages/auth_pages/login_page.dart';
import 'package:iot_v3/pages/scan_screen.dart';
import 'package:iot_v3/pages/drawer_pages/user_provider.dart';
import 'package:provider/provider.dart';
import 'main_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()), // Add UserProvider
        ChangeNotifierProvider(
          create: (context) => SettingsProvider(),
        )
      ],
      child: MyApp(cameras: cameras),
    ),
  );
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: Provider.of<ThemeProvider>(context).themeData,
      home: MainPage(
        cameras: cameras,
      ),
      routes: {
        mainPage: (context) => MainPage(
              cameras: cameras,
            ),
        scanScreen: (context) => ScanScreen(
              imagePath: ModalRoute.of(context)!.settings.arguments as String,
            ),
        cameraScreen: (context) => CameraScreen(cameras: cameras),
        loginPage: (context) => const LoginPage(),
        homePage: (context) => HomePage(
              userUID: ModalRoute.of(context)!.settings.arguments as String,
              cameras: cameras,
            ),
        registerPage: (context) => const RegisterPage(),
        deviceDataPage: (context) => DeviceDataPage(
              deviceId: ModalRoute.of(context)!.settings.arguments as String,
            ),
        deviceQRScanner: (context) => const DeviceQrScanner(),
        forgotPasswordPage: (context) => const ForgotPassPage(),
        profilePage: (context) => const ProfilePage(),
        settingsPage: (context) => const SettingPage(),
      },
    );
  }
}
