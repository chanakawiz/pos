import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/theme/pos_theme.dart';
import '../providers/pos_auth_provider.dart';

class ShiftOpenDialog extends ConsumerStatefulWidget {
  final VoidCallback onShiftOpened;

  const ShiftOpenDialog({super.key, required this.onShiftOpened});

  @override
  ConsumerState<ShiftOpenDialog> createState() => _ShiftOpenDialogState();
}

class _ShiftOpenDialogState extends ConsumerState<ShiftOpenDialog> {
  final _floatController = TextEditingController(text: '10000.00');
  final _notesController = TextEditingController(text: 'Morning mobile shift open');

  final List<double> _presets = [5000.00, 10000.00, 15000.00, 20000.00];

  @override
  void dispose() {
    _floatController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitOpeningFloat() async {
    final floatVal = double.tryParse(_floatController.text.replaceAll(',', '')) ?? 0.00;
    final success = await ref.read(posAuthProvider.notifier).openShift(
      openingFloat: floatVal,
      notes: _notesController.text.trim(),
    );

    if (success && mounted) {
      widget.onShiftOpened();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(posAuthProvider);
    final currencyFormat = NumberFormat('#,##0.00');

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: PosTheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: PosTheme.border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon & Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: PosTheme.forestGreen.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: PosTheme.primaryGold.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.point_of_sale_rounded, color: PosTheme.primaryGold, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'OPEN REGISTER SHIFT',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: PosTheme.primaryGold,
                          ),
                        ),
                        Text(
                          'Initial Drawer Float',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: PosTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text(
                'Enter the physical cash float verified in the mobile cash bag before taking orders:',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: PosTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // Float Amount Field
              TextField(
                controller: _floatController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: PosTheme.primaryGold,
                ),
                decoration: InputDecoration(
                  prefixText: 'LKR  ',
                  prefixStyle: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: PosTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Presets Row
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presets.map((preset) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _floatController.text = preset.toStringAsFixed(2);
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: PosTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: PosTheme.border),
                      ),
                      child: Text(
                        'LKR ${currencyFormat.format(preset)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: PosTheme.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Notes Field
              TextField(
                controller: _notesController,
                style: GoogleFonts.inter(fontSize: 13, color: PosTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Shift Notes (Optional)',
                  hintText: 'e.g. Roaming floor lane count verified',
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: authState.isLoading ? null : _submitOpeningFloat,
                child: authState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Text('CONFIRM FLOAT & ENTER REGISTER'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
