import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iot_v3/widgets/app_widgets.dart';
import 'package:pytorch_lite/pytorch_lite.dart';
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
  late ClassificationModel _model;
  late List<String> _labels;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _modelLoaded = false;

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
    super.dispose();
  }

  // Load the PyTorch model
  Future<void> loadModel() async {
    print('[ScanScreen] 🔄 STARTING MODEL LOADING PROCESS');
    print('[ScanScreen] 📊 Current state: _modelLoaded=${_modelLoaded}');
    print('[ScanScreen] 🕐 Timestamp: ${DateTime.now()}');

    const expectedClasses = 38;
    print('[ScanScreen] 🎯 Expected classes: $expectedClasses');

    try {
      print('[ScanScreen] 📁 STEP 1: Checking model file existence...');
      final modelPath = 'lib/models/mobile_plantnet_mobile_ready.pt';
      final labelPath = 'lib/models/class_labels.txt';
      print('[ScanScreen] 📂 Model path: $modelPath (MobilePlantNet Mobile-Ready)');
      print('[ScanScreen] 📂 Labels path: $labelPath');
      print('[ScanScreen] 🎯 This model has BUILT-IN preprocessing - no manual normalization needed!');

      print('[ScanScreen] 🔍 Checking model file...');
      try {
        final modelData = await rootBundle.load(modelPath);
        print('[ScanScreen] ✅ Model file found: ${modelData.lengthInBytes} bytes');
        print('[ScanScreen] 📏 Model file size: ${(modelData.lengthInBytes / 1024 / 1024).toStringAsFixed(2)} MB');
      } catch (e) {
        print('[ScanScreen] ❌ Model file not found at $modelPath: $e');
        print('[ScanScreen] 🔍 Checking if file exists in assets...');
        try {
          final assetManifest = await rootBundle.loadString('AssetManifest.json');
          print('[ScanScreen] 📋 Asset manifest contains: ${assetManifest.contains(modelPath)}');
        } catch (e2) {
          print('[ScanScreen] ❌ Could not check asset manifest: $e2');
        }
        throw Exception('Model file not found: $modelPath');
      }

      print('[ScanScreen] 🏷️ STEP 2: Loading class labels...');
      String labelsData;
      try {
        labelsData = await rootBundle.loadString(labelPath);
        print('[ScanScreen] ✅ Labels file loaded: ${labelsData.length} characters');
        print('[ScanScreen] 📝 Raw labels data (first 200 chars): ${labelsData.substring(0, labelsData.length > 200 ? 200 : labelsData.length)}');
        print('[ScanScreen] 📝 Raw labels data (last 200 chars): ${labelsData.substring(labelsData.length > 200 ? labelsData.length - 200 : 0)}');
      } catch (e) {
        print('[ScanScreen] ❌ Failed to load labels file: $e');
        throw Exception('Labels file not found or corrupted: $labelPath');
      }

      print('[ScanScreen] 🔍 STEP 3: Parsing labels...');
      // Labels format: "0: Apple___Apple_scab" - extract just the class name
      _labels = labelsData.split('\n').where((label) => label.isNotEmpty).map((label) => label.contains(':') ? label.split(': ').last.trim() : label.trim()).toList();
      print('[ScanScreen] ✅ Parsed ${_labels.length} class labels');
      print('[ScanScreen] 🏷️ First 5 labels: ${_labels.take(5).join(", ")}');
      print('[ScanScreen] 🏷️ Last 5 labels: ${_labels.skip(_labels.length > 5 ? _labels.length - 5 : 0).join(", ")}');

      if (_labels.isEmpty) {
        print('[ScanScreen] ❌ CRITICAL: No valid labels found after parsing');
        throw Exception('No valid labels found in file');
      }

      print('[ScanScreen] 🔍 STEP 4: Validating label count...');
      if (_labels.length != expectedClasses) {
        print('[ScanScreen] ⚠️ WARNING: Expected $expectedClasses classes, but found ${_labels.length}');
        print('[ScanScreen] 📋 All labels (${_labels.length}):');
        for (int i = 0; i < _labels.length; i++) {
          print('[ScanScreen]   ${i.toString().padLeft(2)}: ${_labels[i]}');
        }
      } else {
        print('[ScanScreen] ✅ Label count matches expected: ${_labels.length} classes');
      }

      print('[ScanScreen] 🤖 STEP 5: Loading PyTorch classification model...');
      print('[ScanScreen] 📊 Model config: $expectedClasses classes, 256x256 input');
      print('[ScanScreen] 🔧 Model type: ClassificationModel (not ObjectDetectionModel)');

      try {
        _model = await PytorchLite.loadClassificationModel(
          modelPath,
          expectedClasses,
          256, // Image width
          256, // Image height
        );
        print('[ScanScreen] ✅ PyTorch classification model loaded successfully');
        print('[ScanScreen] 🎯 Model expects input: [1, 3, 256, 256]');
        print('[ScanScreen] 📤 Model outputs: class index (0-${expectedClasses - 1})');
      } catch (modelError) {
        print('[ScanScreen] ❌ Failed to load PyTorch model: $modelError');
        print('[ScanScreen] 🔍 Model loading error type: ${modelError.runtimeType}');
        throw modelError;
      }

      print('[ScanScreen] 🔍 STEP 6: Verifying model...');
      print('[ScanScreen] ✅ Model object created successfully');
      print('[ScanScreen] 🔧 Model runtime type: ${_model.runtimeType}');

      setState(() {
        _modelLoaded = true;
      });

      print('[ScanScreen] 🎉 MODEL INITIALIZATION COMPLETE!');
      print('[ScanScreen] 📈 Ready for inference with ${_labels.length} classes');
      print('[ScanScreen] 🔧 Model type: MobilePlantNet Mobile-Ready v1.0');
      print('[ScanScreen] 📊 Input: 256x256 RGB images (auto-resized by pytorch_lite)');
      print('[ScanScreen] 🎯 Output: Probability array [38] summing to 1.0');
      print('[ScanScreen] ✨ BUILT-IN: ImageNet normalization + Softmax');
      print('[ScanScreen] 🏷️ Label mapping example:');
      print('[ScanScreen]   Index 0 → ${_labels[0]}');
      print('[ScanScreen]   Index ${_labels.length - 1} → ${_labels[_labels.length - 1]}');
      print('[ScanScreen] ✅ True drag-and-drop model - no preprocessing needed!');
    } catch (e, stackTrace) {
      print('[ScanScreen] ❌ CRITICAL ERROR loading model: $e');
      print('[ScanScreen] 🔍 Error type: ${e.runtimeType}');
      print('[ScanScreen] 📋 Full stack trace:');
      print('[ScanScreen] $stackTrace');

      // Provide specific error guidance
      if (e.toString().contains('file not found') || e.toString().contains('AssetManifest')) {
        print('[ScanScreen] 💡 SOLUTION: Model file not found!');
        print('[ScanScreen] 🔍 Check these locations:');
        print('[ScanScreen]   1. lib/models/mobile_plantnet_scripted_cpu.pt exists');
        print('[ScanScreen]   2. File is included in pubspec.yaml assets');
        print('[ScanScreen]   3. File is not corrupted (try re-uploading)');
      } else if (e.toString().contains('labels') || e.toString().contains('class_labels')) {
        print('[ScanScreen] 💡 SOLUTION: Labels file issue!');
        print('[ScanScreen] 📝 class_labels.txt should contain one class name per line');
        print('[ScanScreen] 🎯 Should have exactly 38 lines for this model');
      } else if (e.toString().contains('CUDA') || e.toString().contains('cuda')) {
        print('[ScanScreen] 💡 SOLUTION: Model was trained with CUDA (GPU)!');
        print('[ScanScreen] 📋 Convert to CPU-only model:');
        print('[ScanScreen]   1. model = torch.load("your_model.pth")');
        print('[ScanScreen]   2. model = model.cpu()');
        print('[ScanScreen]   3. model.eval()');
        print('[ScanScreen]   4. dummy = torch.randn(1, 3, 224, 224)');
        print('[ScanScreen]   5. traced = torch.jit.trace(model, dummy)');
        print('[ScanScreen]   6. traced.save("mobile_plantnet_scripted_cpu.pt")');
        print('[ScanScreen]   ⚠️ MUST be done on CPU, not GPU!');
      } else if (e.toString().contains('Tuple') || e.toString().contains('Tensor')) {
        print('[ScanScreen] 💡 SOLUTION: Model format mismatch!');
        print('[ScanScreen] 📊 Your model returns Tensor (classification) but code expects Tuple (detection)');
        print('[ScanScreen] ✅ This is NORMAL for plant disease models');
        print('[ScanScreen] 🔧 Code has been fixed to handle classification');
      } else if (e.toString().contains('PyTorch') || e.toString().contains('pytorch')) {
        print('[ScanScreen] 💡 SOLUTION: PyTorch model issue!');
        print('[ScanScreen] 📏 Check input dimensions: should be 224x224');
        print('[ScanScreen] 🎯 Check output classes: should be 38');
        print('[ScanScreen] 🔄 Ensure proper TorchScript export');
      } else {
        print('[ScanScreen] 💡 SOLUTION: General troubleshooting!');
        print('[ScanScreen] 📱 Try: Clear app data, restart device, reinstall app');
        print('[ScanScreen] 🔧 Check: Device storage space, Android version');
      }

      // Show user-friendly error
      if (mounted) {
        print('[ScanScreen] 📢 Showing error snackbar to user');
        AppWidgets.showSnackBar(
          context: context,
          message: 'Failed to load AI model. Check debug console for details.',
          type: SnackBarType.error,
        );
      } else {
        print('[ScanScreen] ⚠️ Cannot show snackbar - widget not mounted');
      }
    }
  } // Helper function to get readable label

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

