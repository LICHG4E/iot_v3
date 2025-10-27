import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:iot_v3/widgets/app_widgets.dart';

class DeviceQrScanner extends StatefulWidget {
  const DeviceQrScanner({super.key});

  @override
  State<DeviceQrScanner> createState() => _DeviceQrScannerState();
}

class _DeviceQrScannerState extends State<DeviceQrScanner> with SingleTickerProviderStateMixin {
  bool isScanComplete = false;
  final TextEditingController codeController = TextEditingController();
  late MobileScannerController _scannerController;
  late AnimationController _animationController;
  late Animation<double> _scanLineAnimation;
  bool _showManualEntry = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scannerController.dispose();
    codeController.dispose();
    super.dispose();
  }

  void _handleManualSubmit() {
    if (codeController.text.isEmpty) {
      AppWidgets.showSnackBar(
        context: context,
        message: 'Please enter a device code',
        type: SnackBarType.warning,
      );
      return;
    }

    Navigator.pop(context, codeController.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Device QR Code'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showManualEntry ? Icons.qr_code_scanner : Icons.keyboard),
            onPressed: () {
              setState(() {
                _showManualEntry = !_showManualEntry;
              });
            },
            tooltip: _showManualEntry ? 'Scan QR Code' : 'Manual Entry',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera Scanner
          if (!_showManualEntry && !isScanComplete)
            MobileScanner(
              controller: _scannerController,
              allowDuplicates: false,
              onDetect: (barcode, args) {
                if (!isScanComplete && barcode.rawValue != null) {
                  setState(() {
                    isScanComplete = true;
                  });
                  _scannerController.stop();

                  AppWidgets.showSnackBar(
                    context: context,
                    message: 'QR Code detected!',
                    type: SnackBarType.success,
                  );

                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) {
                      Navigator.pop(context, barcode.rawValue);
                    }
                  });
                }
              },
            ),

          // Scanning overlay with animated line
          if (!_showManualEntry && !isScanComplete)
            Center(
              child: Container(
                width: size.width * 0.7,
                height: size.width * 0.7,
                decoration: BoxDecoration(
                  border: Border.all(color: theme.primaryColor, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    // Corner decorations
                    Positioned(
                      top: -2,
                      left: -2,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -2,
                      left: -2,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(14),
                          ),
                        ),
                      ),
                    ),

                    // Animated scan line
                    AnimatedBuilder(
                      animation: _scanLineAnimation,
                      builder: (context, child) {
                        return Positioned(
                          top: _scanLineAnimation.value * (size.width * 0.7 - 4),
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  theme.primaryColor,
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

          // Instructions card
          if (!_showManualEntry && !isScanComplete)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.primaryColor.withOpacity(0.9),
                      theme.primaryColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Position QR code within the frame',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The scanner will automatically detect the code',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

          // Manual entry section
          if (_showManualEntry)
            Container(
              color: theme.scaffoldBackgroundColor,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.primaryColor.withOpacity(0.1),
                              theme.primaryColor.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.edit_note,
                          size: 80,
                          color: theme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Enter Device Code',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Can\'t scan? Enter the code manually',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: codeController,
                        style: const TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          labelText: 'Device Code',
                          hintText: 'Enter the code from your device',
                          prefixIcon: Icon(Icons.devices, color: theme.primaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: theme.primaryColor, width: 2),
                          ),
                          filled: true,
                          fillColor: theme.cardColor,
                        ),
                        onSubmitted: (_) => _handleManualSubmit(),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _handleManualSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                          ),
                          icon: const Icon(Icons.check_circle, size: 24),
                          label: const Text(
                            'Connect Device',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Loading overlay
          if (isScanComplete)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: theme.primaryColor),
                      const SizedBox(height: 24),
                      Text(
                        'Connecting to device...',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
