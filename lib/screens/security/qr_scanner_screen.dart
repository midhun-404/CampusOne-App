import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../core/constants/app_constants.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final code = barcodes.first.rawValue!;
      setState(() => _isProcessing = true);
      
      // Vibrate or beep could be added here if needed
      await _verifyPass(code);
      
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _verifyPass(String passId) async {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator())
    );

    try {
      final pass = await fs.getGatePassById(passId);
      if (context.mounted) Navigator.pop(context); // close loading

      if (pass == null) {
        await _showResult('Invalid Pass', 'This QR Code does not match any existing Gate Pass.', Colors.red);
        return;
      }

      String resultMsg;
      Color resultColor;
      bool isValid = false;

      if (pass.status == AppConstants.statusVerified || pass.status == AppConstants.statusUsed) {
        resultMsg = 'Already Verified';
        resultColor = Colors.orange;
      } else if (pass.isExpired) {
        resultMsg = 'Pass Expired';
        resultColor = Colors.red;
      } else if (pass.status != AppConstants.statusApproved) {
        resultMsg = 'Not Approved';
        resultColor = Colors.red;
      } else {
        resultMsg = 'Valid Pass';
        resultColor = Colors.green;
        isValid = true;
      }

      // Log the scan - This might trigger permission-denied
      try {
        await fs.logGatePassScan(
          passId: passId, 
          studentName: pass.studentName,
          scannedBy: authService.currentUser?.name ?? 'Security', 
          result: resultMsg, 
          department: pass.department,
          profileImageUrl: pass.profileImageUrl,
          isStaff: pass.regNo == null || pass.regNo!.isEmpty,
        );
      } catch (e) {
        debugPrint('Logging failed: $e');
        // We continue even if logging fails, unless the main update fails
      }

      if (isValid) {
        // Mark as verified - This might trigger permission-denied
        await fs.updateGatePassStatus(passId, AppConstants.statusVerified, usedAt: DateTime.now());
      }

      await _showResult(resultMsg, 'Student: ${pass.studentName}\nReg No: ${pass.regNo}\nDestination: ${pass.destination}', resultColor, profileUrl: pass.profileImageUrl);

    } catch (e) {
      if (context.mounted) Navigator.pop(context); // close loading if error
      
      String errorTitle = 'Verification Error';
      String errorMsg = e.toString();
      
      if (e.toString().contains('permission-denied')) {
        errorTitle = 'Permission Denied';
        errorMsg = 'Security user does not have permission to update pass status. Please update Firestore security rules to allow "Security" role to write to "gate_pass_requests" and "gate_pass_logs".';
      }
      
      await _showResult(errorTitle, errorMsg, Colors.red);
    }
  }

  Future<void> _showResult(String title, String subtitle, Color color, {String? profileUrl}) async {
    await showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (profileUrl != null) ...[
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 3),
                ),
                child: CircleAvatar(radius: 50, backgroundImage: NetworkImage(profileUrl)),
              ),
              const SizedBox(height: 20),
            ],
            Icon(
              color == Colors.green ? Icons.check_circle : (color == Colors.orange ? Icons.warning : Icons.error),
              color: color,
              size: 72,
            ),
            const SizedBox(height: 20),
            Text(title, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 12),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey.shade800)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Scan Next', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan E-Gate Pass'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _scannerController.toggleTorch(),
            icon: ValueListenableBuilder(
              valueListenable: _scannerController.torchState,
              builder: (context, state, child) {
                return Icon(state == TorchState.on ? Icons.flash_on : Icons.flash_off);
              },
            ),
          ),
          IconButton(
            onPressed: () => _scannerController.switchCamera(),
            icon: const Icon(Icons.flip_camera_ios),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          // Premium Scanner Overlay
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.7),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 4),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                'Point your camera at the Student\'s QR Code',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          )
        ],
      ),
    );
  }
}

