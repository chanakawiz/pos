import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme/pos_theme.dart';
import '../models/shift_session_report.dart';
import '../providers/pos_shift_provider.dart';

class CashMovementDialog extends ConsumerStatefulWidget {
  const CashMovementDialog({super.key});

  @override
  ConsumerState<CashMovementDialog> createState() => _CashMovementDialogState();
}

class _CashMovementDialogState extends ConsumerState<CashMovementDialog> {
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _reasonCtrl = TextEditingController(text: 'Mid-Shift Safe Cash Drop');
  final TextEditingController _notesCtrl = TextEditingController();
  final NumberFormat _currency = NumberFormat('#,##0.00');

  CashMovementType _selectedType = CashMovementType.cashOut;

  static const List<double> _presets = [1000, 5000, 10000, 25000];
  static const List<String> _presetReasons = [
    'Mid-Shift Safe Cash Drop',
    'Courier & Packaging Supplies',
    'Change Float Replenishment',
    'Store Petty Expense',
  ];

  @override
  void dispose() {
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _parsedAmount => double.tryParse(_amountCtrl.text.replaceAll(',', '').trim()) ?? 0.0;

  Future<void> _submitMovement() async {
    final amount = _parsedAmount;
    if (amount <= 0) return;

    final entry = await ref.read(posShiftProvider.notifier).recordCashMovement(
          type: _selectedType,
          amount: amount,
          reason: _reasonCtrl.text.trim().isNotEmpty ? _reasonCtrl.text.trim() : _selectedType.label,
          notes: _notesCtrl.text.trim(),
          printVoucher: true,
        );

    if (mounted && entry != null) {
      _amountCtrl.clear();
      _notesCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: PosTheme.primaryGold,
          behavior: SnackBarBehavior.floating,
          content: Text(
            '${entry.type.label} (${entry.type.sign}LKR ${_currency.format(entry.amount)}) recorded & voucher queued!',
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final shiftState = ref.watch(posShiftProvider);
    final currentExpected = shiftState.activeSummary?.expectedCash ?? 0.0;
    final previewExpected = (_selectedType.isInflow
            ? currentExpected + _parsedAmount
            : currentExpected - _parsedAmount)
        .clamp(0.0, double.infinity);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
        decoration: BoxDecoration(
          color: PosTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: PosTheme.primaryGold.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: const BoxDecoration(
                color: PosTheme.card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
                border: Border(bottom: BorderSide(color: PosTheme.border)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: PosTheme.accentAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.savings_outlined, color: PosTheme.accentAmber, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PETTY CASH & SAFE DROPS',
                          style: TextStyle(
                            color: PosTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          'Drawer Cash Out, Petty Expenses & Float Top-Ups',
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
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Type Selector
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: CashMovementType.values.map((t) {
                        final isSelected = _selectedType == t;
                        final accent = t.isInflow ? PosTheme.accentGreen : PosTheme.accentAmber;
                        return ChoiceChip(
                          label: Text(t.label),
                          selected: isSelected,
                          selectedColor: accent,
                          backgroundColor: PosTheme.card,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : PosTheme.textSecondary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                          onSelected: (_) {
                            setState(() {
                              _selectedType = t;
                              _reasonCtrl.text = t == CashMovementType.cashIn
                                  ? 'Change Float Replenishment'
                                  : (t == CashMovementType.pettyCash
                                      ? 'Courier & Packaging Supplies'
                                      : 'Mid-Shift Safe Cash Drop');
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Amount Input
                    TextField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(
                        color: PosTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Amount (LKR)',
                        prefixText: 'LKR ',
                        prefixStyle: TextStyle(color: PosTheme.primaryGold, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      children: _presets
                          .map(
                            (p) => ActionChip(
                              backgroundColor: PosTheme.card,
                              side: const BorderSide(color: PosTheme.border),
                              label: Text(
                                'LKR ${NumberFormat('#,##0').format(p)}',
                                style: const TextStyle(color: PosTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                              onPressed: () {
                                setState(() {
                                  _amountCtrl.text = p.toStringAsFixed(0);
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 14),

                    // Reason Chips & Field
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _presetReasons
                          .map(
                            (r) => ActionChip(
                              backgroundColor: PosTheme.card,
                              label: Text(r, style: const TextStyle(color: PosTheme.textSecondary, fontSize: 11)),
                              onPressed: () => setState(() => _reasonCtrl.text = r),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _reasonCtrl,
                      style: const TextStyle(color: PosTheme.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(labelText: 'Reason / Voucher Description', isDense: true),
                    ),
                    const SizedBox(height: 14),

                    // Live Impact Banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: PosTheme.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: PosTheme.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('CURRENT EXPECTED CASH', style: TextStyle(color: PosTheme.textMuted, fontSize: 10)),
                              Text(
                                'LKR ${_currency.format(currentExpected)}',
                                style: const TextStyle(color: PosTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const Icon(Icons.arrow_forward, color: PosTheme.primaryGold, size: 18),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('UPDATED DRAWER CASH', style: TextStyle(color: PosTheme.textMuted, fontSize: 10)),
                              Text(
                                'LKR ${_currency.format(previewExpected)}',
                                style: TextStyle(
                                  color: _selectedType.isInflow ? PosTheme.accentGreen : PosTheme.accentAmber,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      icon: const Icon(Icons.receipt_long_outlined, size: 18),
                      label: Text(
                        shiftState.isRecordingMovement
                            ? 'RECORDING MOVEMENT...'
                            : 'RECORD ${_selectedType.label.toUpperCase()} & PRINT',
                      ),
                      onPressed: shiftState.isRecordingMovement || _parsedAmount <= 0 ? null : _submitMovement,
                    ),

                    if (shiftState.movements.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      const Text(
                        'SHIFT CASH MOVEMENTS LEDGER',
                        style: TextStyle(
                          color: PosTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...shiftState.movements.map(
                        (m) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: PosTheme.card,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: PosTheme.border),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                m.type.isInflow ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                color: m.type.isInflow ? PosTheme.accentGreen : PosTheme.accentAmber,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      m.reason,
                                      style: const TextStyle(
                                        color: PosTheme.textPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      '${m.reference} • ${m.type.label}',
                                      style: const TextStyle(color: PosTheme.textMuted, fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${m.type.sign}LKR ${_currency.format(m.amount)}',
                                style: TextStyle(
                                  color: m.type.isInflow ? PosTheme.accentGreen : PosTheme.accentAmber,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
