import 'package:camera/camera.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iot_v3/firebase_options.dart';
import 'package:iot_v3/pages/auth_pages/controllers/auth_controller.dart';
import 'package:iot_v3/pages/providers/settings_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:iot_v3/app_theme/theme_provider.dart';
import 'package:iot_v3/pages/auth_pages/register_page.dart';
import 'package:iot_v3/pages/camera_screen.dart';
import 'package:iot_v3/pages/device_data.dart';
import 'package:iot_v3/pages/device_qr_scanner.dart';
import 'package:iot_v3/pages/auth_pages/forgot_pass_page.dart';
import 'package:iot_v3/pages/drawer_pages/about_page.dart';
import 'package:iot_v3/pages/drawer_pages/customer_support_mail.dart';
import 'package:iot_v3/pages/drawer_pages/help_page.dart';
import 'package:iot_v3/pages/drawer_pages/profile_page.dart';
import 'package:iot_v3/pages/drawer_pages/setting_page.dart';
import 'package:iot_v3/pages/home_page.dart';
import 'package:iot_v3/pages/auth_pages/login_page.dart';
import 'package:iot_v3/pages/auth_pages/verify_email_page.dart';
import 'package:iot_v3/pages/scan_screen.dart';
import 'package:iot_v3/pages/providers/user_provider.dart';
import 'package:iot_v3/services/auth_service.dart';
import 'constants/routes.dart';
import 'main_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Initialize Firebase with proper options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize cameras
  final cameras = await availableCameras();

  // Request notification permission
  final notificationStatus = await Permission.notification.status;
  if (notificationStatus.isDenied) {
    await Permission.notification.request();
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (context) => AuthController(context.read<AuthService>())),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
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
      title: 'PlantCare IoT',
      debugShowCheckedModeBanner: false,
      theme: Provider.of<ThemeProvider>(context).themeData,
      home: MainPage(cameras: cameras),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case mainPage:
            return MaterialPageRoute(
              builder: (_) => MainPage(cameras: cameras),
            );
          case scanScreen:
            return MaterialPageRoute(
              builder: (_) => ScanScreen(
                imagePath: settings.arguments as String,
              ),
            );
          case cameraScreen:
            return MaterialPageRoute(
              builder: (_) => CameraScreen(cameras: cameras),
            );
          case loginPage:
            return MaterialPageRoute(builder: (_) => const LoginPage());
          case homePage:
            return MaterialPageRoute(
              builder: (_) => HomePage(
                userUID: settings.arguments as String,
                cameras: cameras,
              ),
            );
          case registerPage:
            return MaterialPageRoute(builder: (_) => const RegisterPage());
          case verifyEmailPage:
            return MaterialPageRoute(builder: (_) => const VerifyEmailPage());
          case deviceDataPage:
            return MaterialPageRoute(
              builder: (_) => DeviceDataPage(
                deviceId: settings.arguments as String,
              ),
            );
          case deviceQRScanner:
            return MaterialPageRoute(builder: (_) => const DeviceQrScanner());
          case forgotPasswordPage:
            return MaterialPageRoute(builder: (_) => const ForgotPassPage());
          case profilePage:
            return MaterialPageRoute(builder: (_) => const ProfilePage());
          case settingsPage:
            return MaterialPageRoute(builder: (_) => const SettingPage());
          case helpPage:
            return MaterialPageRoute(builder: (_) => const HelpPage());
          case customerSupportPage:
            return MaterialPageRoute(builder: (_) => const CustomerSupportMail());
          case aboutPage:
            return MaterialPageRoute(builder: (_) => const AboutPage());
          default:
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                body: Center(
                  child: Text('No route defined for ${settings.name}'),
                ),
              ),
            );
        }
      },
    );
  }
}
