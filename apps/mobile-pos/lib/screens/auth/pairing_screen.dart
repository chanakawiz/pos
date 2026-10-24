import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../providers/auth_provider.dart';
import '../scanner/barcode_scanner_dialog.dart';

class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({super.key});

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  final TextEditingController _pairingCodeController = TextEditingController();
  final TextEditingController _deviceNameController =
      TextEditingController(text: 'Mobile Terminal 01');

  bool _isPairing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pairingCodeController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  void _scanPairingQrCode() {
    showDialog(
      context: context,
      builder: (ctx) => BarcodeScannerDialog(
        onBarcodeScanned: (code) {
          setState(() {
            _pairingCodeController.text = code;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Scanned pairing code: $code'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  Future<void> _handlePairing() async {
    final code = _pairingCodeController.text.trim();
    final name = _deviceNameController.text.trim();

    if (code.isEmpty) {
      setState(() => _errorMessage = 'Please enter or scan a pairing code.');
      return;
    }

    setState(() {
      _isPairing = true;
      _errorMessage = null;
    });

    final success = await ref.read(authProvider.notifier).pairDevice(
          pairingCode: code,
          deviceName: name.isNotEmpty ? name : 'Mobile POS Terminal',
        );

    if (!mounted) return;
    setState(() => _isPairing = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terminal paired successfully with store!'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pop(context);
    } else {
      setState(() {
        _errorMessage = ref.read(authProvider).errorMessage ?? 'Pairing failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentDeviceUuid = ApiClient.instance.deviceUuid ?? 'Generating...';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pair POS Terminal'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Icon & Info
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.secondary.withOpacity(0.4)),
                    ),
                    child: const Icon(Icons.qr_code_2, size: 32, color: AppColors.secondary),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Register Terminal',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Scan the QR code displayed in the Filament Admin ERP or enter the terminal pairing code.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
                const SizedBox(height: 24),

                // Error alert
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.danger.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppColors.danger, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Device Name Field
                TextField(
                  controller: _deviceNameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Device Name / Lane Description',
                    hintText: 'e.g. iPad Floor Sales 01',
                    prefixIcon: Icon(Icons.devices, color: AppColors.secondary),
                  ),
                ),
                const SizedBox(height: 14),

                // Pairing Code Field & Camera Scan Button
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _pairingCodeController,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Pairing Code',
                          hintText: 'e.g. POS-IOS-01',
                          prefixIcon: Icon(Icons.vpn_key, color: AppColors.accent),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.all(14),
                      ),
                      icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
                      tooltip: 'Scan QR with Camera',
                      onPressed: _scanPairingQrCode,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Device UUID info chip
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Unique Terminal Fingerprint (UUID):',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      SelectableText(
                        currentDeviceUuid,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isPairing ? null : _handlePairing,
                    child: _isPairing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Pair Device with Central Store'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
