import 'dart:io';
import 'package:camera/camera.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:iot_v3/constants/routes.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController cameraController;
  late Future<void> cameraValue;
  XFile? imageFile;
  String? imagePath = '';
  bool isTakingPicture = false;
  Offset? focusPoint;
  bool isFlashOn = false;
  double aspectRatio = 3 / 4; // Default aspect ratio

  void cameraStart() {
    cameraController = CameraController(
      widget.cameras[0],
      _getResolutionPresetForAspectRatio(aspectRatio),
      enableAudio: false,
    );
    cameraValue = cameraController.initialize().catchError((error) {
      print("Camera initialization failed: $error");
    });
  }

  @override
  void initState() {
    cameraStart();
    super.initState();
  }

  ResolutionPreset _getResolutionPresetForAspectRatio(double ratio) {
    if (ratio == 3 / 4) return ResolutionPreset.high;
    if (ratio == 9 / 16) return ResolutionPreset.veryHigh;
    if (ratio == 1) return ResolutionPreset.medium;
    return ResolutionPreset.high; // Default
  }

  Future<File> saveImage(XFile image) async {
    try {
      final downloadPath = await ExternalPath.getExternalStoragePublicDirectory(
        ExternalPath.DIRECTORY_DCIM,
      );
      final fileName = 'Iot_image_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('$downloadPath/$fileName');
      await file.writeAsBytes(await image.readAsBytes());
      return file;
    } catch (e) {
      print("Error saving image: $e");
      throw Exception("Failed to save image");
    }
  }

  void takePicture() async {
    if (isTakingPicture) return;
    setState(() {
      isTakingPicture = true;
    });

    try {
      final image = await cameraController.takePicture();
      final file = await saveImage(image);

      setState(() {
        imageFile = image;
        imagePath = file.path;
        isTakingPicture = false;
      });

      print('Image saved at ${file.path}');
      _showCaptureFeedback();
    } catch (e) {
      setState(() {
        isTakingPicture = false;
      });
      print(e);
    }
  }

  void _showCaptureFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Picture Taken!")),
    );
  }

  void focusAt(Offset offset) async {
    if (cameraController.value.isInitialized) {
      final x = offset.dx / MediaQuery.of(context).size.width;
      final y = offset.dy / MediaQuery.of(context).size.height;
      setState(() {
        focusPoint = offset;
      });
      await cameraController.setFocusPoint(Offset(x, y));
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          focusPoint = null;
        });
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
    } catch (e) {
      print("Error toggling flash: $e");
    }
  }

  void changeAspectRatio(double ratio) {
    setState(() {
      aspectRatio = ratio;
      cameraController.dispose();
      cameraStart();
    });
  }

  void openPreview() {
    if (imagePath == null) return;
    print("this is the path: $imagePath");
    Navigator.pushNamed(context, scanScreen, arguments: imagePath);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Camera',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            onPressed: toggleFlash,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButton<double>(
              value: [3 / 4, 9 / 16, 1].contains(aspectRatio) ? aspectRatio : null,
              dropdownColor: Colors.black,
              style: const TextStyle(color: Colors.white),
              underline: Container(
                height: 2,
                color: Colors.white,
              ),
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
              items: const [
                DropdownMenuItem(value: 3 / 4, child: Text('4:3')),
                DropdownMenuItem(value: 9 / 16, child: Text('16:9')),
                DropdownMenuItem(value: 1, child: Text('1:1')),
              ],
              onChanged: (ratio) {
                if (ratio != null) {
                  changeAspectRatio(ratio);
                }
              },
            ),
          ),
        ],
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          GestureDetector(
            onTapUp: (details) {
              focusAt(details.localPosition);
            },
            child: FutureBuilder<void>(
              future: cameraValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Center(
                    child: AspectRatio(
                      aspectRatio: aspectRatio,
                      child: CameraPreview(cameraController),
                    ),
                  );
                } else {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            ),
          ),

          Positioned(
            bottom: 50,
            left: size.width / 2 - 35,
            child: IconButton(
              onPressed: takePicture,
              icon: const Icon(Icons.camera_alt, size: 60, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.7),
                shape: const CircleBorder(),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: size.width / 8,
            child: IconButton(
              onPressed: openPreview,
              icon: imageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.file(
                        File(imageFile!.path),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(Icons.photo, size: 60, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.7),
                shape: const CircleBorder(),
              ),
            ),
          ),
          if (focusPoint != null)
            Positioned(
              left: focusPoint!.dx - 20,
              top: focusPoint!.dy - 20,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.yellow, width: 3),
                ),
              ),
            ),
          // Loading screen when taking a picture
          if (isTakingPicture)
            Center(
              child: Container(
                width: size.width,
                height: size.height,
                color: Colors.black.withOpacity(0.5),
                alignment: Alignment.center,
                child: const CircularProgressIndicator.adaptive(),
              ),
            ),
        ],
      ),
    );
  }
}
