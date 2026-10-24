import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/sale.dart';
import '../../../providers/auth_provider.dart';

class ReceiptScreen extends ConsumerWidget {
  final SaleModel sale;

  const ReceiptScreen({super.key, required this.sale});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final store = authState.user?.store;
    final currencySymbol = store?.currencySymbol ?? 'Rs.';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Preview'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Print Receipt',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sent to thermal receipt printer...'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                // Success Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 18, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'Payment Successful',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Receipt Paper Container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Color(0xFF1E293B),
                      fontSize: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Store Header
                        Center(
                          child: Column(
                            children: [
                              Text(
                                store?.receiptHeader ?? 'ස්මාර්ට්ෂොප් වෙළඳසැල / SMARTSHOP',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                store?.name ?? 'Main Store',
                                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                              ),
                              if (store?.address != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  store!.address!,
                                  style: const TextStyle(color: Colors.black54, fontSize: 11),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                              if (store?.phone != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Tel: ${store!.phone!}',
                                  style: const TextStyle(color: Colors.black54, fontSize: 11),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('------------------------------------------', textAlign: TextAlign.center),
                        const SizedBox(height: 8),

                        // Metadata
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Invoice / බිල්පත් අංකය:'),
                            Text(sale.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Date / දිනය:'),
                            Text(sale.soldAt.toString().substring(0, 16)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Cashier / අයකැමි:'),
                            Text(sale.cashierName),
                          ],
                        ),
                        if (sale.customerName != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Customer / පාරිභෝගිකයා:'),
                              Text(sale.customerName!),
                            ],
                          ),
                        ],

                        const SizedBox(height: 8),
                        const Text('------------------------------------------', textAlign: TextAlign.center),
                        const SizedBox(height: 8),

                        // Column Headers
                        const Row(
                          children: [
                            Expanded(flex: 3, child: Text('ITEM / අයිතමය', style: TextStyle(fontWeight: FontWeight.bold))),
                            Expanded(flex: 1, child: Text('QTY', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                            Expanded(flex: 2, child: Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Item Lines
                        ...sale.items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                          if (item.product.sinhalaName != null &&
                                              item.product.sinhalaName!.isNotEmpty)
                                            Text(
                                              item.product.sinhalaName!,
                                              style: const TextStyle(fontSize: 10, color: Colors.black54),
                                            ),
                                          if (item.serialNumber != null && item.serialNumber!.isNotEmpty)
                                            Text(
                                              'SN: ${item.serialNumber}',
                                              style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontWeight: FontWeight.bold),
                                            ),
                                          if (item.warrantyNotes != null && item.warrantyNotes!.isNotEmpty)
                                            Text(
                                              'Warranty: ${item.warrantyNotes}',
                                              style: const TextStyle(fontSize: 10, color: Colors.indigo),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        CurrencyFormatter.formatQuantity(item.quantity),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        CurrencyFormatter.format(item.total, symbol: currencySymbol),
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),

                        const Text('------------------------------------------', textAlign: TextAlign.center),
                        const SizedBox(height: 6),

                        // Totals
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal / උප එකතුව:'),
                            Text(CurrencyFormatter.format(sale.subtotal, symbol: currencySymbol)),
                          ],
                        ),
                        if (sale.discountAmount > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Discount / වට්ටම:'),
                              Text('- ${CurrencyFormatter.format(sale.discountAmount, symbol: currencySymbol)}'),
                            ],
                          ),
                        ],
                        if (sale.taxAmount > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Tax (VAT) / බදු:'),
                              Text(CurrencyFormatter.format(sale.taxAmount, symbol: currencySymbol)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('TOTAL / මුළු එකතුව:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            Text(
                              CurrencyFormatter.format(sale.totalAmount, symbol: currencySymbol),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Paid / ගෙවූ මුදල:'),
                            Text(CurrencyFormatter.format(sale.paidAmount, symbol: currencySymbol)),
                          ],
                        ),
                        if (sale.changeAmount > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Change / ඉතිරි මුදල:'),
                              Text(CurrencyFormatter.format(sale.changeAmount, symbol: currencySymbol)),
                            ],
                          ),
                        ],

                        const SizedBox(height: 12),
                        const Text('==========================================', textAlign: TextAlign.center),
                        const SizedBox(height: 8),

                        // Sinhala & English Blessings
                        Center(
                          child: Column(
                            children: [
                              const Text(
                                'ස්තූතියි! නැවත එන්න.',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                store?.receiptFooter ?? 'Thank you! Please visit again.',
                                style: const TextStyle(fontSize: 11, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Return to POS Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Start New Sale', style: TextStyle(fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
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
