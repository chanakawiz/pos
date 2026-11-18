import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme/pos_theme.dart';
import '../models/shift_session_report.dart';
import '../providers/pos_shift_provider.dart';

class ShiftCloseDialog extends ConsumerStatefulWidget {
  const ShiftCloseDialog({super.key});

  @override
  ConsumerState<ShiftCloseDialog> createState() => _ShiftCloseDialogState();
}

class _ShiftCloseDialogState extends ConsumerState<ShiftCloseDialog> {
  final TextEditingController _cashCountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final NumberFormat _currency = NumberFormat.currency(symbol: 'LKR ', decimalDigits: 2);
  ShiftSessionReport? _completedZReport;

  @override
  void dispose() {
    _cashCountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onConfirmClose(double expectedCash) async {
    final entered = double.tryParse(_cashCountController.text.replaceAll(',', '')) ?? expectedCash;

    final zReport = await ref.read(posShiftProvider.notifier).closeShift(
          closingCountedCash: entered,
          notes: _notesController.text.trim(),
          printReceipt: true,
        );

    if (mounted && zReport != null) {
      setState(() {
        _completedZReport = zReport;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final shiftState = ref.watch(posShiftProvider);
    final summary = shiftState.activeSummary;
    final expectedCash = summary?.expectedCash ?? 15000.0;
    final enteredCash = double.tryParse(_cashCountController.text.replaceAll(',', '')) ?? expectedCash;
    final discrepancy = enteredCash - expectedCash;

    if (_completedZReport != null) {
      return _buildZReportSuccessDialog(_completedZReport!);
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 660),
        decoration: BoxDecoration(
          color: PosTheme.surfaceDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: PosTheme.accentAmber.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),
              blurRadius: 32,
              offset: const Offset(0, 12),
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
                border: Border(bottom: BorderSide(color: PosTheme.dividerDark)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: PosTheme.accentAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.lock_clock, color: PosTheme.accentAmber, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CLOSE REGISTER SHIFT (Z-REPORT)',
                          style: TextStyle(
                            color: PosTheme.textWhite,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          'Cash Count & Drawer Discrepancy Reconciliation',
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
                    // Financial summary card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: PosTheme.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: PosTheme.dividerDark),
                      ),
                      child: Column(
                        children: [
                          _buildRow('Opening Float', _currency.format(summary?.openingFloat ?? 0.0)),
                          _buildRow('Cash Sales', _currency.format(summary?.cashSales ?? 0.0)),
                          _buildRow('Card Sales', _currency.format(summary?.cardSales ?? 0.0)),
                          _buildRow('Total Bills', '${summary?.transactionsCount ?? 0} bills'),
                          const Divider(color: PosTheme.dividerDark),
                          _buildRow(
                            'EXPECTED DRAWER CASH',
                            _currency.format(expectedCash),
                            isBold: true,
                            color: PosTheme.primaryGold,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Counted Cash Input
                    const Text(
                      'ACTUAL COUNTED CASH IN DRAWER',
                      style: TextStyle(color: PosTheme.textWhite, fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _cashCountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: PosTheme.textWhite, fontSize: 20, fontWeight: FontWeight.w800),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: PosTheme.cardDark,
                        hintText: expectedCash.toStringAsFixed(0),
                        prefixText: 'LKR ',
                        prefixStyle: const TextStyle(color: PosTheme.primaryGold, fontWeight: FontWeight.w700),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 10),

                    // Quick buttons
                    Wrap(
                      spacing: 8,
                      children: [
                        ActionChip(
                          label: Text('Exact (${_currency.format(expectedCash)})', style: const TextStyle(fontSize: 11, color: PosTheme.primaryGold)),
                          backgroundColor: PosTheme.cardDark,
                          side: const BorderSide(color: PosTheme.primaryGold),
                          onPressed: () {
                            _cashCountController.text = expectedCash.toStringAsFixed(0);
                            setState(() {});
                          },
                        ),
                        ActionChip(
                          label: const Text('+1,000', style: TextStyle(fontSize: 11)),
                          backgroundColor: PosTheme.cardDark,
                          onPressed: () {
                            final cur = double.tryParse(_cashCountController.text.replaceAll(',', '')) ?? 0.0;
                            _cashCountController.text = (cur + 1000).toStringAsFixed(0);
                            setState(() {});
                          },
                        ),
                        ActionChip(
                          label: const Text('+5,000', style: TextStyle(fontSize: 11)),
                          backgroundColor: PosTheme.cardDark,
                          onPressed: () {
                            final cur = double.tryParse(_cashCountController.text.replaceAll(',', '')) ?? 0.0;
                            _cashCountController.text = (cur + 5000).toStringAsFixed(0);
                            setState(() {});
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Discrepancy indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: discrepancy.abs() < 0.01
                            ? PosTheme.statusSuccess.withValues(alpha: 0.15)
                            : (discrepancy > 0
                                ? PosTheme.accentAmber.withValues(alpha: 0.15)
                                : PosTheme.statusError.withValues(alpha: 0.15)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: discrepancy.abs() < 0.01
                              ? PosTheme.statusSuccess
                              : (discrepancy > 0 ? PosTheme.accentAmber : PosTheme.statusError),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            discrepancy.abs() < 0.01
                                ? 'DRAWER BALANCED'
                                : (discrepancy > 0 ? 'DRAWER OVER' : 'DRAWER SHORT'),
                            style: TextStyle(
                              color: discrepancy.abs() < 0.01
                                  ? PosTheme.statusSuccess
                                  : (discrepancy > 0 ? PosTheme.accentAmber : PosTheme.statusError),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            discrepancy >= 0 ? '+${_currency.format(discrepancy)}' : _currency.format(discrepancy),
                            style: TextStyle(
                              color: discrepancy.abs() < 0.01
                                  ? PosTheme.statusSuccess
                                  : (discrepancy > 0 ? PosTheme.accentAmber : PosTheme.statusError),
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Notes
                    TextField(
                      controller: _notesController,
                      style: const TextStyle(color: PosTheme.textWhite, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: PosTheme.cardDark,
                        hintText: 'Supervisor authorization / closing notes...',
                        hintStyle: TextStyle(color: PosTheme.textMuted, fontSize: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: PosTheme.cardDark,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(23)),
                border: Border(top: BorderSide(color: PosTheme.dividerDark)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: shiftState.isClosing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Icon(Icons.lock, size: 18),
                  label: const Text('CONFIRM COUNT & CLOSE REGISTER', style: TextStyle(fontWeight: FontWeight.w900)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PosTheme.accentAmber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: shiftState.isClosing ? null : () => _onConfirmClose(expectedCash),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZReportSuccessDialog(ShiftSessionReport z) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 560),
        decoration: BoxDecoration(
          color: PosTheme.surfaceDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: PosTheme.primaryGold, width: 1.5),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: PosTheme.statusSuccess.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: PosTheme.statusSuccess),
              ),
              child: const Icon(Icons.check, color: PosTheme.statusSuccess, size: 32),
            ),
            const SizedBox(height: 12),
            const Text(
              'REGISTER CLOSED (Z-REPORT)',
              style: TextStyle(color: PosTheme.textWhite, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.8),
            ),
            const SizedBox(height: 4),
            Text('Session closed and queued to ESC/POS thermal printer', style: TextStyle(color: PosTheme.textMuted, fontSize: 12)),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: PosTheme.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PosTheme.dividerDark),
                ),
                child: Column(
                  children: [
                    _buildRow('Opening Float', _currency.format(z.openingFloat)),
                    _buildRow('Gross Sales', _currency.format(z.grossSales)),
                    _buildRow('Expected Cash', _currency.format(z.expectedCash)),
                    _buildRow('Actual Cash', _currency.format(z.actualClosingCash ?? 0.0)),
                    _buildRow(
                      'Discrepancy',
                      (z.discrepancy ?? 0.0) >= 0 ? '+${_currency.format(z.discrepancy ?? 0.0)}' : _currency.format(z.discrepancy ?? 0.0),
                      color: z.isBalanced ? PosTheme.statusSuccess : PosTheme.statusError,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: PosTheme.primaryGold,
                  foregroundColor: const Color(0xFF111413),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                },
                child: const Text('LOCK TERMINAL', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: PosTheme.textMuted, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: color ?? PosTheme.textWhite,
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
