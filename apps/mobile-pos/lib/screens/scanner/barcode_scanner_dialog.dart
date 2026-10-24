import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/constants/app_colors.dart';

class BarcodeScannerDialog extends StatefulWidget {
  final Function(String barcode) onBarcodeScanned;

  const BarcodeScannerDialog({super.key, required this.onBarcodeScanned});

  @override
  State<BarcodeScannerDialog> createState() => _BarcodeScannerDialogState();
}

class _BarcodeScannerDialogState extends State<BarcodeScannerDialog> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _hasDetected = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_hasDetected) return;
    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final code = barcodes.first.rawValue!.trim();
      if (code.isNotEmpty) {
        setState(() {
          _hasDetected = true;
        });
        widget.onBarcodeScanned(code);
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 360,
          height: 440,
          child: Stack(
            children: [
              MobileScanner(
                controller: _controller,
                onDetect: _handleBarcode,
              ),

              // Scanner Viewfinder Overlay
              Center(
                child: Container(
                  width: 240,
                  height: 160,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              // Top Bar Controls
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Align barcode inside box',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Bottom Torch toggle
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                    icon: const Icon(Icons.flash_on, color: AppColors.accent),
                    onPressed: () => _controller.toggleTorch(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
