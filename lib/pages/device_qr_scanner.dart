import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class DeviceQrScanner extends StatefulWidget {
  const DeviceQrScanner({super.key});

  @override
  State<DeviceQrScanner> createState() => _DeviceQrScannerState();
}

class _DeviceQrScannerState extends State<DeviceQrScanner> {
  bool isScanComplete = false;
  final TextEditingController codeController = TextEditingController();
  late MobileScannerController _scannerController; // To control the scanner

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device QR Scanner'),
      ),
      body: SingleChildScrollView(
        // Make the body scrollable
        child: Container(
          width: double.infinity,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Scan the QR code on the device to connect, or enter the code manually',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: codeController,
                            decoration: const InputDecoration(
                              labelText: 'Enter code',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            if (codeController.text.isNotEmpty) {
                              Navigator.pop(context, codeController.text);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a code'),
                                ),
                              );
                            }
                          },
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                height: MediaQuery.of(context).size.height / 2, // Use a fraction of the screen height
                child: MobileScanner(
                  controller: _scannerController,
                  allowDuplicates: false, // Prevent duplicate scans
                  onDetect: (barcode, args) {
                    if (!isScanComplete) {
                      setState(() {
                        isScanComplete = true;
                      });

                      // Pass the scanned value back to the previous screen
                      Navigator.pop(context, barcode.rawValue);

                      // Optionally stop the scanner after the first scan
                      _scannerController.stop();
                    }
                  },
                ),
              ),
              if (isScanComplete)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(), // Show loading spinner
                ),
            ],
          ),
        ),
      ),
    );
  }
}
