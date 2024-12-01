import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class DeviceQrScanner extends StatefulWidget {
  const DeviceQrScanner({super.key});

  @override
  State<DeviceQrScanner> createState() => _DeviceQrScannerState();
}

class _DeviceQrScannerState extends State<DeviceQrScanner> {
  bool isScanComplete = false; // To prevent multiple scans
  late MobileScannerController _scannerController; // To control the scanner

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
  }

  @override
  void dispose() {
    _scannerController.dispose(); // Dispose of the controller when done
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device QR Scanner'),
      ),
      body: Container(
        width: double.infinity,
        child: Column(
          children: [
            Expanded(child: Container()),
            Expanded(
              flex: 4,
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
            Expanded(child: Container()),
            if (isScanComplete)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(), // Show loading spinner
              ),
          ],
        ),
      ),
    );
  }
}
