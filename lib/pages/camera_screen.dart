import 'dart:io';
import 'package:camera/camera.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:iot_v3/constants/routes.dart';
import 'package:iot_v3/widgets/app_widgets.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with TickerProviderStateMixin {
  late CameraController cameraController;
  late Future<void> cameraValue;
  XFile? imageFile;
  String? imagePath = '';
  bool isTakingPicture = false;
  Offset? focusPoint;
  bool isFlashOn = false;
  late AnimationController _captureAnimationController;
  late AnimationController _focusAnimationController;
  late Animation<double> _captureAnimation;
  late Animation<double> _focusAnimation;

  @override
  void initState() {
    super.initState();
    cameraStart();

    // Capture animation
    _captureAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _captureAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(
        parent: _captureAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Focus animation
    _focusAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _focusAnimation = Tween<double>(begin: 1.0, end: 0.7).animate(
      CurvedAnimation(
        parent: _focusAnimationController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _captureAnimationController.dispose();
    _focusAnimationController.dispose();
    cameraController.dispose();
    super.dispose();
  }

  void cameraStart() {
    cameraController = CameraController(
      widget.cameras[0],
      ResolutionPreset.veryHigh, // Always use highest quality
      enableAudio: false,
    );
    cameraValue = cameraController.initialize().catchError((error) {
      debugPrint("Camera initialization failed: $error");
    });
  }

  Future<File> saveImage(XFile image) async {
    try {
      final downloadPath = await ExternalPath.getExternalStoragePublicDirectory(
        ExternalPath.DIRECTORY_DCIM,
      );
      final fileName = 'PlantCare_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('$downloadPath/$fileName');
      await file.writeAsBytes(await image.readAsBytes());
      return file;
    } catch (e) {
      debugPrint("Error saving image: $e");
      throw Exception("Failed to save image");
    }
  }

  void takePicture() async {
    if (isTakingPicture) return;

    setState(() => isTakingPicture = true);
    _captureAnimationController.forward().then((_) => _captureAnimationController.reverse());

    try {
      final image = await cameraController.takePicture();
      final file = await saveImage(image);

      setState(() {
        imageFile = image;
        imagePath = file.path;
        isTakingPicture = false;
      });

      if (mounted) {
        AppWidgets.showSnackBar(
          context: context,
          message: 'Picture saved!',
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      setState(() => isTakingPicture = false);
      if (mounted) {
        AppWidgets.showSnackBar(
          context: context,
          message: 'Failed to capture image',
          type: SnackBarType.error,
        );
      }
    }
  }

  void focusAt(Offset offset) async {
    if (cameraController.value.isInitialized) {
      final x = offset.dx / MediaQuery.of(context).size.width;
      final y = offset.dy / MediaQuery.of(context).size.height;

      setState(() => focusPoint = offset);
      _focusAnimationController.forward().then((_) => _focusAnimationController.reverse());

      await cameraController.setFocusPoint(Offset(x, y));

      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          setState(() => focusPoint = null);
        }
      });
    }
  }

  void toggleFlash() async {
    if (!cameraController.value.isInitialized) return;
    try {
      isFlashOn = !isFlashOn;
      await cameraController.setFlashMode(
        isFlashOn ? FlashMode.torch : FlashMode.off,
      );
      setState(() {});
      if (mounted) {
        AppWidgets.showSnackBar(
          context: context,
          message: isFlashOn ? 'Flash on' : 'Flash off',
          type: SnackBarType.info,
          duration: const Duration(seconds: 1),
        );
      }
    } catch (e) {
      debugPrint("Error toggling flash: $e");
    }
  }

  void openPreview() {
    if (imagePath == null || imagePath!.isEmpty) {
      AppWidgets.showSnackBar(
        context: context,
        message: 'No image captured yet',
        type: SnackBarType.warning,
      );
      return;
    }
    Navigator.pushNamed(context, scanScreen, arguments: imagePath);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.3),
        elevation: 0,
        title: const Text(
          'Plant Scanner',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Flash toggle
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isFlashOn ? Colors.amber.withOpacity(0.3) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                isFlashOn ? Icons.flash_on : Icons.flash_off,
                color: isFlashOn ? Colors.amber : Colors.white,
              ),
              onPressed: toggleFlash,
              tooltip: isFlashOn ? 'Flash On' : 'Flash Off',
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          GestureDetector(
            onTapUp: (details) => focusAt(details.localPosition),
            child: FutureBuilder<void>(
              future: cameraValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Center(
                    child: CameraPreview(cameraController),
                  );
                } else {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Initializing camera...',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ), // Focus indicator
          if (focusPoint != null)
            AnimatedBuilder(
              animation: _focusAnimation,
              builder: (context, child) {
                return Positioned(
                  left: focusPoint!.dx - 40,
                  top: focusPoint!.dy - 40,
                  child: Transform.scale(
                    scale: _focusAnimation.value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.primaryColor,
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        Icons.center_focus_strong,
                        color: theme.primaryColor,
                        size: 40,
                      ),
                    ),
                  ),
                );
              },
            ),

          // Loading overlay
          if (isTakingPicture)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      'Capturing...',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Gallery/Preview button
                  _buildControlButton(
                    onPressed: openPreview,
                    child: imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(imageFile!.path),
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.photo_library,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                  ),

                  // Capture button
                  AnimatedBuilder(
                    animation: _captureAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _captureAnimation.value,
                        child: GestureDetector(
                          onTap: takePicture,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 4,
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: theme.primaryColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.primaryColor.withOpacity(0.5),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Spacer for symmetry
                  const SizedBox(width: 56),
                ],
              ),
            ),
          ),

          // Instructions overlay
          if (!isTakingPicture && imageFile == null)
            Positioned(
              top: size.height * 0.15,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.eco,
                      color: theme.primaryColor,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap anywhere to focus',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Capture plant leaves for disease detection',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required VoidCallback onPressed,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: child,
    );
  }
}
