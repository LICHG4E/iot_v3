import 'dart:math';

import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iot_v3/pages/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart';
import '../constants/routes.dart';
import '../tasks/alert_task.dart';

class HomePage extends StatefulWidget {
  final String userUID;
  final List<CameraDescription> cameras;

  const HomePage({super.key, required this.userUID, required this.cameras});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? userData;
  List<dynamic> devicesData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;
      user?.reload();
      if (user?.emailVerified == false) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Email not verified'),
              content: const Text('Please verify your email through the link we sent you.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'OK',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                ),
              ],
            );
          },
        );
      }
    });

    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userUID).get();

      if (doc.exists) {
        setState(() {
          userData = doc.data();
          devicesData = userData?['devices'] ?? {};
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not found')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  bool isDeviceOwned(String deviceId) {
    return devicesData.contains(deviceId);
  }

  Future<bool> checkDeviceExists(String deviceId) async {
    try {
      final parentDoc = await FirebaseFirestore.instance.doc('beaglebones/$deviceId').get();
      if (parentDoc.exists) {
        return true;
      }
      final subcollectionSnapshot = await FirebaseFirestore.instance.collection('beaglebones/$deviceId/data').limit(1).get();
      final subcollectionExists = subcollectionSnapshot.docs.isNotEmpty;
      return subcollectionExists;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateUserData(String deviceId) async {
    await FirebaseFirestore.instance.collection('users').doc(widget.userUID).update({
      'devices': FieldValue.arrayUnion([deviceId]),
    });
  }

  Future<void> deleteDevice(int index) async {
    bool confirmDelete = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm Delete'),
              content: const Text('Are you sure you want to delete this device?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false); // Dismiss the dialog and return false
                  },
                  child: Text(
                    'Cancel',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true); // Dismiss the dialog and return true
                  },
                  child: Text(
                    'Delete',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false; // Default to false if the dialog is dismissed without any action

    if (confirmDelete) {
      await FirebaseFirestore.instance.collection('users').doc(widget.userUID).update({
        'devices': FieldValue.arrayRemove([devicesData[index]]),
      });
      fetchUserData();
    }
  }

  Future<void> logout() async {
    NotificationTask.stopService();
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final bool isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    final int divisor = isPortrait ? 250 : 200;
    final currentCount = (MediaQuery.of(context).size.width ~/ divisor).toInt();
    const minCount = 2;
    final crossAxisCount = max(currentCount, minCount);
    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FloatingActionButton.extended(
          label: const Text('Scan plants'),
          onPressed: () => Navigator.pushNamed(context, cameraScreen, arguments: widget.cameras),
          icon: const Icon(Icons.camera_alt),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      appBar: AppBar(
        title: const Text('Home Page'),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        centerTitle: true,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100.0),
                  color: Colors.white,
                ),
                child: Stack(
                  children: [
                    const SizedBox(
                      height: 300,
                      child: RiveAnimation.asset(
                        'assets/animations/plants.riv',
                        fit: BoxFit.contain,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("PlantCare",
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).primaryColor)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ListTile(
                      title: const Text('Profile'),
                      leading: const Icon(Icons.person),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          profilePage,
                          arguments: widget.userUID,
                        );
                      },
                    ),
                    const SizedBox(height: 8.0),
                    ListTile(
                      title: const Text('Settings'),
                      leading: const Icon(Icons.settings),
                      onTap: () {
                        Navigator.pushNamed(context, settingsPage);
                      },
                    ),
                    const SizedBox(height: 8.0),
                    ListTile(
                      title: const Text('Help & Support'),
                      leading: const Icon(Icons.help),
                      onTap: () {
                        Navigator.pushNamed(context, helpPage);
                      },
                    ),
                    const SizedBox(height: 8.0),
                    ListTile(
                      title: const Text('About'),
                      leading: const Icon(Icons.info),
                      onTap: () {
                        Navigator.pushNamed(context, aboutPage);
                      },
                    ),
                    const SizedBox(height: 8.0),
                    ListTile(
                      title: const Text('Logout'),
                      leading: const Icon(Icons.logout),
                      onTap: () async {
                        // Show the confirmation dialog
                        bool confirmLogout = await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Confirm Logout'),
                                  content: const Text('Are you sure you want to log out?'),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(false); // Dismiss the dialog and return false
                                      },
                                      child: Text(
                                        'Cancel',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              color: Theme.of(context).primaryColor,
                                            ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(true); // Dismiss the dialog and return true
                                      },
                                      child: Text(
                                        'Logout',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              color: Theme.of(context).primaryColor,
                                            ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ) ??
                            false; // Default to false if the dialog is dismissed without any action

                        // Proceed with logout if confirmed
                        if (confirmLogout) {
                          await logout();
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            loginPage,
                            (route) => false,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.end,
            //   children: [
            //     Consumer<ThemeProvider>(
            //       builder: (context, provider, child) {
            //         return Row(
            //           children: [
            //             const SizedBox(width: 16),
            //             Switch(
            //               value: provider.isLight,
            //               onChanged: (value) {
            //                 setState(() {
            //                   Provider.of<ThemeProvider>(context, listen: false).toggleTheme(value);
            //                 });
            //               },
            //               thumbIcon: WidgetStatePropertyAll(
            //                   provider.isLight ? const Icon(Icons.light_mode) : const Icon(Icons.dark_mode)),
            //               activeColor: Theme.of(context).primaryColor,
            //             ),
            //           ],
            //         );
            //       },
            //     ),
            //     const SizedBox(width: 16),
            //   ],
            // ),
            const SizedBox(height: 40.0),
          ],
        ),
      ),
      body: isLoading
          ? const Center(
              child: SizedBox(
                height: 300,
                child: RiveAnimation.asset(
                  'assets/animations/plant_logo_loading_in_lightmode.riv',
                  fit: BoxFit.contain,
                ),
              ),
            )
          : Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Your devices ",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16.0),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16.0,
                        mainAxisSpacing: 16.0,
                      ),
                      itemCount: devicesData.length + 1,
                      itemBuilder: (context, index) {
                        if (index < devicesData.length) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                deviceDataPage,
                                arguments: devicesData[index],
                              );
                            },
                            child: Card(
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () {
                                        deleteDevice(index);
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Device ${index + 1}',
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(height: 8.0),
                                          Text(
                                            devicesData[index],
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          const SizedBox(height: 8.0),
                                          Text(
                                            'Details...',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          // Replace with actual device details if needed
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else {
                          // The + button card
                          return GestureDetector(
                            onTap: () async {
                              // Perform navigation and check after the QR scan
                              Object? scannedData = await Navigator.pushNamed(context, deviceQRScanner);
                              if (scannedData != null) {
                                scannedData = scannedData as String;
                                scannedData = scannedData.replaceAll('/', '').trim();

                                bool deviceOwned = isDeviceOwned(scannedData);

                                if (deviceOwned) {
                                  showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: const Text('Device already added'),
                                          content: const Text('You already own this device!'),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: Text(
                                                'OK',
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                      color: Theme.of(context).primaryColor,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        );
                                      });
                                }

                                bool deviceExists = await checkDeviceExists(scannedData);

                                if (deviceExists) {
                                  // If the device exists, update Firestore
                                  await FirebaseFirestore.instance.collection('users').doc(widget.userUID).update({
                                    'devices': FieldValue.arrayUnion([scannedData]),
                                  });
                                  await updateUserData(scannedData);
                                  fetchUserData();
                                } else {
                                  showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: const Text('Device not found'),
                                          content: const Text('The device you scanned does not exist. Please try again.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: Text(
                                                'OK',
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                      color: Theme.of(context).primaryColor,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        );
                                      });
                                }
                              }
                            },
                            child: Card(
                              color: Theme.of(context).primaryColor,
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add,
                                      size: 40.0,
                                      color: Colors.white,
                                    ),
                                    SizedBox(height: 8.0),
                                    Text(
                                      'Add Device',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
