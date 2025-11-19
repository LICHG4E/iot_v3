import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iot_v3/pages/auth_pages/controllers/auth_controller.dart';
import 'package:iot_v3/pages/auth_pages/login_page.dart';
import 'package:iot_v3/pages/auth_pages/verify_email_page.dart';
import 'package:iot_v3/pages/home_page.dart';
import 'package:iot_v3/pages/providers/settings_provider.dart';
import 'package:iot_v3/pages/providers/user_provider.dart';
import 'package:iot_v3/tasks/alert_task.dart';
import 'package:iot_v3/widgets/app_widgets.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const MainPage({super.key, required this.cameras});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String? _activeUserId;
  User? _queuedUser;

  @override
  void initState() {
    WidgetsFlutterBinding.ensureInitialized();
    NotificationTask.initializeService();
    super.initState();
  }

  void loadSettings(String uid) {
    Provider.of<SettingsProvider>(context, listen: false).setUserId(uid);
  }

  void _bootstrapUserSession(User user) {
    if (_activeUserId == user.uid) return;
    _activeUserId = user.uid;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<UserProvider>(context, listen: false).setUser(user);
      loadSettings(user.uid);
      NotificationTask.startService(user.uid);
    });
  }

  void _scheduleUserUpdate(User? user, {bool clearActiveId = false}) {
    if (clearActiveId) {
      _activeUserId = null;
    }
    _queuedUser = user;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_queuedUser == user) {
        Provider.of<UserProvider>(context, listen: false).setUser(user);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthController>(
        builder: (context, authController, _) {
          if (authController.isInitializing) {
            return AppWidgets.loadingIndicator(
              message: 'Preparing your experience...',
              color: Theme.of(context).primaryColor,
            );
          }

          switch (authController.status) {
            case AuthStatus.unauthenticated:
              _scheduleUserUpdate(null, clearActiveId: true);
              return const LoginPage();
            case AuthStatus.awaitingEmailVerification:
              _scheduleUserUpdate(authController.user, clearActiveId: true);
              return const VerifyEmailPage();
            case AuthStatus.authenticated:
              final user = authController.user;
              if (user == null) {
                return AppWidgets.loadingIndicator(message: 'Loading account...');
              }
              _bootstrapUserSession(user);
              return HomePage(userUID: user.uid, cameras: widget.cameras);
            case AuthStatus.initializing:
              return AppWidgets.loadingIndicator(message: 'Starting up...');
          }
        },
      ),
    );
  }
}
