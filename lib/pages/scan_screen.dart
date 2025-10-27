import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:iot_v3/widgets/app_widgets.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

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
  late Interpreter _interpreter;
  late InterpreterOptions interpreterOptions;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // List of labels (hardcoded)
  final List<String> _labels = [
    'Apple___Apple_scab',
    'Apple___Black_rot',
    'Apple___Cedar_apple_rust',
    'Apple___healthy',
    'Blueberry___healthy',
    'Cherry_(including_sour)___Powdery_mildew',
    'Cherry_(including_sour)___healthy',
    'Corn_(maize)___Cercospora_leaf_spot Gray_leaf_spot',
    'Corn_(maize)___Common_rust_',
    'Corn_(maize)___Northern_Leaf_Blight',
    'Corn_(maize)___healthy',
    'Grape___Black_rot',
    'Grape___Esca_(Black_Measles)',
    'Grape___Leaf_blight_(Isariopsis_Leaf_Spot)',
    'Grape___healthy',
    'Orange___Haunglongbing_(Citrus_greening)',
    'Peach___Bacterial_spot',
    'Peach___healthy',
    'Pepper,_bell___Bacterial_spot',
    'Pepper,_bell___healthy',
    'Potato___Early_blight',
    'Potato___Late_blight',
    'Potato___healthy',
    'Raspberry___healthy',
    'Soybean___healthy',
    'Squash___Powdery_mildew',
    'Strawberry___Leaf_scorch',
    'Strawberry___healthy',
    'Tomato___Bacterial_spot',
    'Tomato___Early_blight',
    'Tomato___Late_blight',
    'Tomato___Leaf_Mold',
    'Tomato___Septoria_leaf_spot',
    'Tomato___Spider_mites Two-spotted_spider_mite',
    'Tomato___Target_Spot',
    'Tomato___Tomato_Yellow_Leaf_Curl_Virus',
    'Tomato___Tomato_mosaic_virus',
    'Tomato___healthy'
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
    loadModel();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _interpreter.close();
    super.dispose();
  }

  // Load the TFLite model
  Future<void> loadModel() async {
    try {
      // Load the TFLite model
      interpreterOptions = InterpreterOptions();
      interpreterOptions.threads = 4;
      interpreterOptions.useNnApiForAndroid = false;

      _interpreter = await Interpreter.fromAsset(
        'lib/models/new_plants_disease_model_float32.tflite',
        options: interpreterOptions,
      );
      print('Model loaded successfully.');
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  // This method runs in an isolate to prevent UI freezing
  static Future<String> runInferenceInIsolate(String imagePath, List<String> labels, Interpreter interpreter) async {
    final result = await compute(_processImageAndRunModel, {
      'imagePath': imagePath,
      'labels': labels,
      'interpreter': interpreter,
    });

    return result;
  }

  // Helper function to process the image and run the model
  static Future<String> _processImageAndRunModel(Map<String, dynamic> args) async {
    final String imagePath = args['imagePath'];
    final List<String> labels = args['labels'];
    final Interpreter interpreter = args['interpreter'];
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

    // Preprocess image
    final inputImage = await preprocessImage(imagePath, interpreter);

    // Define output buffer
    final outputShape = interpreter.getOutputTensor(0).shape;
    final outputBuffer = List.filled(outputShape[1], 0.0).reshape(outputShape);

    // Run inference
    interpreter.run(inputImage as Object, outputBuffer);

    // Find the index of the highest confidence score
    final predictedIndex = (outputBuffer[0] as List<double>).indexWhere((value) => value == (outputBuffer[0] as List<double>).reduce((a, b) => a > b ? a : b));
    final predictedLabel = labels[predictedIndex];

    // Use the readable labels map
    final readableLabel = readableLabels[predictedLabel] ?? predictedLabel;

    return "Prediction: $readableLabel (${(outputBuffer[0][predictedIndex] * 10).abs().toStringAsFixed(2)}%)";
  }

  // Preprocess the image to match model input
  static Future<List<List<List<List<double>>>>?> preprocessImage(String imagePath, Interpreter interpreter) async {
    final image = img.decodeImage(File(imagePath).readAsBytesSync());
    if (image == null) return null;

    final inputShape = interpreter.getInputTensor(0).shape;
    final inputSize = inputShape[1]; // Assuming square input
    final resizedImage = img.copyResize(image, width: inputSize, height: inputSize);

    // Normalize image data
    final inputBuffer = List.generate(
      inputSize,
      (y) => List.generate(
        inputSize,
        (x) => List.generate(
          3,
          (c) {
            // Access red, green, and blue channels
            final pixel = resizedImage.getPixel(x, y);
            if (c == 0) {
              return img.getRed(pixel) / 255.0; // Normalize red channel
            }
            if (c == 1) {
              return img.getGreen(pixel) / 255.0; // Normalize green channel
            }
            return img.getBlue(pixel) / 255.0; // Normalize blue channel
          },
        ),
      ),
    );

    return [inputBuffer];
  }

  Future<void> _runScan() async {
    setState(() {
      _isProcessing = true;
      _hasScanned = false;
    });

    try {
      String result = await runInferenceInIsolate(widget.imagePath, _labels, _interpreter);

      // Parse result to extract label and confidence
      final parts = result.split('(');
      final label = parts[0].replaceAll('Prediction: ', '').trim();
      final confidenceStr = parts.length > 1 ? parts[1].replaceAll('%)', '').trim() : '0';

      setState(() {
        _predictedLabel = label;
        _confidence = double.tryParse(confidenceStr) ?? 0.0;
        _isProcessing = false;
        _hasScanned = true;
      });

      if (mounted) {
        AppWidgets.showSnackBar(
          context: context,
          message: 'Scan complete!',
          type: SnackBarType.success,
        );
      }
    } catch (e) {
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
                // Share functionality could be added here
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
                                    'Detection Result',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _predictedLabel,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isHealthy ? Colors.green.shade900 : Colors.orange.shade900,
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
                        _buildRecommendation(
                          icon: Icons.water_drop,
                          text: isHealthy ? 'Continue regular watering schedule' : 'Adjust watering - avoid overwatering',
                        ),
                        const SizedBox(height: 12),
                        _buildRecommendation(
                          icon: Icons.wb_sunny,
                          text: 'Ensure adequate sunlight exposure',
                        ),
                        const SizedBox(height: 12),
                        _buildRecommendation(
                          icon: Icons.eco,
                          text: isHealthy ? 'Plant appears healthy - maintain current care' : 'Consider consulting a plant expert for treatment',
                        ),
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
