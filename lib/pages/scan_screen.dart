import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class ScanScreen extends StatefulWidget {
  final String imagePath;

  const ScanScreen({super.key, required this.imagePath});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  String _predictionResult = "No result"; // Store the prediction result
  bool _isProcessing = false; // Track if model inference is ongoing
  late Interpreter _interpreter; // TensorFlow Lite interpreter
  late InterpreterOptions interpreterOptions;

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
    loadModel(); // Load the TFLite model
  }

  @override
  void dispose() {
    _interpreter.close(); // Release model resources
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
    final predictedIndex = (outputBuffer[0] as List<double>)
        .indexWhere((value) => value == (outputBuffer[0] as List<double>).reduce((a, b) => a > b ? a : b));
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

  @override
  Widget build(BuildContext context) {
    final imageFile = File(widget.imagePath);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Preview'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Image.file(
                    imageFile,
                    fit: BoxFit.contain,
                  )), // Display the image
              const SizedBox(height: 20),
              _isProcessing
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          _isProcessing = true;
                        });

                        // Run inference in isolate
                        String result = await runInferenceInIsolate(widget.imagePath, _labels, _interpreter);

                        setState(() {
                          _predictionResult = result;
                          _isProcessing = false;
                        });
                      },
                      child: const Text(
                        'Scan',
                      ),
                    ),
              const SizedBox(height: 20),
              Text(
                _predictionResult,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