// Fixed _runScan() method with correct preprocessing
  Future<void> _runScan() async {
    print('[ScanScreen] 🚀 STARTING PLANT SCAN PROCESS');

    if (!_modelLoaded) {
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
      print('[ScanScreen] 📏 Image size: ${(imageBytes.length / 1024).toStringAsFixed(2)} KB');

      print('[ScanScreen] 🤖 STEP 2: Running PyTorch inference...');
      print('[ScanScreen] ✨ Using mobile-ready model with BUILT-IN preprocessing!');
      print('[ScanScreen] 📊 PyTorch Lite will automatically:');
      print('[ScanScreen]   1. Resize image to 256x256');
      print('[ScanScreen]   2. Convert to 0-1 range');
      print('[ScanScreen]   3. Model applies ImageNet normalization internally');
      print('[ScanScreen]   4. Model applies softmax for probabilities');

      // No manual preprocessing needed! The model has everything built-in
      final result = await _model.getImagePredictionList(imageBytes);

      print('[ScanScreen] 📊 STEP 3: Processing prediction result...');
      print('[ScanScreen] 📋 Raw result: $result');

      int classIndex;
      double confidence = 0.0;

      if (result.isNotEmpty) {
        print('[ScanScreen] ✅ Model returned probabilities array with ${result.length} elements');

        // Find max probability
        double maxProb = 0.0;
        int maxIndex = 0;

        for (int i = 0; i < result.length; i++) {
          final prob = result[i].toDouble();
          if (prob > maxProb) {
            maxProb = prob;
            maxIndex = i;
          }
        }

        classIndex = maxIndex;
        confidence = (maxProb * 100).clamp(0.0, 100.0);

        print('[ScanScreen] 🎯 Prediction: index=$classIndex, confidence=${confidence.toStringAsFixed(2)}%');

        // Show top 5 predictions for debugging
        print('[ScanScreen] 🏆 Top 5 predictions:');
        final sortedIndices = List.generate(result.length, (i) => i)..sort((a, b) => result[b].compareTo(result[a]));

        for (int i = 0; i < 5 && i < sortedIndices.length; i++) {
          final idx = sortedIndices[i];
          final prob = (result[idx] as num).toDouble() * 100;
          final label = idx < _labels.length ? _labels[idx] : 'Unknown';
          print('[ScanScreen]   ${i + 1}. $label: ${prob.toStringAsFixed(2)}%');
        }
      } else {
        throw Exception('Model returned invalid result format');
      }

      if (classIndex < 0 || classIndex >= _labels.length) {
        throw Exception('Class index out of range: $classIndex (expected 0-${_labels.length - 1})');
      }

      final rawLabel = _labels[classIndex];
      final readableLabel = _getReadableLabel(rawLabel);

      setState(() {
        _predictedLabel = readableLabel;
        _confidence = confidence;
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
    print('[ScanScreen] 🏷️ Current prediction: "$_predictedLabel"');
    print('[ScanScreen] 📊 Current confidence: $_confidence%');

    final imageFile = File(widget.imagePath);
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isHealthy = _predictedLabel.toLowerCase().contains('healthy');
    print('[ScanScreen] 🎯 Health status: ${isHealthy ? "HEALTHY" : "DISEASED"}');

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
