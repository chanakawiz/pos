import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/pos_theme.dart';
import '../providers/pos_catalog_provider.dart';
import '../providers/pos_cart_provider.dart';

class BarcodeScannerDialog extends ConsumerStatefulWidget {
  const BarcodeScannerDialog({super.key});

  @override
  ConsumerState<BarcodeScannerDialog> createState() => _BarcodeScannerDialogState();
}

class _BarcodeScannerDialogState extends ConsumerState<BarcodeScannerDialog>
    with SingleTickerProviderStateMixin {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _laserController;
  String? _lastScanned;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _laserController.dispose();
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _processBarcode(String barcode) {
    final clean = barcode.trim();
    if (clean.isEmpty) return;

    final catalogNotifier = ref.read(posCatalogProvider.notifier);
    final product = catalogNotifier.lookupByBarcode(clean);

    if (product != null) {
      ref.read(posCartProvider.notifier).addItem(product);
      setState(() {
        _lastScanned = '${product.name} (LKR ${product.sellingPrice.toStringAsFixed(0)})';
        _statusMessage = 'ADDED TO REGISTER CART';
        _isSuccess = true;
      });
      _codeController.clear();
      _focusNode.requestFocus();
    } else {
      setState(() {
        _lastScanned = 'Barcode "$clean" not found';
        _statusMessage = 'UNRECOGNIZED SKU / BARCODE';
        _isSuccess = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 620),
        decoration: BoxDecoration(
          color: PosTheme.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: PosTheme.primaryGold.withOpacity(0.35), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: PosTheme.cardDark,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                border: Border(bottom: BorderSide(color: PosTheme.dividerDark)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: PosTheme.primaryGold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.qr_code_scanner, color: PosTheme.primaryGold, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'HARDWARE WEDGE & SCANNER',
                          style: TextStyle(
                            color: PosTheme.textWhite,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          'Zebra / Honeywell / Camera Wedge Ready',
                          style: TextStyle(color: PosTheme.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: PosTheme.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Viewfinder Box with Laser Scan Line
                    AspectRatio(
                      aspectRatio: 16 / 10,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF090C0B),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: PosTheme.dividerDark),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Corner reticles
                            Positioned(
                              top: 14,
                              left: 14,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: PosTheme.primaryGold, width: 3),
                                    left: BorderSide(color: PosTheme.primaryGold, width: 3),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 14,
                              right: 14,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: PosTheme.primaryGold, width: 3),
                                    right: BorderSide(color: PosTheme.primaryGold, width: 3),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 14,
                              left: 14,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: PosTheme.primaryGold, width: 3),
                                    left: BorderSide(color: PosTheme.primaryGold, width: 3),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 14,
                              right: 14,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: PosTheme.primaryGold, width: 3),
                                    right: BorderSide(color: PosTheme.primaryGold, width: 3),
                                  ),
                                ),
                              ),
                            ),

                            // Scanning red/gold animated laser
                            AnimatedBuilder(
                              animation: _laserController,
                              builder: (context, child) {
                                return FractionallySizedBox(
                                  alignment: Alignment(0, (_laserController.value * 2) - 1),
                                  heightFactor: 0.05,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 24),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF3B30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFF3B30).withOpacity(0.8),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                            // Center barcode icon
                            Icon(
                              Icons.barcode_reader,
                              size: 56,
                              color: PosTheme.textMuted.withOpacity(0.2),
                            ),

                            Positioned(
                              bottom: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'OPTICAL BEAM ACTIVE',
                                  style: TextStyle(
                                    color: PosTheme.primaryGold,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Feedback status banner
                    if (_statusMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isSuccess
                              ? PosTheme.statusSuccess.withOpacity(0.15)
                              : PosTheme.statusError.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _isSuccess ? PosTheme.statusSuccess : PosTheme.statusError,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isSuccess ? Icons.check_circle : Icons.error_outline,
                              color: _isSuccess ? PosTheme.statusSuccess : PosTheme.statusError,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _statusMessage!,
                                    style: TextStyle(
                                      color: _isSuccess
                                          ? PosTheme.statusSuccess
                                          : PosTheme.statusError,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  if (_lastScanned != null)
                                    Text(
                                      _lastScanned!,
                                      style: const TextStyle(
                                        color: PosTheme.textWhite,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Manual Text Field (Hardware wedge keystroke receiver)
                    TextField(
                      controller: _codeController,
                      focusNode: _focusNode,
                      style: const TextStyle(
                        color: PosTheme.textWhite,
                        fontSize: 15,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                      ),
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.done,
                      onSubmitted: _processBarcode,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: PosTheme.cardDark,
                        hintText: 'Scan or type SKU / Barcode (e.g. 445566)...',
                        hintStyle: TextStyle(color: PosTheme.textMuted, fontSize: 13),
                        prefixIcon: const Icon(Icons.keyboard, color: PosTheme.primaryGold),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.arrow_forward, color: PosTheme.primaryGold),
                          onPressed: () => _processBarcode(_codeController.text),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: PosTheme.dividerDark),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: PosTheme.primaryGold, width: 1.5),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Quick-Scan Hardware Simulators
                    Row(
                      children: [
                        const Icon(Icons.touch_app, size: 14, color: PosTheme.primaryGold),
                        const SizedBox(width: 6),
                        Text(
                          'HARDWARE TEST WEDGES (1-TAP SCAN)',
                          style: TextStyle(
                            color: PosTheme.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildScanChip('445566', 'iPhone 16 Pro Max'),
                        _buildScanChip('556677', 'Galaxy S24 Ultra'),
                        _buildScanChip('667788', 'AirPods Pro 2'),
                        _buildScanChip('112233', 'Studio Ceylon'),
                        _buildScanChip('223344', 'Nike Pegasus'),
                        _buildScanChip('334455', 'Dior Sauvage'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: PosTheme.cardDark,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(19)),
                border: Border(top: BorderSide(color: PosTheme.dividerDark)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Consumer(
                    builder: (context, ref, _) {
                      final count = ref.watch(posCartProvider).totalQuantity;
                      return Text(
                        'Cart Items: $count',
                        style: const TextStyle(
                          color: PosTheme.primaryGold,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      );
                    },
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PosTheme.primaryGold,
                      foregroundColor: const Color(0xFF111413),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('DONE SCANNING', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanChip(String barcode, String label) {
    return ActionChip(
      backgroundColor: PosTheme.cardDark,
      side: BorderSide(color: PosTheme.dividerDark),
      avatar: const Icon(Icons.qr_code, size: 14, color: PosTheme.primaryGold),
      label: Text(
        '$barcode ($label)',
        style: const TextStyle(color: PosTheme.textWhite, fontSize: 11, fontWeight: FontWeight.w600),
      ),
      onPressed: () => _processBarcode(barcode),
    );
  }
}
