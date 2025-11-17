import 'dart:io';
import 'package:camera/camera.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:iot_v3/constants/routes.dart';
import 'package:iot_v3/widgets/app_widgets.dart';
import 'package:image/image.dart' as img;

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
  bool showGuidelines = true;
  String lightingQuality = 'good'; // 'good', 'dark', 'bright'
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
      final filePath = '$downloadPath/$fileName';

      // Read and decode the image
      final bytes = await image.readAsBytes();
      final decodedImage = img.decodeImage(bytes);

      if (decodedImage != null) {
        // Calculate crop dimensions (90% of the smaller dimension, centered)
        final cropSize = (decodedImage.width < decodedImage.height ? decodedImage.width : decodedImage.height) * 0.9;

        final cropX = ((decodedImage.width - cropSize) / 2).round();
        final cropY = ((decodedImage.height - cropSize) / 2).round();

        // Crop to the guideline box size
        final croppedImage = img.copyCrop(
          decodedImage,
          x: cropX,
          y: cropY,
          width: cropSize.round(),
          height: cropSize.round(),
        );

        // Save the cropped image
        final file = File(filePath);
        await file.writeAsBytes(img.encodePng(croppedImage));
        return file;
      } else {
        // Fallback: save original if decoding fails
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        return file;
      }
    } catch (e) {
      debugPrint("Error saving image: $e");
      throw Exception("Failed to save image");
    }
  }

  Future<bool> validateImageQuality(XFile image) async {
    try {
      final bytes = await image.readAsBytes();
      final decodedImage = img.decodeImage(bytes);

      if (decodedImage == null) return false;

      // Check minimum resolution (should be at least 256x256)
      if (decodedImage.width < 256 || decodedImage.height < 256) {
        if (mounted) {
          AppWidgets.showSnackBar(
            context: context,
            message: 'Image resolution too low. Move closer to the plant.',
            type: SnackBarType.warning,
          );
        }
        return false;
      }

      // Check if image is too dark or too bright
      int totalBrightness = 0;
      int sampleCount = 0;

      // Sample pixels (every 10th pixel for performance)
      for (int y = 0; y < decodedImage.height; y += 10) {
        for (int x = 0; x < decodedImage.width; x += 10) {
          final pixel = decodedImage.getPixel(x, y);
          totalBrightness += ((pixel.r + pixel.g + pixel.b) / 3).round();
          sampleCount++;
        }
      }

      final avgBrightness = totalBrightness / sampleCount;

      // Update lighting quality for UI feedback
      setState(() {
        if (avgBrightness < 50) {
          lightingQuality = 'dark';
        } else if (avgBrightness > 200) {
          lightingQuality = 'bright';
        } else {
          lightingQuality = 'good';
        }
      });

      if (avgBrightness < 40) {
        if (mounted) {
          AppWidgets.showSnackBar(
            context: context,
            message: 'Image too dark. Turn on flash or find better lighting.',
            type: SnackBarType.warning,
          );
        }
        return false;
      }

      if (avgBrightness > 220) {
        if (mounted) {
          AppWidgets.showSnackBar(
            context: context,
            message: 'Image too bright. Avoid direct sunlight.',
            type: SnackBarType.warning,
          );
        }
        return false;
      }

      return true;
    } catch (e) {
      debugPrint("Image quality validation failed: $e");
      return true; // Allow capture if validation fails
    }
  }

  void takePicture() async {
    if (isTakingPicture) return;

    setState(() => isTakingPicture = true);
    _captureAnimationController.forward().then((_) => _captureAnimationController.reverse());

    try {
      final image = await cameraController.takePicture();

      // Validate image quality before saving
      final isQualityGood = await validateImageQuality(image);

      if (!isQualityGood) {
        setState(() => isTakingPicture = false);
        return;
      }

      final file = await saveImage(image);

      setState(() {
        imageFile = image;
        imagePath = file.path;
        isTakingPicture = false;
        showGuidelines = false; // Hide guidelines after first capture
      });

      if (mounted) {
        AppWidgets.showSnackBar(
          context: context,
          message: 'Picture saved! ✓ Good quality detected',
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
          // Guidelines toggle
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: showGuidelines ? Colors.green.withOpacity(0.3) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                showGuidelines ? Icons.grid_on : Icons.grid_off,
                color: showGuidelines ? Colors.green : Colors.white,
              ),
              onPressed: () => setState(() => showGuidelines = !showGuidelines),
              tooltip: showGuidelines ? 'Hide Guidelines' : 'Show Guidelines',
            ),
          ),
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
          ),

          // Camera Guidelines Overlay
          if (showGuidelines)
            Center(
              child: Container(
                width: size.width * 0.9,
                height: size.width * 0.9,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.primaryColor,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    // Corner markers
                    Positioned(
                      top: -3,
                      left: -3,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: theme.primaryColor, width: 5),
                            left: BorderSide(color: theme.primaryColor, width: 5),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -3,
                      right: -3,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: theme.primaryColor, width: 5),
                            right: BorderSide(color: theme.primaryColor, width: 5),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -3,
                      left: -3,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: theme.primaryColor, width: 5),
                            left: BorderSide(color: theme.primaryColor, width: 5),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -3,
                      right: -3,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: theme.primaryColor, width: 5),
                            right: BorderSide(color: theme.primaryColor, width: 5),
                          ),
                        ),
                      ),
                    ),
                    // Center target
                    Center(
                      child: Icon(
                        Icons.center_focus_weak,
                        size: 80,
                        color: theme.primaryColor.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Focus indicator
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
