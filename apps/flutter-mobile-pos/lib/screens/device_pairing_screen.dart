import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/pos_theme.dart';
import '../providers/pos_auth_provider.dart';
import 'staff_pin_screen.dart';

class DevicePairingScreen extends ConsumerStatefulWidget {
  const DevicePairingScreen({super.key});

  @override
  ConsumerState<DevicePairingScreen> createState() => _DevicePairingScreenState();
}

class _DevicePairingScreenState extends ConsumerState<DevicePairingScreen> {
  final _apiUrlController = TextEditingController(text: 'http://127.0.0.1:8000');
  final _storeCodeController = TextEditingController(text: 'STORE-001');
  final _deviceCodeController = TextEditingController(text: 'ROAMING-01');

  @override
  void dispose() {
    _apiUrlController.dispose();
    _storeCodeController.dispose();
    _deviceCodeController.dispose();
    super.dispose();
  }

  Future<void> _handlePairing() async {
    final success = await ref.read(posAuthProvider.notifier).pairDevice(
      apiUrl: _apiUrlController.text.trim(),
      storeCode: _storeCodeController.text.trim(),
      deviceCode: _deviceCodeController.text.trim(),
    );

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const StaffPinScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(posAuthProvider);

    return Scaffold(
      backgroundColor: PosTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Brand Medallion
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: PosTheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: PosTheme.primaryGold, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: PosTheme.primaryGold.withValues(alpha: 0.25),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'O',
                          style: GoogleFonts.outfit(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: PosTheme.primaryGold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header Titles
                  Text(
                    'OMNILUXE STORE',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      color: PosTheme.primaryGold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Handheld POS Provisioning',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: PosTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pair this roaming mobile terminal with your central boutique ERP network.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: PosTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Provisioning Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: PosTheme.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: PosTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CENTRAL ERP GATEWAY',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: PosTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _apiUrlController,
                          style: GoogleFonts.inter(color: PosTheme.textPrimary),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.dns_outlined, color: PosTheme.primaryGold),
                            hintText: 'e.g. http://127.0.0.1:8000',
                          ),
                        ),
                        const SizedBox(height: 20),

                        Text(
                          'STORE IDENTIFIER',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: PosTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _storeCodeController,
                          style: GoogleFonts.inter(color: PosTheme.textPrimary),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.storefront_outlined, color: PosTheme.primaryGold),
                            hintText: 'e.g. STORE-001',
                          ),
                        ),
                        const SizedBox(height: 20),

                        Text(
                          'TERMINAL DEVICE CODE',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: PosTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _deviceCodeController,
                          style: GoogleFonts.inter(color: PosTheme.textPrimary),
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.point_of_sale_outlined, color: PosTheme.primaryGold),
                            hintText: 'e.g. ROAMING-01',
                          ),
                        ),
                        const SizedBox(height: 28),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: authState.isLoading ? null : _handlePairing,
                            child: authState.isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                  )
                                : const Text('PAIR DEVICE & PROCEED'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
