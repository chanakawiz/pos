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
  late final MobileScannerController _controller;
  final TextEditingController _manualInputController = TextEditingController();
  bool _hasDetected = false;
  bool _cameraFailed = false;
  String _errorMessage = '';

  // Quick test barcodes for simulator & fast cashier testing
  static const List<Map<String, String>> _sampleBarcodes = [
    {'code': '123456', 'name': 'Classic Oxford Shoes', 'type': 'Shoe'},
    {'code': '789012', 'name': 'Nike Air Zoom Pegasus', 'type': 'Shoe'},
    {'code': '112233', 'name': 'Italian Tailored Shirt', 'type': 'Clothing'},
    {'code': '887766', 'name': 'Silk Evening Gala Dress', 'type': 'Clothing'},
    {'code': '445566', 'name': 'iPhone 16 Pro Max (IMEI)', 'type': 'Mobile'},
    {'code': '556677', 'name': 'Samsung Galaxy S24 Ultra', 'type': 'Mobile'},
    {'code': '990011', 'name': 'Anker 65W GaN Charger', 'type': 'Accessory'},
  ];

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      autoStart: true,
    );
  }

  @override
  void dispose() {
    _manualInputController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_hasDetected) return;
    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final code = barcodes.first.rawValue!.trim();
      if (code.isNotEmpty) {
        _submitBarcode(code);
      }
    }
  }

  void _submitBarcode(String code) {
    if (_hasDetected) return;
    final clean = code.trim();
    if (clean.isEmpty) return;

    setState(() {
      _hasDetected = true;
    });

    widget.onBarcodeScanned(clean);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 580),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: const BoxDecoration(
                  color: AppColors.card,
                  border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.qr_code_scanner, color: AppColors.accent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Barcode & IMEI Scanner',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Camera feed or manual code entry',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                      onPressed: () => Navigator.pop(context),
                      splashRadius: 18,
                    ),
                  ],
                ),
              ),

              // Camera viewport or Fallback
              Flexible(
                child: SizedBox(
                  height: 240,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (!_cameraFailed)
                        MobileScanner(
                          controller: _controller,
                          onDetect: _handleBarcode,
                          errorBuilder: (context, error, child) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted && !_cameraFailed) {
                                setState(() {
                                  _cameraFailed = true;
                                  _errorMessage = error.errorCode.name;
                                });
                              }
                            });
                            return _buildCameraFallback();
                          },
                        )
                      else
                        _buildCameraFallback(),

                      // Overlay target box (only if camera is active)
                      if (!_cameraFailed) ...[
                        Center(
                          child: Container(
                            width: 200,
                            height: 120,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.accent, width: 2),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withOpacity(0.2),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Torch button
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black.withOpacity(0.6),
                            ),
                            icon: const Icon(Icons.flash_on, color: AppColors.accent, size: 18),
                            onPressed: () => _controller.toggleTorch(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Manual Entry Section
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border, width: 1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MANUAL BARCODE / IMEI INPUT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: TextField(
                              controller: _manualInputController,
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Enter barcode or IMEI...',
                                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                prefixIcon: const Icon(Icons.barcode_reader, color: AppColors.textMuted, size: 18),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                filled: true,
                                fillColor: AppColors.card,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: AppColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: AppColors.accent),
                                ),
                              ),
                              onSubmitted: _submitBarcode,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                            ),
                            onPressed: () => _submitBarcode(_manualInputController.text),
                            child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Quick test presets
                    const Text(
                      'QUICK TEST BARCODES (SIMULATOR MODE)',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _sampleBarcodes.map((item) {
                        return InkWell(
                          onTap: () => _submitBarcode(item['code']!),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.border, width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item['code']!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accent,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(${item['type']})',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraFallback() {
    return Container(
      color: const Color(0xFF0D131F),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.camera_alt_outlined, color: AppColors.textMuted, size: 24),
              ),
              const SizedBox(height: 8),
              const Text(
                'Camera hardware inactive or simulated',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _errorMessage.isNotEmpty
                    ? 'Status: $_errorMessage. Use manual entry or quick presets below.'
                    : 'iOS Simulator has no camera. Use manual entry or quick presets below.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
