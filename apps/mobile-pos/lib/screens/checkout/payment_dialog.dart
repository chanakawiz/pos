import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/sale.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/sync_provider.dart';
import '../receipt/receipt_screen.dart';

class PaymentDialog extends ConsumerStatefulWidget {
  final VoidCallback? onComplete;

  const PaymentDialog({super.key, this.onComplete});

  @override
  ConsumerState<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<PaymentDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _cashReceivedController = TextEditingController();
  final TextEditingController _refNumberController = TextEditingController();

  PaymentMethod _selectedMethod = PaymentMethod.cash;
  double _cashReceived = 0.0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        if (_tabController.index == 0) {
          _selectedMethod = PaymentMethod.cash;
        } else if (_tabController.index == 1) {
          _selectedMethod = PaymentMethod.card;
        } else {
          _selectedMethod = PaymentMethod.bankTransfer;
        }
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final total = ref.read(cartProvider).grandTotal;
      setState(() {
        _cashReceived = total;
        _cashReceivedController.text = total.toStringAsFixed(2);
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cashReceivedController.dispose();
    _refNumberController.dispose();
    super.dispose();
  }

  void _addCash(double amount) {
    setState(() {
      _cashReceived += amount;
      _cashReceivedController.text = _cashReceived.toStringAsFixed(2);
    });
  }

  void _setExactCash(double total) {
    setState(() {
      _cashReceived = total;
      _cashReceivedController.text = _cashReceived.toStringAsFixed(2);
    });
  }

  void _roundUpToNext(double step, double total) {
    final next = (total / step).ceil() * step;
    setState(() {
      _cashReceived = next;
      _cashReceivedController.text = _cashReceived.toStringAsFixed(2);
    });
  }

  Future<void> _completeCheckout() async {
    final cartState = ref.read(cartProvider);
    final authState = ref.read(authProvider);
    final salesRepo = ref.read(salesRepositoryProvider);

    if (cartState.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    final total = cartState.grandTotal;
    final paidAmount = _selectedMethod == PaymentMethod.cash ? _cashReceived : total;
    final changeAmount = _selectedMethod == PaymentMethod.cash && _cashReceived > total
        ? (_cashReceived - total)
        : 0.0;

    final timestamp = DateTime.now();
    final randomSuffix = (1000 + (timestamp.millisecond % 9000)).toString();
    final invoiceNumber =
        'INV-${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}-$randomSuffix';

    final sale = SaleModel(
      transactionUuid: const Uuid().v4(),
      invoiceNumber: invoiceNumber,
      cashierUuid: authState.user?.uuid ?? 'offline-cashier',
      cashierName: authState.user?.name ?? 'Cashier',
      customerUuid: cartState.customer?.uuid,
      customerName: cartState.customer?.name,
      storeUuid: authState.user?.store?.uuid ?? 'offline-store',
      deviceUuid: authState.deviceUuid ?? 'mobile-device',
      subtotal: cartState.subtotal,
      discountAmount: cartState.billDiscount,
      taxAmount: cartState.taxTotal,
      totalAmount: total,
      paidAmount: paidAmount,
      changeAmount: changeAmount,
      soldAt: timestamp,
      items: List.from(cartState.items),
      payments: [
        PaymentModel(
          method: _selectedMethod,
          amount: total,
          referenceNumber: _refNumberController.text.trim().isNotEmpty
              ? _refNumberController.text.trim()
              : null,
        ),
      ],
      syncStatus: 'pending',
    );

    // Commit atomically to local SQLite
    await salesRepo.createSale(sale);

    // Trigger background sync in non-blocking manner
    ref.read(syncProvider.notifier).syncNow();

    // Clear cart state
    ref.read(cartProvider.notifier).clearCart();

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
    });

    Navigator.pop(context); // Close payment dialog

    if (widget.onComplete != null) {
      widget.onComplete!();
    }

    // Open bilingual receipt screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ReceiptScreen(sale: sale),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final authState = ref.watch(authProvider);
    final currencySymbol = authState.user?.store?.currencySymbol ?? 'Rs.';
    final total = cartState.grandTotal;

    final change = _cashReceived - total;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Banner: Total Due
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Total Payable',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(total, symbol: currencySymbol),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Payment Method Tabs
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(icon: Icon(Icons.money), text: 'Cash'),
                Tab(icon: Icon(Icons.credit_card), text: 'Card'),
                Tab(icon: Icon(Icons.account_balance), text: 'Bank Transfer'),
              ],
            ),

            // Tab Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (_selectedMethod == PaymentMethod.cash) ...[
                    // Cash Input
                    TextField(
                      controller: _cashReceivedController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Cash Received ($currencySymbol)',
                        prefixIcon: const Icon(Icons.payments, color: AppColors.primary),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _cashReceived = double.tryParse(val) ?? 0.0;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Quick Bill Buttons
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          label: const Text('Exact'),
                          backgroundColor: AppColors.card,
                          labelStyle: const TextStyle(color: AppColors.textPrimary),
                          onPressed: () => _setExactCash(total),
                        ),
                        ActionChip(
                          label: const Text('+1,000'),
                          backgroundColor: AppColors.card,
                          labelStyle: const TextStyle(color: AppColors.textPrimary),
                          onPressed: () => _addCash(1000),
                        ),
                        ActionChip(
                          label: const Text('+5,000'),
                          backgroundColor: AppColors.card,
                          labelStyle: const TextStyle(color: AppColors.textPrimary),
                          onPressed: () => _addCash(5000),
                        ),
                        ActionChip(
                          label: const Text('Next 1,000'),
                          backgroundColor: AppColors.card,
                          labelStyle: const TextStyle(color: AppColors.textPrimary),
                          onPressed: () => _roundUpToNext(1000, total),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Change Calculation Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: change >= 0
                            ? AppColors.primary.withOpacity(0.12)
                            : AppColors.danger.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: change >= 0
                              ? AppColors.primary.withOpacity(0.4)
                              : AppColors.danger.withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            change >= 0 ? 'Change to Return:' : 'Remaining Due:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: change >= 0 ? AppColors.primary : AppColors.danger,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(change.abs(), symbol: currencySymbol),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: change >= 0 ? AppColors.primary : AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Reference / Slip Number Input for Card / Transfer
                    TextField(
                      controller: _refNumberController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: _selectedMethod == PaymentMethod.card
                            ? 'Card Auth / Approval Code'
                            : 'Bank Reference / Transaction ID',
                        hintText: 'e.g. TXN-8829103',
                        prefixIcon: Icon(
                          _selectedMethod == PaymentMethod.card
                              ? Icons.credit_score
                              : Icons.receipt_long,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedMethod == PaymentMethod.card
                          ? 'Swipe/tap terminal and enter authorization code if available.'
                          : 'Enter the online bank transfer reference or slip number.',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ],
              ),
            ),

            // Dialog Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isProcessing ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: (_isProcessing ||
                              (_selectedMethod == PaymentMethod.cash && change < 0))
                          ? null
                          : _completeCheckout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline, size: 20),
                                SizedBox(width: 6),
                                Text(
                                  'Complete Sale',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
