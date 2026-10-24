import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/held_bill.dart';
import '../../../data/repositories/held_bill_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';

class HeldBillsModal extends ConsumerStatefulWidget {
  const HeldBillsModal({super.key});

  @override
  ConsumerState<HeldBillsModal> createState() => _HeldBillsModalState();
}

class _HeldBillsModalState extends ConsumerState<HeldBillsModal> {
  List<HeldBillModel> _bills = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHeldBills();
  }

  Future<void> _loadHeldBills() async {
    setState(() => _isLoading = true);
    final repo = ref.read(heldBillRepositoryProvider);
    final list = await repo.getHeldBills();
    if (mounted) {
      setState(() {
        _bills = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _recallBill(HeldBillModel bill) async {
    final cartNotifier = ref.read(cartProvider.notifier);
    final repo = ref.read(heldBillRepositoryProvider);

    // Populate active cart with held items
    cartNotifier.clearCart();
    for (final item in bill.items) {
      cartNotifier.addItem(
        item.product,
        quantity: item.quantity,
        serialNumber: item.serialNumber,
        warrantyNotes: item.warrantyNotes,
      );
    }

    // Delete held bill from server & local SQLite
    await repo.recallOrDeleteBill(bill.uuid);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recalled bill ${bill.holdReference} (${bill.itemsCount} items)'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _discardBill(HeldBillModel bill) async {
    final repo = ref.read(heldBillRepositoryProvider);
    await repo.recallOrDeleteBill(bill.uuid);
    _loadHeldBills();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currencySymbol = authState.user?.store?.currencySymbol ?? 'Rs.';

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.pause_circle_outline, color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('Held Bills (Parked Sales)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20, color: AppColors.textMuted),
            tooltip: 'Refresh',
            onPressed: _loadHeldBills,
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        height: 360,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _bills.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_outlined, size: 48, color: AppColors.textMuted.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        const Text(
                          'No held bills found',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Park bills to cloud for queue-busting',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _bills.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final b = _bills[i];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        b.holdReference,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${b.itemsCount} items',
                                          style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${b.customerName ?? "Walk-in"} • Cashier: ${b.cashierName}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Total: ${CurrencyFormatter.format(b.subtotal, symbol: currencySymbol)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                                  tooltip: 'Discard',
                                  onPressed: () => _discardBill(b),
                                ),
                                const SizedBox(width: 4),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.play_arrow, size: 16),
                                  label: const Text('Recall'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  onPressed: () => _recallBill(b),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close', style: TextStyle(color: AppColors.textSecondary)),
        ),
      ],
    );
  }
}
