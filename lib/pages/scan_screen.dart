import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iot_v3/widgets/app_widgets.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class ScanScreen extends StatefulWidget {
  final String imagePath;

  const ScanScreen({super.key, required this.imagePath});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  String _predictedLabel = "";
  double _confidence = 0.0;
  bool _isProcessing = false;
  bool _hasScanned = false;
  Interpreter? _interpreter;
  late List<String> _labels;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _modelLoaded = false;
  Map<String, List<String>> _adviceData = {};
  List<String> _currentAdvice = [];

  @override
  void initState() {
    super.initState();
    print('[ScanScreen] 🚀 INITIALIZING ScanScreen');
    print('[ScanScreen] 📸 Image path: ${widget.imagePath}');
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
    print('[ScanScreen] 🎬 Animation controller initialized');
    loadModel();
  }

  @override
  void dispose() {
    print('[ScanScreen] 🗑️ DISPOSING ScanScreen');
    print('[ScanScreen] 📊 Final state: _modelLoaded=$_modelLoaded, _isProcessing=$_isProcessing, _hasScanned=$_hasScanned');
    _animationController.dispose();
    _interpreter?.close();
    super.dispose();
  }

  // Load the TFLite model
  Future<void> loadModel() async {
    print('[ScanScreen] 🔄 STARTING TFLITE MODEL LOADING PROCESS');
    print('[ScanScreen] 📊 Current state: _modelLoaded=$_modelLoaded');
    print('[ScanScreen] 🕐 Timestamp: ${DateTime.now()}');

    const expectedClasses = 38;
    print('[ScanScreen] 🎯 Expected classes: $expectedClasses');

    try {
      print('[ScanScreen] 📁 STEP 1: Loading TFLite model...');
      const modelPath = 'assets/models/plant_disease_model.tflite';
      const labelPath = 'assets/models/class_labels.txt';
      print('[ScanScreen] 📂 Model path: $modelPath');
      print('[ScanScreen] 📂 Labels path: $labelPath');
      print('[ScanScreen] 🎯 TFLite model with 256x256 input, 38 classes output');

      // Load TFLite model
      _interpreter = await Interpreter.fromAsset(modelPath);
      print('[ScanScreen] ✅ TFLite interpreter loaded successfully');

      // Get input/output tensor info
      final inputTensors = _interpreter!.getInputTensors();
      final outputTensors = _interpreter!.getOutputTensors();

      print('[ScanScreen] 📊 Input tensor info:');
      for (var tensor in inputTensors) {
        print('[ScanScreen]   Shape: ${tensor.shape}, Type: ${tensor.type}');
      }
      print('[ScanScreen] 📊 Output tensor info:');
      for (var tensor in outputTensors) {
        print('[ScanScreen]   Shape: ${tensor.shape}, Type: ${tensor.type}');
      }

      print('[ScanScreen] 🏷️ STEP 2: Loading class labels...');
      String labelsData;
      try {
        labelsData = await rootBundle.loadString(labelPath);
        print('[ScanScreen] ✅ Labels file loaded: ${labelsData.length} characters');
      } catch (e) {
        print('[ScanScreen] ❌ Failed to load labels file: $e');
        throw Exception('Labels file not found or corrupted: $labelPath');
      }

      print('[ScanScreen] 🔍 STEP 3: Parsing labels...');
      _labels = labelsData.split('\n').where((label) => label.isNotEmpty).map((label) => label.contains(':') ? label.split(': ').last.trim() : label.trim()).toList();

      print('[ScanScreen] ✅ Parsed ${_labels.length} class labels');
      print('[ScanScreen] 🏷️ First 5 labels: ${_labels.take(5).join(", ")}');
      print('[ScanScreen] 🏷️ Last 5 labels: ${_labels.skip(_labels.length > 5 ? _labels.length - 5 : 0).join(", ")}');

      if (_labels.length != expectedClasses) {
        print('[ScanScreen] ⚠️ WARNING: Expected $expectedClasses classes, but found ${_labels.length}');
      }

      print('[ScanScreen] 💡 STEP 4: Loading treatment advice...');
      try {
        final adviceString = await rootBundle.loadString('assets/models/advice.json');
        final Map<String, dynamic> adviceJson = json.decode(adviceString);
        _adviceData = adviceJson.map((key, value) => MapEntry(key, List<String>.from(value)));
        print('[ScanScreen] ✅ Loaded advice for ${_adviceData.length} diseases');
      } catch (e) {
        print('[ScanScreen] ⚠️ Failed to load advice: $e');
        // Continue without advice - it's not critical
      }

      setState(() {
        _modelLoaded = true;
      });

      print('[ScanScreen] 🎉 TFLITE MODEL INITIALIZATION COMPLETE!');
      print('[ScanScreen] 📈 Ready for inference with ${_labels.length} classes');
      print('[ScanScreen] 🔧 Model: PlantNet TFLite (Converted from PyTorch)');
      print('[ScanScreen] 📊 Input: [1, 3, 256, 256] (NCHW format)');
      print('[ScanScreen] 🎯 Output: Probability array [1, 38]');
    } catch (e, stackTrace) {
      print('[ScanScreen] ❌ CRITICAL ERROR loading model: $e');
      print('[ScanScreen] 🔍 Error type: ${e.runtimeType}');
      print('[ScanScreen] 📋 Stack trace: $stackTrace');

      if (mounted) {
        AppWidgets.showSnackBar(
          context: context,
          message: 'Failed to load AI model: ${e.toString()}',
          type: SnackBarType.error,
        );
      }
    }
  }

  // Helper function to get readable label
  String _getReadableLabel(String label) {
    final Map<String, String> readableLabels = {
      'Apple___Apple_scab': 'Apple - Apple Scab',
      'Apple___Black_rot': 'Apple - Black Rot',
      'Apple___Cedar_apple_rust': 'Apple - Cedar Apple Rust',
      'Apple___healthy': 'Apple - Healthy',
      'Blueberry___healthy': 'Blueberry - Healthy',
      'Cherry_(including_sour)___Powdery_mildew': 'Cherry (Including Sour) - Powdery Mildew',
      'Cherry_(including_sour)___healthy': 'Cherry (Including Sour) - Healthy',
      'Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot': 'Corn (Maize) - Cercospora Leaf Spot (Gray Leaf Spot)',
      'Corn_(maize)___Common_rust_': 'Corn (Maize) - Common Rust',
      'Corn_(maize)___Northern_Leaf_Blight': 'Corn (Maize) - Northern Leaf Blight',
      'Corn_(maize)___healthy': 'Corn (Maize) - Healthy',
      'Grape___Black_rot': 'Grape - Black Rot',
      'Grape___Esca_(Black_Measles)': 'Grape - Esca (Black Measles)',
      'Grape___Leaf_blight_(Isariopsis_Leaf_Spot)': 'Grape - Leaf Blight (Isariopsis Leaf Spot)',
      'Grape___healthy': 'Grape - Healthy',
      'Orange___Haunglongbing_(Citrus_greening)': 'Orange - Huanglongbing (Citrus Greening)',
      'Peach___Bacterial_spot': 'Peach - Bacterial Spot',
      'Peach___healthy': 'Peach - Healthy',
      'Pepper,_bell___Bacterial_spot': 'Bell Pepper - Bacterial Spot',
      'Pepper,_bell___healthy': 'Bell Pepper - Healthy',
      'Potato___Early_blight': 'Potato - Early Blight',
      'Potato___Late_blight': 'Potato - Late Blight',
      'Potato___healthy': 'Potato - Healthy',
      'Raspberry___healthy': 'Raspberry - Healthy',
      'Soybean___healthy': 'Soybean - Healthy',
      'Squash___Powdery_mildew': 'Squash - Powdery Mildew',
      'Strawberry___Leaf_scorch': 'Strawberry - Leaf Scorch',
      'Strawberry___healthy': 'Strawberry - Healthy',
      'Tomato___Bacterial_spot': 'Tomato - Bacterial Spot',
      'Tomato___Early_blight': 'Tomato - Early Blight',
      'Tomato___Late_blight': 'Tomato - Late Blight',
      'Tomato___Leaf_Mold': 'Tomato - Leaf Mold',
      'Tomato___Septoria_leaf_spot': 'Tomato - Septoria Leaf Spot',
      'Tomato___Spider_mites Two-spotted_spider_mite': 'Tomato - Spider Mites (Two-Spotted Spider Mite)',
      'Tomato___Target_Spot': 'Tomato - Target Spot',
      'Tomato___Tomato_Yellow_Leaf_Curl_Virus': 'Tomato - Yellow Leaf Curl Virus',
      'Tomato___Tomato_mosaic_virus': 'Tomato - Mosaic Virus',
      'Tomato___healthy': 'Tomato - Healthy',
    };
    return readableLabels[label] ?? label;
  }

  // Preprocess image for TFLite model
  Float32List _preprocessImage(img.Image image) {
    print('[ScanScreen] 🖼️ Preprocessing image...');

    // Resize to 256x256
    final resized = img.copyResize(image, width: 256, height: 256);
    print('[ScanScreen] ✅ Resized to 256x256');

    // Convert to float32 list with NCHW format (channels first)
    // Shape: [1, 3, 256, 256]
    final input = Float32List(1 * 3 * 256 * 256);

    const mean = [0.485, 0.456, 0.406];
    const std = [0.229, 0.224, 0.225];

    int pixelIndex = 0;
    for (int y = 0; y < 256; y++) {
      for (int x = 0; x < 256; x++) {
        final pixel = resized.getPixel(x, y);

        // Extract RGB values (0-255) and normalize
        final r = pixel.r / 255.0;
        final g = pixel.g / 255.0;
        final b = pixel.b / 255.0;

        // Apply ImageNet normalization in NCHW format (channels first)
        input[pixelIndex] = (r - mean[0]) / std[0]; // R channel
        input[pixelIndex + 256 * 256] = (g - mean[1]) / std[1]; // G channel
        input[pixelIndex + 256 * 256 * 2] = (b - mean[2]) / std[2]; // B channel

        pixelIndex++;
      }
    }

    print('[ScanScreen] ✅ Normalized with ImageNet stats (NCHW format)');
    return input;
  }

  // Run inference with TFLite
  Future<void> _runScan() async {
    print('[ScanScreen] 🚀 STARTING PLANT SCAN PROCESS (TFLite)');

    if (!_modelLoaded || _interpreter == null) {
      print('[ScanScreen] ❌ SCAN CANCELLED: Model not loaded yet');
      AppWidgets.showSnackBar(
        context: context,
        message: 'Model not loaded yet. Please wait...',
        type: SnackBarType.error,
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _hasScanned = false;
    });

    try {
      print('[ScanScreen] 📁 STEP 1: Loading image file...');
      final imageFile = File(widget.imagePath);
      final imageExists = await imageFile.exists();

      if (!imageExists) {
        throw Exception('Image file not found: ${widget.imagePath}');
      }

      final imageBytes = await imageFile.readAsBytes();
      print('[ScanScreen] ✅ Image loaded: ${imageBytes.length} bytes');

      print('[ScanScreen] 🖼️ STEP 2: Decoding image...');
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) {
        throw Exception('Failed to decode image');
      }
      print('[ScanScreen] ✅ Image decoded: ${decodedImage.width}x${decodedImage.height}');

      print('[ScanScreen] 🔄 STEP 3: Preprocessing for TFLite...');
      final input = _preprocessImage(decodedImage);

      print('[ScanScreen] 🤖 STEP 4: Running TFLite inference...');
      final output = List.filled(38, 0.0).reshape([1, 38]);

      _interpreter!.run(input.reshape([1, 3, 256, 256]), output);

      print('[ScanScreen] 📊 STEP 5: Processing prediction result...');
      final probabilities = output[0] as List<double>;
      print('[ScanScreen] 📋 Output shape: ${probabilities.length} probabilities');

      // Find max probability
      double maxProb = 0.0;
      int maxIndex = 0;

      for (int i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          maxIndex = i;
        }
      }

      final confidence = (maxProb * 100).clamp(0.0, 100.0);
      print('[ScanScreen] 🎯 Prediction: index=$maxIndex, confidence=${confidence.toStringAsFixed(2)}%');

      // Show top 5 predictions for debugging
      print('[ScanScreen] 🏆 Top 5 predictions:');
      final sortedIndices = List.generate(probabilities.length, (i) => i)..sort((a, b) => probabilities[b].compareTo(probabilities[a]));

      for (int i = 0; i < 5 && i < sortedIndices.length; i++) {
        final idx = sortedIndices[i];
        final prob = probabilities[idx] * 100;
        final label = idx < _labels.length ? _labels[idx] : 'Unknown';
        print('[ScanScreen]   ${i + 1}. $label: ${prob.toStringAsFixed(2)}%');
      }

      if (maxIndex < 0 || maxIndex >= _labels.length) {
        throw Exception('Class index out of range: $maxIndex (expected 0-${_labels.length - 1})');
      }

      final rawLabel = _labels[maxIndex];
      final readableLabel = _getReadableLabel(rawLabel);

      // Get advice for the detected disease
      List<String> advice = [];
      if (_adviceData.containsKey(rawLabel)) {
        advice = _adviceData[rawLabel]!;
        print('[ScanScreen] 💡 Found ${advice.length} treatment recommendations');
      } else {
        print('[ScanScreen] ⚠️ No advice found for: $rawLabel');
      }

      setState(() {
        _predictedLabel = readableLabel;
        _confidence = confidence;
        _currentAdvice = advice;
        _isProcessing = false;
        _hasScanned = true;
      });

      print('[ScanScreen] ✅ SCAN COMPLETE!');
      print('[ScanScreen] 🏷️ Result: $readableLabel (${confidence.toStringAsFixed(2)}%)');

      if (mounted) {
        AppWidgets.showSnackBar(
          context: context,
          message: 'Scan complete!',
          type: SnackBarType.success,
        );
      }
    } catch (e, stackTrace) {
      print('[ScanScreen] ❌ ERROR: $e');
      print('[ScanScreen] 📋 Stack trace: $stackTrace');

      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        AppWidgets.showSnackBar(
          context: context,
          message: 'Scan failed: ${e.toString()}',
          type: SnackBarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('[ScanScreen] 🎨 BUILDING UI');
    print('[ScanScreen] 📊 Build state: _modelLoaded=$_modelLoaded, _isProcessing=$_isProcessing, _hasScanned=$_hasScanned');

    final imageFile = File(widget.imagePath);
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isHealthy = _predictedLabel.toLowerCase().contains('healthy');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Plant Disease Detection'),
        centerTitle: true,
        actions: [
          if (_hasScanned)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                AppWidgets.showSnackBar(
                  context: context,
                  message: 'Share feature coming soon!',
                  type: SnackBarType.info,
                );
              },
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image preview with modern card
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      Image.file(
                        imageFile,
                        height: size.height * 0.5,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      if (_hasScanned)
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isHealthy ? Colors.green.withOpacity(0.9) : Colors.orange.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isHealthy ? Icons.check_circle : Icons.warning,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isHealthy ? 'Healthy' : 'Disease Detected',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Scan button or loading
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _isProcessing
                    ? Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            CircularProgressIndicator(
                              color: theme.primaryColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Analyzing plant...',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This may take a few seconds',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : !_hasScanned
                        ? SizedBox(
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: _runScan,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 2,
                              ),
                              icon: const Icon(Icons.document_scanner, size: 24),
                              label: const Text(
                                'Scan Plant',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
              ),

              // Results section
              if (_hasScanned && !_isProcessing) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isHealthy
                            ? [
                                Colors.green.shade50,
                                Colors.green.shade100,
                              ]
                            : [
                                Colors.orange.shade50,
                                Colors.orange.shade100,
                              ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isHealthy ? Colors.green.shade200 : Colors.orange.shade200,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isHealthy ? Colors.green.shade600 : Colors.orange.shade600,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isHealthy ? Icons.local_florist : Icons.bug_report,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Diagnosis',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _predictedLabel,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Confidence',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${_confidence.toStringAsFixed(1)}%',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Recommendations section
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb, color: theme.primaryColor, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'Recommendations',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (isHealthy) ...[
                          _buildRecommendation(
                            icon: Icons.check_circle,
                            text: 'Your plant appears to be healthy! Continue with regular care and maintenance.',
                          ),
                        ] else if (_currentAdvice.isNotEmpty) ...[
                          ..._currentAdvice.map((advice) => _buildRecommendation(
                                icon: Icons.healing,
                                text: advice,
                              )),
                        ] else ...[
                          _buildRecommendation(
                            icon: Icons.warning,
                            text: 'Disease detected but no specific treatment advice available. Consult a plant specialist.',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Scan again button
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.primaryColor,
                      side: BorderSide(color: theme.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text(
                      'Scan Another Plant',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendation({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
