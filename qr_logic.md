QR CODE GENERATION AND VERIFICATION CODE

DEPENDENCIES:
Add these to pubspec.yaml:
qr_flutter: ^4.1.0
mobile_scanner: ^4.0.1

1. QR CODE GENERATION (STUDENT SIDE)
This code uses the qr_flutter package to display the Gate Pass ID as a QR Code.

import 'package:qr_flutter/qr_flutter.dart';

// In your Widget build:
QrImageView(
  data: gatePass.id, // The ID of the gate pass from Firestore
  version: QrVersions.auto,
  size: 200.0,
  dataModuleStyle: const QrDataModuleStyle(
    dataModuleShape: QrDataModuleShape.square,
    color: Colors.blue,
  ),
  eyeStyle: const QrEyeStyle(
    eyeShape: QrEyeShape.square,
    color: Colors.blue,
  ),
)


2. QR CODE VERIFICATION (SECURITY/SCANNER SIDE)
This code uses the mobile_scanner package to scan and verify the pass in Firestore.

import 'package:mobile_scanner/mobile_scanner.dart';

// Scanner Widget logic
void onDetect(BarcodeCapture capture) async {
  final List<Barcode> barcodes = capture.barcodes;
  if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
    final String passId = barcodes.first.rawValue!;
    await verifyGatePass(passId);
  }
}

// Verification Logic
Future<void> verifyGatePass(String passId) async {
  try {
    // 1. Fetch pass from Firestore
    final passDoc = await FirebaseFirestore.instance
        .collection('gate_pass_requests')
        .doc(passId)
        .get();

    if (!passDoc.exists) {
      print('Invalid Pass: Not found in database');
      return;
    }

    final passData = passDoc.data()!;
    final String status = passData['status'];
    final Timestamp? expiry = passData['expiryTimestamp'];

    // 2. Check Validity
    bool isExpired = expiry != null && DateTime.now().isAfter(expiry.toDate());

    if (isExpired) {
      print('Verification Failed: Pass has expired');
    } else if (status != 'Approved') {
      print('Verification Failed: Pass status is $status');
    } else {
      // 3. Success: Mark as Verified
      await FirebaseFirestore.instance
          .collection('gate_pass_requests')
          .doc(passId)
          .update({
        'status': 'Verified',
        'usedAt': FieldValue.serverTimestamp(),
      });
      print('Verification Success: Student can exit');
    }
  } catch (e) {
    print('Error during verification: $e');
  }
}
