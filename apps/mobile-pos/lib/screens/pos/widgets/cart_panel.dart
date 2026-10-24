import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/customer.dart';
import '../../../data/repositories/held_bill_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/catalog_provider.dart';
import '../../checkout/payment_dialog.dart';
import 'cart_item_tile.dart';
import 'held_bills_modal.dart';
import 'new_customer_dialog.dart';

class CartPanel extends ConsumerWidget {
  final VoidCallback? onCheckoutComplete;

  const CartPanel({super.key, this.onCheckoutComplete});

  void _showCustomerPicker(BuildContext context, WidgetRef ref) async {
    final catalogRepo = ref.read(catalogRepositoryProvider);
    final searchController = TextEditingController();
    List<CustomerModel> searchResults = await catalogRepo.getCustomers('');

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Select Customer', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchController,
                  autofocus: true,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Search by name or phone...',
                    prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
                  ),
                  onChanged: (val) async {
                    final res = await catalogRepo.getCustomers(val);
                    setDialogState(() {
                      searchResults = res;
                    });
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.card,
                    child: Icon(Icons.person_outline, color: AppColors.textPrimary),
                  ),
                  title: const Text('Walk-in Customer', style: TextStyle(color: AppColors.textPrimary)),
                  subtitle: const Text('Default cash checkout', style: TextStyle(color: AppColors.textMuted)),
                  onTap: () {
                    ref.read(cartProvider.notifier).setCustomer(null);
                    Navigator.pop(ctx);
                  },
                ),
                const Divider(color: AppColors.border),
                SizedBox(
                  height: 200,
                  child: searchResults.isEmpty
                      ? const Center(
                          child: Text('No customers found', style: TextStyle(color: AppColors.textMuted)),
                        )
                      : ListView.builder(
                          itemCount: searchResults.length,
                          itemBuilder: (ctx, i) {
                            final c = searchResults[i];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.secondary.withOpacity(0.2),
                                child: Text(
                                  c.name.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(c.name, style: const TextStyle(color: AppColors.textPrimary)),
                              subtitle: Text(c.phone ?? 'No phone', style: const TextStyle(color: AppColors.textMuted)),
                              trailing: c.loyaltyPoints > 0
                                  ? Chip(
                                      label: Text('${c.loyaltyPoints} pts', style: const TextStyle(fontSize: 11)),
                                      backgroundColor: AppColors.accent.withOpacity(0.15),
                                      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                                    )
                                  : null,
                              onTap: () {
                                ref.read(cartProvider.notifier).setCustomer(c);
                                Navigator.pop(ctx);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                final newCustomer = await showDialog<CustomerModel>(
                  context: context,
                  builder: (_) => const NewCustomerDialog(),
                );
                if (newCustomer != null) {
                  ref.read(cartProvider.notifier).setCustomer(newCustomer);
                }
              },
              icon: const Icon(Icons.person_add, size: 16),
              label: const Text('New Customer'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDiscountDialog(BuildContext context, WidgetRef ref) {
    final discountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Apply Bill Discount', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: discountController,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Discount Amount (Rs.)',
            prefixIcon: Icon(Icons.discount, color: AppColors.accent),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(discountController.text.trim()) ?? 0.0;
              ref.read(cartProvider.notifier).setBillDiscount(val);
              Navigator.pop(ctx);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final authState = ref.watch(authProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final currencySymbol = authState.user?.store?.currencySymbol ?? 'Rs.';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(left: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        children: [
          // Header Customer Selector & Held Bills
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.background,
              border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Customer Button
                InkWell(
                  onTap: () => _showCustomerPicker(context, ref),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: AppColors.secondary),
                        const SizedBox(width: 6),
                        Text(
                          cartState.customer != null
                              ? cartState.customer!.name
                              : 'Walk-in Customer',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),

                // Held Bills trigger
                IconButton(
                  tooltip: 'Held Bills (Parked Sales)',
                  icon: const Icon(Icons.pause_circle_outline, color: AppColors.accent),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => const HeldBillsModal(),
                    );
                  },
                ),
              ],
            ),
          ),

          // Cart Items List
          Expanded(
            child: cartState.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 48,
                          color: AppColors.textMuted.withOpacity(0.5),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Cart is empty',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tap products or scan barcode',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: cartState.items.length,
                    itemBuilder: (ctx, i) => CartItemTile(item: cartState.items[i]),
                  ),
          ),

          // Bottom Pricing Breakdown & Actions
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppColors.background,
              border: Border(top: BorderSide(color: AppColors.border, width: 1)),
            ),
            child: Column(
              children: [
                // Subtotal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => _showDiscountDialog(context, ref),
                      borderRadius: BorderRadius.circular(4),
                      child: const Row(
                        children: [
                          Text('Subtotal', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          SizedBox(width: 4),
                          Icon(Icons.discount_outlined, size: 13, color: AppColors.accent),
                        ],
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(cartState.subtotal, symbol: currencySymbol),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),

                // Bill Discount
                if (cartState.billDiscount > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Discount', style: TextStyle(color: AppColors.accent, fontSize: 13)),
                      Text(
                        '- ${CurrencyFormatter.format(cartState.billDiscount, symbol: currencySymbol)}',
                        style: const TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],

                // Tax
                if (cartState.taxTotal > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('VAT / Tax', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      Text(
                        CurrencyFormatter.format(cartState.taxTotal, symbol: currencySymbol),
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: AppColors.border, height: 1),
                ),

                // Grand Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(cartState.grandTotal, symbol: currencySymbol),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Action Row
                Row(
                  children: [
                    // Hold Button
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: cartState.isEmpty
                            ? null
                            : () async {
                                final authState = ref.read(authProvider);
                                final repo = ref.read(heldBillRepositoryProvider);
                                final bill = await repo.holdBill(
                                  items: List.from(cartState.items),
                                  subtotal: cartState.subtotal,
                                  cashierName: authState.user?.name ?? 'Cashier',
                                  customer: cartState.customer,
                                );
                                cartNotifier.clearCart();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Bill parked (${bill.holdReference}) to cloud & local queue'),
                                      backgroundColor: AppColors.accent,
                                    ),
                                  );
                                }
                              },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Hold', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Clear Button
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: cartState.isEmpty ? null : () => cartNotifier.clearCart(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          foregroundColor: AppColors.danger,
                        ),
                        child: const Text('Clear', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Checkout / Pay Button
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: cartState.isEmpty
                            ? null
                            : () {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (ctx) => PaymentDialog(
                                    onComplete: () {
                                      if (onCheckoutComplete != null) {
                                        onCheckoutComplete!();
                                      }
                                    },
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.payment, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Pay (${cartState.totalItemCount})',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
