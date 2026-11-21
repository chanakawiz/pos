import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme/pos_theme.dart';
import '../models/sale_history_entry.dart';
import '../providers/pos_sales_history_provider.dart';
import '../services/esc_pos_service.dart';

class RefundDialog extends ConsumerStatefulWidget {
  final SaleHistoryEntry? initialSale;

  const RefundDialog({super.key, this.initialSale});

  @override
  ConsumerState<RefundDialog> createState() => _RefundDialogState();
}

class _RefundDialogState extends ConsumerState<RefundDialog> {
  final TextEditingController _invoiceCtrl = TextEditingController();
  final TextEditingController _reasonCtrl = TextEditingController(text: 'Size / Fit Exchange');
  final NumberFormat _currency = NumberFormat('#,##0.00');

  SaleHistoryEntry? _selectedSale;
  final Map<String, int> _returnQuantities = {};
  bool _restockInventory = true;
  bool _isSearching = false;
  String? _lookupError;
  RefundRecord? _completedRefund;

  static const List<String> _presetReasons = [
    'Size / Fit Exchange',
    'Defective / Damaged',
    'Customer Changed Mind',
    'Wrong Item Scanned',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialSale != null) {
      _selectSale(widget.initialSale!);
    }
  }

  @override
  void dispose() {
    _invoiceCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  void _selectSale(SaleHistoryEntry sale) {
    setState(() {
      _selectedSale = sale;
      _invoiceCtrl.text = sale.invoiceNumber;
      _lookupError = null;
      _returnQuantities.clear();
      for (final item in sale.items) {
        _returnQuantities[item.uuid] = item.quantity;
      }
    });
  }

  Future<void> _lookupInvoice() async {
    final query = _invoiceCtrl.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _lookupError = null;
    });

    final found = await ref.read(posSalesHistoryProvider.notifier).lookupSale(query);
    if (!mounted) return;

    if (found != null) {
      _selectSale(found);
      setState(() => _isSearching = false);
    } else {
      setState(() {
        _isSearching = false;
        _lookupError = 'Invoice "$query" not found in local or cloud records.';
      });
    }
  }

  double get _totalRefundAmount {
    if (_selectedSale == null) return 0.0;
    double sum = 0.0;
    for (final item in _selectedSale!.items) {
      final qty = _returnQuantities[item.uuid] ?? 0;
      sum += qty * item.unitPrice;
    }
    return sum;
  }

  Future<void> _submitRefund() async {
    final sale = _selectedSale;
    if (sale == null) return;

    final lines = sale.items
        .where((i) => (_returnQuantities[i.uuid] ?? 0) > 0)
        .map(
          (i) => RefundItemLine(
            saleItemId: i.id,
            saleItemUuid: i.uuid,
            productName: i.productName,
            quantity: _returnQuantities[i.uuid] ?? 0,
            unitPrice: i.unitPrice,
          ),
        )
        .toList();

    if (lines.isEmpty) {
      setState(() => _lookupError = 'Select at least 1 unit to refund.');
      return;
    }

    final record = await ref.read(posSalesHistoryProvider.notifier).processRefund(
          sale: sale,
          items: lines,
          reason: _reasonCtrl.text.trim().isNotEmpty ? _reasonCtrl.text.trim() : 'Customer Return',
          restock: _restockInventory,
          printReceipt: true,
        );

    if (mounted && record != null) {
      setState(() => _completedRefund = record);
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(posSalesHistoryProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 680),
        decoration: BoxDecoration(
          color: PosTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: PosTheme.accentRed.withValues(alpha: 0.45), width: 1.5),
        ),
        child: _completedRefund != null
            ? _buildSuccessView(_completedRefund!)
            : Column(
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
                            color: PosTheme.accentRed.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.assignment_return_outlined, color: PosTheme.accentRed, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'IN-STORE REFUND & EXCHANGE',
                                style: TextStyle(
                                  color: PosTheme.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Text(
                                'Itemized Return • Inventory Restock • Voucher Print',
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
                          // Invoice Search Row
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _invoiceCtrl,
                                  style: const TextStyle(color: PosTheme.textPrimary, fontSize: 13),
                                  decoration: const InputDecoration(
                                    hintText: 'Enter Invoice # (e.g. INV-2026-8841)',
                                    prefixIcon: Icon(Icons.receipt_long, color: PosTheme.primaryGold, size: 18),
                                    isDense: true,
                                  ),
                                  onSubmitted: (_) => _lookupInvoice(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _isSearching ? null : _lookupInvoice,
                                child: const Text('FIND'),
                              ),
                            ],
                          ),

                          if (_selectedSale == null && historyState.sales.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Text(
                              'RECENT INVOICES (1-TAP SELECT)',
                              style: TextStyle(
                                color: PosTheme.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: historyState.sales
                                  .where((s) => !s.isRefunded)
                                  .take(4)
                                  .map(
                                    (s) => ActionChip(
                                      backgroundColor: PosTheme.card,
                                      side: const BorderSide(color: PosTheme.border),
                                      label: Text(
                                        '${s.invoiceNumber} • LKR ${_currency.format(s.totalAmount)}',
                                        style: const TextStyle(color: PosTheme.primaryGold, fontSize: 11),
                                      ),
                                      onPressed: () => _selectSale(s),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],

                          if (_lookupError != null) ...[
                            const SizedBox(height: 10),
                            Text(_lookupError!, style: const TextStyle(color: PosTheme.accentRed, fontSize: 12)),
                          ],

                          if (_selectedSale != null) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'SELECT ITEMS TO RETURN',
                              style: TextStyle(
                                color: PosTheme.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._selectedSale!.items.map((item) {
                              final qty = _returnQuantities[item.uuid] ?? 0;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: PosTheme.card,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: qty > 0 ? PosTheme.accentRed.withValues(alpha: 0.6) : PosTheme.border,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.productName,
                                            style: const TextStyle(
                                              color: PosTheme.textPrimary,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            'Purchased: ${item.quantity} × LKR ${_currency.format(item.unitPrice)}',
                                            style: const TextStyle(color: PosTheme.textSecondary, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline, size: 20, color: PosTheme.textSecondary),
                                          onPressed: qty > 0
                                              ? () => setState(() => _returnQuantities[item.uuid] = qty - 1)
                                              : null,
                                        ),
                                        Text(
                                          '$qty',
                                          style: const TextStyle(
                                            color: PosTheme.textPrimary,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline, size: 20, color: PosTheme.accentRed),
                                          onPressed: qty < item.quantity
                                              ? () => setState(() => _returnQuantities[item.uuid] = qty + 1)
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),

                            const SizedBox(height: 12),
                            const Text(
                              'RETURN REASON',
                              style: TextStyle(
                                color: PosTheme.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: _presetReasons
                                  .map(
                                    (r) => ChoiceChip(
                                      label: Text(r),
                                      selected: _reasonCtrl.text == r,
                                      selectedColor: PosTheme.primaryGold,
                                      backgroundColor: PosTheme.card,
                                      labelStyle: TextStyle(
                                        color: _reasonCtrl.text == r ? Colors.black : PosTheme.textSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      onSelected: (_) => setState(() => _reasonCtrl.text = r),
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _reasonCtrl,
                              style: const TextStyle(color: PosTheme.textPrimary, fontSize: 13),
                              decoration: const InputDecoration(
                                hintText: 'Return / exchange notes...',
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              activeColor: PosTheme.accentGreen,
                              title: const Text(
                                'Restock Items to Branch Inventory',
                                style: TextStyle(color: PosTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              subtitle: const Text(
                                'Disable for defective / unsellable goods',
                                style: TextStyle(color: PosTheme.textMuted, fontSize: 11),
                              ),
                              value: _restockInventory,
                              onChanged: (v) => setState(() => _restockInventory = v),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: PosTheme.accentRed.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: PosTheme.accentRed.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'TOTAL REFUND AMOUNT',
                                    style: TextStyle(
                                      color: PosTheme.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    'LKR ${_currency.format(_totalRefundAmount)}',
                                    style: const TextStyle(
                                      color: PosTheme.accentRed,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Bottom CTA
                  if (_selectedSale != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: PosTheme.card,
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(19)),
                        border: Border(top: BorderSide(color: PosTheme.border)),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PosTheme.accentRed,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: Text(
                            historyState.isProcessingRefund
                                ? 'PROCESSING REFUND...'
                                : 'CONFIRM REFUND & PRINT VOUCHER',
                          ),
                          onPressed: historyState.isProcessingRefund || _totalRefundAmount <= 0
                              ? null
                              : _submitRefund,
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildSuccessView(RefundRecord refund) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.check_circle_rounded, color: PosTheme.accentGreen, size: 54),
          const SizedBox(height: 12),
          const Text(
            'REFUND COMPLETED',
            textAlign: TextAlign.center,
            style: TextStyle(color: PosTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'Voucher ${refund.refundNumber} • Orig ${refund.invoiceNumber}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: PosTheme.primaryGold, fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: PosTheme.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: PosTheme.border),
            ),
            child: Column(
              children: [
                Text(
                  'LKR ${_currency.format(refund.totalRefunded)}',
                  style: const TextStyle(color: PosTheme.accentRed, fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  refund.restocked ? 'Returned units restocked to inventory' : 'Marked non-restockable (defective)',
                  style: const TextStyle(color: PosTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            icon: const Icon(Icons.print_outlined, size: 18),
            label: const Text('REPRINT REFUND VOUCHER'),
            onPressed: () {
              EscPosService.buildRefundReceiptBytes(refund, width: PrinterPaperWidth.mm58);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refund voucher sent to portable ESC/POS printer')),
              );
            },
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('DONE'),
          ),
        ],
      ),
    );
  }
}
