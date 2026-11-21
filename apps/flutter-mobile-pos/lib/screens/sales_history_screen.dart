import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme/pos_theme.dart';
import '../models/sale_history_entry.dart';
import '../providers/pos_sales_history_provider.dart';
import '../services/esc_pos_service.dart';
import 'refund_dialog.dart';
import 'sync_status_ribbon.dart';

class SalesHistoryScreen extends ConsumerStatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  ConsumerState<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends ConsumerState<SalesHistoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final NumberFormat _currency = NumberFormat('#,##0.00');
  final DateFormat _dateFmt = DateFormat('MMM dd, HH:mm');

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openSaleDetails(SaleHistoryEntry sale) {
    final phoneCtrl = TextEditingController(text: sale.customerPhone ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PosTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          expand: false,
          builder: (_, scrollCtrl) {
            return SingleChildScrollView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sale.invoiceNumber,
                              style: const TextStyle(
                                color: PosTheme.primaryGold,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                            Text(
                              '${_dateFmt.format(sale.soldAt)} • ${sale.cashierName} (${sale.terminalCode})',
                              style: const TextStyle(color: PosTheme.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusBadge(sale),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (sale.customerName != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: PosTheme.primaryGold.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: PosTheme.primaryGold.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user, color: PosTheme.primaryGold, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sale.customerName!,
                                  style: const TextStyle(
                                    color: PosTheme.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                if (sale.customerPhone != null && sale.customerPhone!.isNotEmpty)
                                  Text(
                                    sale.customerPhone!,
                                    style: const TextStyle(color: PosTheme.textSecondary, fontSize: 11),
                                  ),
                              ],
                            ),
                          ),
                          if (sale.loyaltyPointsEarned > 0)
                            Text(
                              '+${sale.loyaltyPointsEarned} PTS',
                              style: const TextStyle(
                                color: PosTheme.primaryGold,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),

                  const Text(
                    'PURCHASED ITEMS',
                    style: TextStyle(
                      color: PosTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...sale.items.map(
                    (item) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: PosTheme.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: PosTheme.border),
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
                                  '${item.quantity} × LKR ${_currency.format(item.unitPrice)}${item.selectedVariant != null ? " • ${item.selectedVariant}" : ""}',
                                  style: const TextStyle(color: PosTheme.textSecondary, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'LKR ${_currency.format(item.total)}',
                            style: const TextStyle(
                              color: PosTheme.primaryGold,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(color: PosTheme.border, height: 24),

                  _summaryLine('Subtotal', 'LKR ${_currency.format(sale.subtotal)}'),
                  if (sale.discountAmount > 0)
                    _summaryLine('Discount', '-LKR ${_currency.format(sale.discountAmount)}', valueColor: PosTheme.accentGreen),
                  _summaryLine(
                    'Total Payable',
                    'LKR ${_currency.format(sale.totalAmount)}',
                    isBold: true,
                    valueColor: PosTheme.primaryGold,
                  ),
                  if (sale.isRefunded)
                    _summaryLine(
                      'Refunded (${sale.refundNumber ?? "REF"})',
                      '-LKR ${_currency.format(sale.refundedAmount)}',
                      valueColor: PosTheme.accentRed,
                    ),

                  if (sale.payments.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'TENDER BREAKDOWN',
                      style: TextStyle(
                        color: PosTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...sale.payments.map(
                      (p) => _summaryLine(
                        '${p.method.displayName}${p.reference != null ? " (${p.reference})" : ""}',
                        'LKR ${_currency.format(p.amount)}',
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // SMS Resend Bar
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: PosTheme.textPrimary, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'Mobile for SMS e-receipt (+94 77...)',
                            prefixIcon: Icon(Icons.sms_outlined, color: PosTheme.primaryGold, size: 18),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () async {
                          final phone = phoneCtrl.text.trim();
                          if (phone.isEmpty) return;
                          await ref.read(posSalesHistoryProvider.notifier).resendSmsReceipt(sale, phone: phone);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: PosTheme.accentGreen,
                                content: Text('SMS e-receipt dispatched to $phone'),
                              ),
                            );
                          }
                        },
                        child: const Text('SEND SMS'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Primary Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.print_outlined, size: 18),
                          label: const Text('REPRINT RECEIPT'),
                          onPressed: () {
                            ref.read(posSalesHistoryProvider.notifier).reprintReceipt(
                                  sale,
                                  width: PrinterPaperWidth.mm58,
                                );
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: PosTheme.primaryGold,
                                content: Text(
                                  'Receipt ${sale.invoiceNumber} queued to portable ESC/POS printer',
                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (!sale.isRefunded) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: PosTheme.accentRed,
                              side: const BorderSide(color: PosTheme.accentRed),
                            ),
                            icon: const Icon(Icons.assignment_return_outlined, size: 18),
                            label: const Text('PROCESS REFUND'),
                            onPressed: () {
                              Navigator.pop(ctx);
                              showDialog(
                                context: context,
                                barrierColor: Colors.black.withValues(alpha: 0.75),
                                builder: (_) => RefundDialog(initialSale: sale),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _summaryLine(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isBold ? PosTheme.textPrimary : PosTheme.textSecondary,
              fontSize: isBold ? 14 : 12,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? PosTheme.textPrimary,
              fontSize: isBold ? 15 : 13,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(SaleHistoryEntry sale) {
    Color color;
    String label;
    if (sale.isRefunded) {
      color = PosTheme.accentRed;
      label = 'REFUNDED';
    } else if (sale.isPending) {
      color = PosTheme.accentAmber;
      label = 'PENDING SYNC';
    } else {
      color = PosTheme.accentGreen;
      label = 'SYNCED';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(posSalesHistoryProvider);
    final sales = historyState.filteredSales;

    return Scaffold(
      backgroundColor: PosTheme.background,
      appBar: AppBar(
        backgroundColor: PosTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: PosTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SALES HISTORY & RECEIPTS',
              style: TextStyle(
                color: PosTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              'Reprint Slips • SMS Dispatch • Instant Refunds',
              style: TextStyle(color: PosTheme.textSecondary, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_return_outlined, color: PosTheme.accentAmber),
            tooltip: 'Lookup Invoice for Refund',
            onPressed: () {
              showDialog(
                context: context,
                barrierColor: Colors.black.withValues(alpha: 0.75),
                builder: (_) => const RefundDialog(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: PosTheme.primaryGold),
            tooltip: 'Refresh History',
            onPressed: () => ref.read(posSalesHistoryProvider.notifier).loadSales(),
          ),
        ],
      ),
      body: Column(
        children: [
          const SyncStatusRibbon(),
          Container(
            padding: const EdgeInsets.all(14),
            color: PosTheme.surface,
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: PosTheme.textPrimary, fontSize: 14),
                  onChanged: (v) => ref.read(posSalesHistoryProvider.notifier).setSearchQuery(v),
                  decoration: InputDecoration(
                    hintText: 'Search by invoice #, VIP customer, or mobile...',
                    prefixIcon: const Icon(Icons.search, color: PosTheme.primaryGold, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: PosTheme.textMuted, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              ref.read(posSalesHistoryProvider.notifier).setSearchQuery('');
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final entry in const [
                      ('all', 'All'),
                      ('synced', 'Synced'),
                      ('pending', 'Pending'),
                      ('refunded', 'Refunded'),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(entry.$2),
                          selected: historyState.statusFilter == entry.$1,
                          selectedColor: PosTheme.primaryGold,
                          backgroundColor: PosTheme.card,
                          labelStyle: TextStyle(
                            color: historyState.statusFilter == entry.$1 ? Colors.black : PosTheme.textSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                          onSelected: (_) => ref.read(posSalesHistoryProvider.notifier).setStatusFilter(entry.$1),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: historyState.isLoading
                ? const Center(child: CircularProgressIndicator(color: PosTheme.primaryGold))
                : sales.isEmpty
                    ? const Center(
                        child: Text(
                          'No matching transactions found.',
                          style: TextStyle(color: PosTheme.textSecondary, fontSize: 14),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(14),
                        itemCount: sales.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final sale = sales[index];
                          return InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _openSaleDetails(sale),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: PosTheme.card,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: PosTheme.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        sale.invoiceNumber,
                                        style: const TextStyle(
                                          color: PosTheme.primaryGold,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                      _buildStatusBadge(sale),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${sale.totalQuantity} items • ${_dateFmt.format(sale.soldAt)}',
                                        style: const TextStyle(color: PosTheme.textSecondary, fontSize: 12),
                                      ),
                                      Text(
                                        'LKR ${_currency.format(sale.totalAmount)}',
                                        style: const TextStyle(
                                          color: PosTheme.textPrimary,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (sale.customerName != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'VIP: ${sale.customerName} (${sale.customerPhone ?? ""})',
                                      style: const TextStyle(color: PosTheme.textMuted, fontSize: 11),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
