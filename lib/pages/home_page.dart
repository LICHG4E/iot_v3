import 'dart:math';

import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iot_v3/app_theme/theme_provider.dart';
import 'package:iot_v3/constants/app_constants.dart';
import 'package:iot_v3/models/greenhouse.dart';
import 'package:iot_v3/pages/providers/user_provider.dart';
import 'package:iot_v3/widgets/app_widgets.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart';
import 'package:uuid/uuid.dart';
import '../constants/routes.dart';
import '../tasks/alert_task.dart';

enum _DeviceMenuAction { view, reassign, remove }

class HomePage extends StatefulWidget {
  final String userUID;
  final List<CameraDescription> cameras;

  const HomePage({super.key, required this.userUID, required this.cameras});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? userData;
  List<String> devicesData = [];
  List<Greenhouse> _greenhouses = [];
  bool isLoading = true;
  final Uuid _uuid = const Uuid();
  static const String _createGreenhouseOption = '__create_greenhouse__';

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
        final data = doc.data();
        final rawGreenhouses = (data?['greenhouses'] as List<dynamic>? ?? <dynamic>[]);
        setState(() {
          userData = data;
          devicesData = List<String>.from(data?['devices'] ?? <String>[]);
          _greenhouses = rawGreenhouses.map((entry) => entry is Map<String, dynamic> ? Greenhouse.fromMap(entry) : null).whereType<Greenhouse>().toList();
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

  List<String> get _unassignedDevices {
    final assignedIds = _greenhouses.expand((g) => g.devices).toSet();
    return devicesData.where((deviceId) => !assignedIds.contains(deviceId)).toList();
  }

  String _greenhouseLabel(String rawName) {
    final trimmed = rawName.trim();
    return trimmed.isEmpty ? 'Unnamed greenhouse' : trimmed;
  }

  Greenhouse? _findGreenhouseByDevice(String deviceId) {
    for (final greenhouse in _greenhouses) {
      if (greenhouse.devices.contains(deviceId)) {
        return greenhouse;
      }
    }
    return null;
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
    await FirebaseFirestore.instance.collection(AppConstants.usersCollection).doc(widget.userUID).update({
      'devices': FieldValue.arrayUnion([deviceId]),
    });
  }

  Future<void> deleteDevice(String deviceId) async {
    try {
      final updatedGreenhouses = _greenhouses.map((g) => g.copyWith(devices: List<String>.from(g.devices)..remove(deviceId))).toList();

      await FirebaseFirestore.instance.collection(AppConstants.usersCollection).doc(widget.userUID).update({
        'devices': FieldValue.arrayRemove([deviceId]),
        'greenhouses': updatedGreenhouses.map((g) => g.toMap()).toList(),
      });

      await fetchUserData();
      if (mounted) {
        AppWidgets.showSnackBar(
          context: context,
          message: 'Device removed successfully',
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppWidgets.showSnackBar(
          context: context,
          message: 'Failed to remove device: $e',
          type: SnackBarType.error,
        );
      }
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
      await updateUserData(cleanedData);
      await fetchUserData();
      if (!mounted) return;
      AppWidgets.showSnackBar(
        context: context,
        message: 'Device added successfully. Choose a greenhouse to finish setup.',
        type: SnackBarType.success,
      );
      await _promptGreenhouseAssignment(cleanedData);
    } else {
      AppWidgets.showSnackBar(
        context: context,
        message: 'Device not found. Please try again.',
        type: SnackBarType.error,
      );
    }
  }

  /// Builds a device card widget
  Widget _buildDeviceCard({
    required String deviceId,
    required int deviceNumber,
    required String locationLabel,
  }) {
    return Hero(
      tag: 'device_$deviceId',
      child: Card(
        child: InkWell(
          onTap: () => _openDevice(deviceId),
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: PopupMenuButton<_DeviceMenuAction>(
                  onSelected: (action) async {
                    switch (action) {
                      case _DeviceMenuAction.view:
                        _openDevice(deviceId);
                        break;
                      case _DeviceMenuAction.reassign:
                        await _promptGreenhouseAssignment(deviceId);
                        break;
                      case _DeviceMenuAction.remove:
                        await _confirmDeleteDevice(deviceId);
                        break;
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _DeviceMenuAction.view,
                      child: Text('View data'),
                    ),
                    PopupMenuItem(
                      value: _DeviceMenuAction.reassign,
                      child: Text('Reassign greenhouse'),
                    ),
                    PopupMenuItem(
                      value: _DeviceMenuAction.remove,
                      child: Text('Remove device'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
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
                    const SizedBox(height: 8),
                    Text(
                      'Device $deviceNumber',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      deviceId,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_florist,
                            size: 12,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            locationLabel,
                            style: TextStyle(
                              fontSize: 10,
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

  void _openDevice(String deviceId) {
    Navigator.pushNamed(
      context,
      deviceDataPage,
      arguments: deviceId,
    );
  }

  Future<void> _confirmDeleteDevice(String deviceId) async {
    final confirmed = await AppWidgets.showConfirmationDialog(
      context: context,
      title: 'Remove Device',
      message: 'Are you sure you want to remove this device from your account?',
      confirmText: 'Remove',
      isDangerous: true,
    );
    if (confirmed) {
      await deleteDevice(deviceId);
    }
  }

  Future<void> _promptGreenhouseAssignment(String deviceId) async {
    if (!mounted) return;

    if (_greenhouses.isEmpty) {
      final newId = await _showCreateGreenhouseDialog(shouldReturnId: true);
      if (newId != null) {
        await _assignDeviceToGreenhouse(deviceId, newId);
      }
      return;
    }

    final currentLocation = _findGreenhouseByDevice(deviceId);
    final selection = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(
                'Select greenhouse',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ..._greenhouses.map(
                (greenhouse) => ListTile(
                  title: Text(_greenhouseLabel(greenhouse.name)),
                  trailing: greenhouse.id == currentLocation?.id ? const Icon(Icons.check) : null,
                  onTap: () => Navigator.pop(sheetContext, greenhouse.id),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Create new greenhouse'),
                onTap: () => Navigator.pop(sheetContext, _createGreenhouseOption),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (selection == null) {
      return;
    }

    if (selection == _createGreenhouseOption) {
      final newId = await _showCreateGreenhouseDialog(shouldReturnId: true);
      if (newId != null) {
        await _assignDeviceToGreenhouse(deviceId, newId);
      }
    } else {
      await _assignDeviceToGreenhouse(deviceId, selection);
    }
  }

  Future<String?> _showCreateGreenhouseDialog({bool shouldReturnId = false}) async {
    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('New greenhouse'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Greenhouse name',
              hintText: 'e.g. South greenhouse',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) {
                  AppWidgets.showSnackBar(
                    context: context,
                    message: 'Please enter a greenhouse name',
                    type: SnackBarType.warning,
                  );
                  return;
                }
                final newId = await _createGreenhouse(name);
                Navigator.pop(dialogContext, shouldReturnId ? newId : null);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
    return result;
  }

  Future<String?> _createGreenhouse(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      if (mounted) {
        AppWidgets.showSnackBar(
          context: context,
          message: 'Greenhouse name cannot be empty',
          type: SnackBarType.error,
        );
      }
      return null;
    }

    final newGreenhouse = Greenhouse(
      id: _uuid.v4(),
      name: trimmed,
      devices: const [],
      createdAt: Timestamp.now(),
    );

    try {
      await FirebaseFirestore.instance.collection(AppConstants.usersCollection).doc(widget.userUID).update({
        'greenhouses': [..._greenhouses, newGreenhouse].map((g) => g.toMap()).toList(),
      });
      await fetchUserData();
      if (mounted) {
        AppWidgets.showSnackBar(
          context: context,
          message: 'Greenhouse created',
          type: SnackBarType.success,
        );
      }
      return newGreenhouse.id;
    } catch (e) {
      if (mounted) {
        AppWidgets.showSnackBar(
          context: context,
          message: 'Failed to create greenhouse: $e',
          type: SnackBarType.error,
        );
      }
      return null;
    }
  }

  Future<void> _showRenameGreenhouseDialog(Greenhouse greenhouse) async {
    final controller = TextEditingController(text: greenhouse.name);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Rename greenhouse'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Greenhouse name',
              hintText: 'e.g. East tunnel',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final trimmed = controller.text.trim();
                if (trimmed.isEmpty) {
                  AppWidgets.showSnackBar(
                    context: context,
                    message: 'Please enter a greenhouse name',
                    type: SnackBarType.warning,
                  );
                  return;
                }
                if (trimmed == greenhouse.name.trim()) {
                  Navigator.pop(dialogContext);
                  return;
                }
                await _renameGreenhouse(greenhouse, trimmed);
                if (mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
  }

  Future<void> _renameGreenhouse(Greenhouse greenhouse, String newName) async {
    final updated = _greenhouses.map((g) {
      if (g.id == greenhouse.id) {
        return g.copyWith(name: newName);
      }
      return g;
    }).toList();

    try {
      await FirebaseFirestore.instance.collection(AppConstants.usersCollection).doc(widget.userUID).update({
        'greenhouses': updated.map((g) => g.toMap()).toList(),
      });
      await fetchUserData();
      if (mounted) {
        AppWidgets.showSnackBar(
          context: context,
          message: 'Greenhouse renamed',
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppWidgets.showSnackBar(
          context: context,
          message: 'Failed to rename greenhouse: $e',
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _confirmDeleteGreenhouse(Greenhouse greenhouse) async {
    final confirmed = await AppWidgets.showConfirmationDialog(
      context: context,
      title: 'Delete Greenhouse',
      message: 'Are you sure you want to delete this greenhouse? All devices will be moved to unassigned.',
      confirmText: 'Delete',
      isDangerous: true,
    );
    if (confirmed) {
      await _deleteGreenhouse(greenhouse);
    }
  }

  Future<void> _deleteGreenhouse(Greenhouse greenhouse) async {
    try {
      final updatedGreenhouses = _greenhouses.where((g) => g.id != greenhouse.id).toList();

      await FirebaseFirestore.instance.collection(AppConstants.usersCollection).doc(widget.userUID).update({
        'greenhouses': updatedGreenhouses.map((g) => g.toMap()).toList(),
      });
      await fetchUserData();
      if (mounted) {
        AppWidgets.showSnackBar(
          context: context,
          message: 'Greenhouse deleted',
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppWidgets.showSnackBar(
          context: context,
          message: 'Failed to delete greenhouse: $e',
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _assignDeviceToGreenhouse(String deviceId, String greenhouseId) async {
    try {
      final updated = _greenhouses.map((g) {
        final updatedDevices = List<String>.from(g.devices)..remove(deviceId);
        if (g.id == greenhouseId && !updatedDevices.contains(deviceId)) {
          updatedDevices.add(deviceId);
        }
        return g.copyWith(devices: updatedDevices);
      }).toList();

      if (!updated.any((g) => g.id == greenhouseId)) {
        AppWidgets.showSnackBar(
          context: context,
          message: 'Selected greenhouse not found',
          type: SnackBarType.error,
        );
        return;
      }

      await FirebaseFirestore.instance.collection(AppConstants.usersCollection).doc(widget.userUID).update({
        'greenhouses': updated.map((g) => g.toMap()).toList(),
      });
      await fetchUserData();
      if (mounted) {
        AppWidgets.showSnackBar(
          context: context,
          message: 'Device assignment updated',
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppWidgets.showSnackBar(
          context: context,
          message: 'Failed to assign device: $e',
          type: SnackBarType.error,
        );
      }
    }
  }

  Widget _buildGreenhouseSection(Greenhouse greenhouse, int crossAxisCount) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _greenhouseLabel(greenhouse.name),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${greenhouse.devices.length} ${greenhouse.devices.length == 1 ? 'device' : 'devices'}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    IconButton(
                      tooltip: 'Rename greenhouse',
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _showRenameGreenhouseDialog(greenhouse),
                    ),
                    IconButton(
                      tooltip: 'Delete greenhouse',
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () => _confirmDeleteGreenhouse(greenhouse),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            greenhouse.devices.isEmpty
                ? Text(
                    'No devices assigned yet. Use the menu on a device to move it here.',
                    style: TextStyle(color: Colors.grey.shade600),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: greenhouse.devices.length,
                    itemBuilder: (context, index) {
                      final deviceId = greenhouse.devices[index];
                      return _buildDeviceCard(
                        deviceId: deviceId,
                        deviceNumber: index + 1,
                        locationLabel: _greenhouseLabel(greenhouse.name),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnassignedSection(List<String> devices, int crossAxisCount) {
    if (devices.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Unassigned devices',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  devices.length == 1 ? '1 device' : '${devices.length} devices',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 1.0,
              ),
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final deviceId = devices[index];
                return _buildDeviceCard(
                  deviceId: deviceId,
                  deviceNumber: index + 1,
                  locationLabel: 'Unassigned',
                );
              },
            ),
          ],
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
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Your Devices',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${devicesData.length} ${devicesData.length == 1 ? 'device' : 'devices'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            '${_greenhouses.length} ${_greenhouses.length == 1 ? 'greenhouse' : 'greenhouses'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () => _showCreateGreenhouseDialog(),
                      icon: const Icon(Icons.house_outlined),
                      label: const Text('Add greenhouse'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_greenhouses.isEmpty && _unassignedDevices.isEmpty && devicesData.isEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: AppWidgets.emptyState(
                        message: 'No devices yet. Add a device and group it by greenhouse to get started.',
                        icon: Icons.devices_other,
                        actionLabel: 'Add Device',
                        onAction: () async {
                          final scannedData = await Navigator.pushNamed(context, deviceQRScanner);
                          if (scannedData != null) {
                            await _handleScannedDevice(scannedData as String);
                          }
                        },
                      ),
                    ),
                  ] else ...[
                    _buildUnassignedSection(_unassignedDevices, crossAxisCount),
                    ..._greenhouses.map((greenhouse) => _buildGreenhouseSection(greenhouse, crossAxisCount)).toList(),
                  ],
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 180,
                    child: _buildAddDeviceCard(),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
