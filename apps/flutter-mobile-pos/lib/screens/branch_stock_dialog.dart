import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/pos_theme.dart';
import '../models/branch_stock.dart';
import '../models/pos_product.dart';
import '../providers/pos_branch_stock_provider.dart';
import '../providers/pos_catalog_provider.dart';

class BranchStockDialog extends ConsumerStatefulWidget {
  final PosProduct? initialProduct;

  const BranchStockDialog({super.key, this.initialProduct});

  @override
  ConsumerState<BranchStockDialog> createState() => _BranchStockDialogState();
}

class _BranchStockDialogState extends ConsumerState<BranchStockDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final product = widget.initialProduct ??
          (ref.read(posCatalogProvider).products.isNotEmpty
              ? ref.read(posCatalogProvider).products.first
              : null);
      if (product != null) {
        ref.read(posBranchStockProvider.notifier).lookupProductStock(product);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stockState = ref.watch(posBranchStockProvider);
    final catalog = ref.watch(posCatalogProvider).products;

    final matches = _query.trim().isEmpty
        ? catalog.take(6).toList()
        : catalog.where((p) {
            final q = _query.trim().toLowerCase();
            return p.name.toLowerCase().contains(q) ||
                p.sku.toLowerCase().contains(q) ||
                p.barcode.toLowerCase().contains(q);
          }).take(6).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 670),
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
                      color: PosTheme.primaryGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.store_mall_directory_outlined, color: PosTheme.primaryGold, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CROSS-BRANCH STOCK LOCATOR',
                          style: TextStyle(
                            color: PosTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          'Live Inventory Across All OmniLuxe Boutiques',
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

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: PosTheme.textPrimary, fontSize: 13),
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      hintText: 'Search SKU, barcode, or product name...',
                      prefixIcon: Icon(Icons.search, color: PosTheme.primaryGold, size: 18),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: matches.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (_, idx) {
                        final p = matches[idx];
                        final isSelected = stockState.selectedProduct?.id == p.id;
                        return ChoiceChip(
                          label: Text(
                            p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          selected: isSelected,
                          selectedColor: PosTheme.primaryGold,
                          backgroundColor: PosTheme.card,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : PosTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                          onSelected: (_) {
                            ref.read(posBranchStockProvider.notifier).lookupProductStock(p);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Selected Product Summary Banner
            if (stockState.selectedProduct != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: PosTheme.forestGreen.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PosTheme.primaryGold.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stockState.selectedProduct!.name,
                            style: const TextStyle(
                              color: PosTheme.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'SKU: ${stockState.selectedProduct!.sku} • Barcode: ${stockState.selectedProduct!.barcode}',
                            style: const TextStyle(color: PosTheme.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${stockState.totalNetworkAvailable.toInt()} UNITS',
                          style: const TextStyle(
                            color: PosTheme.primaryGold,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${stockState.branchesWithStock}/${stockState.stores.length} Branches',
                          style: const TextStyle(color: PosTheme.textSecondary, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Branch Stock Cards List
            Expanded(
              child: stockState.isLoading
                  ? const Center(child: CircularProgressIndicator(color: PosTheme.primaryGold))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: stockState.stores.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, index) => _buildBranchCard(stockState.stores[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchCard(BranchStock branch) {
    final badgeColor = branch.isInStock
        ? PosTheme.accentGreen
        : (branch.isLowStock ? PosTheme.accentAmber : PosTheme.accentRed);

    return Container(
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            branch.storeName,
                            style: const TextStyle(
                              color: PosTheme.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${branch.storeCode})',
                          style: const TextStyle(color: PosTheme.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${branch.address} • ${branch.phone}',
                      style: const TextStyle(color: PosTheme.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.45)),
                ),
                child: Text(
                  branch.availabilityLabel,
                  style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _metricPill('On Hand', '${branch.quantityOnHand.toInt()}'),
              const SizedBox(width: 8),
              _metricPill('Reserved', '${branch.quantityReserved.toInt()}'),
              const SizedBox(width: 8),
              _metricPill('Available', '${branch.quantityAvailable.toInt()}', highlight: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricPill(String label, String value, {bool highlight = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: PosTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: highlight ? PosTheme.primaryGold.withValues(alpha: 0.4) : PosTheme.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: PosTheme.textMuted, fontSize: 10)),
            Text(
              value,
              style: TextStyle(
                color: highlight ? PosTheme.primaryGold : PosTheme.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
