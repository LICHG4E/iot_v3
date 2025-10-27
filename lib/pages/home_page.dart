import 'dart:math';

import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iot_v3/app_theme/theme_provider.dart';
import 'package:iot_v3/constants/app_constants.dart';
import 'package:iot_v3/pages/providers/user_provider.dart';
import 'package:iot_v3/widgets/app_widgets.dart';
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
    await FirebaseFirestore.instance.collection(AppConstants.usersCollection).doc(widget.userUID).update({
      'devices': FieldValue.arrayRemove([devicesData[index]]),
    });
    await fetchUserData();
    if (mounted) {
      AppWidgets.showSnackBar(
        context: context,
        message: 'Device removed successfully',
        type: SnackBarType.success,
      );
    }
  }

  Future<void> logout() async {
    NotificationTask.stopService();
    await FirebaseAuth.instance.signOut();
  }

  /// Handles scanned device QR code
  Future<void> _handleScannedDevice(String scannedData) async {
    final cleanedData = scannedData.replaceAll('/', '').trim();

    if (isDeviceOwned(cleanedData)) {
      if (!mounted) return;
      AppWidgets.showSnackBar(
        context: context,
        message: 'You already own this device!',
        type: SnackBarType.warning,
      );
      return;
    }

    final deviceExists = await checkDeviceExists(cleanedData);
    if (!mounted) return;

    if (deviceExists) {
      await FirebaseFirestore.instance.collection(AppConstants.usersCollection).doc(widget.userUID).update({
        'devices': FieldValue.arrayUnion([cleanedData]),
      });
      await updateUserData(cleanedData);
      await fetchUserData();
      AppWidgets.showSnackBar(
        context: context,
        message: 'Device added successfully!',
        type: SnackBarType.success,
      );
    } else {
      AppWidgets.showSnackBar(
        context: context,
        message: 'Device not found. Please try again.',
        type: SnackBarType.error,
      );
    }
  }

  /// Builds a device card widget
  Widget _buildDeviceCard(int index) {
    return Hero(
      tag: 'device_${devicesData[index]}',
      child: Card(
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              deviceDataPage,
              arguments: devicesData[index],
            );
          },
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          child: Stack(
            children: [
              // Delete button
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: Colors.red.shade400,
                  onPressed: () async {
                    final confirmed = await AppWidgets.showConfirmationDialog(
                      context: context,
                      title: 'Delete Device',
                      message: 'Are you sure you want to remove this device?',
                      confirmText: 'Delete',
                      isDangerous: true,
                    );
                    if (confirmed) {
                      await deleteDevice(index);
                    }
                  },
                ),
              ),
              // Device content
              Padding(
                padding: const EdgeInsets.all(6.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.devices_other,
                        size: 26,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Device ${index + 1}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Flexible(
                      child: Text(
                        devicesData[index],
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                              fontSize: 10,
                            ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 6,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the add device card
  Widget _buildAddDeviceCard() {
    return Card(
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: InkWell(
        onTap: () async {
          final scannedData = await Navigator.pushNamed(context, deviceQRScanner);
          if (scannedData != null) {
            await _handleScannedDevice(scannedData as String);
          }
        },
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Add Device',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Scan QR Code',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                        Text("PlantCare", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).primaryColor)),
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
                        final confirmLogout = await AppWidgets.showConfirmationDialog(
                          context: context,
                          title: 'Confirm Logout',
                          message: 'Are you sure you want to log out?',
                          confirmText: 'Logout',
                          isDangerous: true,
                        );

                        if (confirmLogout) {
                          await logout();
                          if (mounted) {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              loginPage,
                              (route) => false,
                            );
                          }
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
          ? Center(
              child: SizedBox(
                height: 300,
                child: Consumer<ThemeProvider>(
                  builder: (context, themeProvider, _) {
                    return RiveAnimation.asset(
                      themeProvider.isLight ? AppConstants.plantLogoLightPath : AppConstants.plantLogoDarkPath,
                      fit: BoxFit.contain,
                    );
                  },
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: fetchUserData,
              child: devicesData.isEmpty
                  ? AppWidgets.emptyState(
                      message: 'No devices found.\nAdd your first IoT device to get started!',
                      icon: Icons.devices_other,
                      actionLabel: 'Add Device',
                      onAction: () async {
                        final scannedData = await Navigator.pushNamed(context, deviceQRScanner);
                        if (scannedData != null) {
                          await _handleScannedDevice(scannedData as String);
                        }
                      },
                    )
                  : Container(
                      padding: const EdgeInsets.all(AppConstants.defaultPadding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Your Devices",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${devicesData.length} ${devicesData.length == 1 ? 'device' : 'devices'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16.0),
                          Expanded(
                            child: GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16.0,
                                mainAxisSpacing: 16.0,
                                childAspectRatio: 1.0,
                              ),
                              itemCount: devicesData.length + 1,
                              itemBuilder: (context, index) {
                                if (index < devicesData.length) {
                                  return _buildDeviceCard(index);
                                } else {
                                  return _buildAddDeviceCard();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
    );
  }
}
