import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/api_client.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        _isProcessing = true;
        await _processCode(barcode.rawValue!);
        break; // Only process one
      }
    }
  }

  Future<void> _processCode(String code) async {
    try {
      // Check if it's a Resident ID JWT (long string) or a Guest Code (short 5-digit)
      if (code.length > 10) {
        // Assume ID Token
        final result = await ApiClient.verifyIdentity(code);
        if (mounted) {
           Navigator.pop(context, {'type': 'IDENTITY', 'data': result});
        }
      } else {
        // Assume Guest Pass Code
        if (mounted) {
           Navigator.pop(context, {'type': 'PASS_CODE', 'code': code});
        }
      }
    } catch (e) {
       // Show error overlay?
       _isProcessing = false; // Reset to allow retry
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(LucideIcons.scanLine, color: Colors.white54, size: 48),
                ],
              ),
            ),
          ),
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              "Point camera at Guest Pass or Resident ID",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          )
        ],
      ),
    );
  }
}
