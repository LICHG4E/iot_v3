import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iot_v3/pages/home_page.dart';
import 'package:iot_v3/pages/auth_pages/login_page.dart';
import 'package:provider/provider.dart';
import 'package:iot_v3/pages/drawer_pages/user_provider.dart';

class MainPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  const MainPage({super.key, required this.cameras});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Only update UserProvider after the current build phase
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (snapshot.connectionState == ConnectionState.active) {
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              if (snapshot.hasData) {
                userProvider.setUser(snapshot.data); // Update provider
              } else {
                userProvider.setUser(null); // Clear provider if no user
              }
            }
          });

          // Show login or home page based on the snapshot
          if (snapshot.data == null) {
            return const LoginPage();
          } else {
            snapshot.data!.reload(); // Reload user data from Firebase
            return HomePage(userUID: snapshot.data!.uid, cameras: widget.cameras);
          }
        },
      ),
    );
  }
}
