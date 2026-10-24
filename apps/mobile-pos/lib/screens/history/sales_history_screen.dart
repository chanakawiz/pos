import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/printer/printer_service.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/sale.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';
import '../receipt/receipt_screen.dart';

class SalesHistoryScreen extends ConsumerStatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  ConsumerState<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends ConsumerState<SalesHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<SaleModel> _sales = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // 'all', 'synced', 'pending'

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSales({String? search}) async {
    setState(() => _isLoading = true);
    final salesRepo = ref.read(salesRepositoryProvider);
    final result = await salesRepo.getRecentSales(search: search);
    if (mounted) {
      setState(() {
        _sales = result;
        _isLoading = false;
      });
    }
  }

  List<SaleModel> get _filteredSales {
    if (_selectedFilter == 'synced') {
      return _sales.where((s) => s.syncStatus == 'synced').toList();
    } else if (_selectedFilter == 'pending') {
      return _sales.where((s) => s.syncStatus == 'pending').toList();
    }
    return _sales;
  }

  void _showSaleDetails(SaleModel sale) {
    final authState = ref.read(authProvider);
    final store = authState.user?.store;
    final currencySymbol = store?.currencySymbol ?? 'Rs.';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pull handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Invoice
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sale.invoiceNumber,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sale.soldAt.toString().substring(0, 16),
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: sale.syncStatus == 'synced'
                        ? AppColors.synced.withOpacity(0.15)
                        : AppColors.pending.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        sale.syncStatus == 'synced' ? Icons.check_circle : Icons.cloud_upload,
                        size: 14,
                        color: sale.syncStatus == 'synced' ? AppColors.synced : AppColors.pending,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        sale.syncStatus.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: sale.syncStatus == 'synced' ? AppColors.synced : AppColors.pending,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 12),

            // Customer & Cashier Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Customer: ${sale.customerName ?? "Walk-in"}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                Text(
                  'Cashier: ${sale.cashierName}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Item count & Totals
            Text(
              'Items (${sale.items.length}):',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),

            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: sale.items.length,
                itemBuilder: (ctx, i) {
                  final it = sale.items[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${it.product.name} x${CurrencyFormatter.formatQuantity(it.quantity)}',
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(it.total, symbol: currencySymbol),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 12),

            // Grand Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Grand Total:',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Text(
                  CurrencyFormatter.format(sale.totalAmount, symbol: currencySymbol),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Action Buttons: Reprint & View Full Receipt
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.print, size: 18),
                    label: const Text('Reprint'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      final success = await PrinterService.instance.printSaleReceipt(sale, store);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Receipt reprinted (${PrinterService.instance.type.toUpperCase()})'
                                : 'Printer unreachable (${PrinterService.instance.host}:${PrinterService.instance.port})',
                          ),
                          backgroundColor: success ? AppColors.primary : AppColors.danger,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.receipt_long, size: 18),
                    label: const Text('View Receipt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => ReceiptScreen(sale: sale),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currencySymbol = authState.user?.store?.currencySymbol ?? 'Rs.';
    final filtered = _filteredSales;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sales & Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload Sales',
            onPressed: () => _loadSales(search: _searchController.text),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search by invoice or customer...',
                      prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppColors.textMuted),
                              onPressed: () {
                                _searchController.clear();
                                _loadSales();
                              },
                            )
                          : null,
                    ),
                    onSubmitted: (val) => _loadSales(search: val),
                  ),
                ),
              ],
            ),
          ),

          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ChoiceChip(
                  label: Text('All (${_sales.length})'),
                  selected: _selectedFilter == 'all',
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  labelStyle: TextStyle(
                    color: _selectedFilter == 'all' ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  onSelected: (_) => setState(() => _selectedFilter = 'all'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text('Synced (${_sales.where((s) => s.syncStatus == "synced").length})'),
                  selected: _selectedFilter == 'synced',
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  labelStyle: TextStyle(
                    color: _selectedFilter == 'synced' ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  onSelected: (_) => setState(() => _selectedFilter = 'synced'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text('Pending (${_sales.where((s) => s.syncStatus == "pending").length})'),
                  selected: _selectedFilter == 'pending',
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  labelStyle: TextStyle(
                    color: _selectedFilter == 'pending' ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  onSelected: (_) => setState(() => _selectedFilter = 'pending'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Sales List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_outlined, size: 48, color: AppColors.textMuted.withOpacity(0.5)),
                            const SizedBox(height: 12),
                            const Text(
                              'No transactions found',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 15),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final sale = filtered[i];
                          final isSynced = sale.syncStatus == 'synced';
                          final methodStr = sale.payments.isNotEmpty
                              ? sale.payments.first.method.name.toUpperCase()
                              : 'CASH';

                          return Material(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _showSaleDetails(sale),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    // Payment Method Icon Avatar
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppColors.card,
                                      child: Icon(
                                        methodStr == 'CARD'
                                            ? Icons.credit_card
                                            : (methodStr == 'BANKTRANSFER'
                                                ? Icons.account_balance
                                                : Icons.payments_outlined),
                                        size: 20,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Invoice & Meta
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                sale.invoiceNumber,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Icon(
                                                isSynced ? Icons.check_circle : Icons.cloud_upload,
                                                size: 13,
                                                color: isSynced ? AppColors.synced : AppColors.pending,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${sale.customerName ?? "Walk-in"} • ${sale.soldAt.toString().substring(11, 16)}',
                                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Amount & Items
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          CurrencyFormatter.format(sale.totalAmount, symbol: currencySymbol),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${sale.items.length} items',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textMuted),
                                  ],
                                ),
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
