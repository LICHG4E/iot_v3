import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TestFirestore extends StatelessWidget {
  const TestFirestore({super.key});

  /// Method 1: Check if a subcollection exists
  Future<bool> checkDeviceExists(String deviceId) async {
    try {
      final collectionRef = FirebaseFirestore.instance.collection('beaglebones');
      final subcollectionSnapshot = await collectionRef.doc(deviceId).collection('data').get();

      final exists = subcollectionSnapshot.docs.isNotEmpty;
      print("Method 1 - Subcollection exists for $deviceId: $exists");
      return exists;
    } catch (e) {
      print("Error in Method 1: $e");
      return false;
    }
  }

  /// Method 2: Fetch parent collection and check for subcollection indirectly
  Future<bool> fetchDeviceData(String deviceId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('beaglebones').get();
      final parentDocExists = querySnapshot.docs.any((doc) => doc.id == deviceId);

      // If the parent document exists, check for the subcollection
      if (parentDocExists) {
        final subcollectionSnapshot =
            await FirebaseFirestore.instance.collection('beaglebones').doc(deviceId).collection('data').get();

        final exists = subcollectionSnapshot.docs.isNotEmpty;
        print("Method 2 - Subcollection exists for $deviceId: $exists");
        return exists;
      }

      print("Method 2 - Parent document for $deviceId does NOT exist");
      return false;
    } catch (e) {
      print("Error in Method 2: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    const testDeviceId = 'device_id_123';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Firestore'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            // Perform both checks
            bool existsMethod1 = await checkDeviceExists(testDeviceId);
            bool existsMethod2 = await fetchDeviceData(testDeviceId);

            // Compare results
            String comparisonResult = existsMethod1 == existsMethod2
                ? 'Both methods returned the same result: ${existsMethod1 ? "Subcollection exists" : "Subcollection does NOT exist"}'
                : 'Results differ! Method 1: ${existsMethod1 ? "Exists" : "Does NOT exist"}, Method 2: ${existsMethod2 ? "Exists" : "Does NOT exist"}';

            print(comparisonResult);

            // Show comparison results in a dialog
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Firestore Test Results'),
                content: Text(comparisonResult),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          },
          child: const Text('Check Device Existence'),
        ),
      ),
    );
  }
}
