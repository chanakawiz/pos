import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/sync_provider.dart';
import '../history/sales_history_screen.dart';
import '../scanner/barcode_scanner_dialog.dart';
import '../session/cash_session_dialog.dart';
import '../settings/settings_screen.dart';
import 'widgets/cart_panel.dart';
import 'widgets/product_card.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openBarcodeScanner() {
    showDialog(
      context: context,
      builder: (ctx) => BarcodeScannerDialog(
        onBarcodeScanned: (barcode) async {
          final product = await ref.read(catalogProvider.notifier).findByBarcode(barcode);
          if (product != null) {
            ref.read(cartProvider.notifier).addItem(product);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Scanned: ${product.name}'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Barcode not found: $barcode'),
                  backgroundColor: AppColors.danger,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _openMobileCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Pull handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: CartPanel(
                  onCheckoutComplete: () {
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(catalogProvider);
    final authState = ref.watch(authProvider);
    final syncState = ref.watch(syncProvider);
    final cartState = ref.watch(cartProvider);
    final isOnline = ref.watch(connectivityProvider);
    final currencySymbol = authState.user?.store?.currencySymbol ?? 'Rs.';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.point_of_sale, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    authState.user?.store?.name ?? 'SmartShop POS',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    authState.user?.name ?? 'Cashier',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Sync status chip
          InkWell(
            onTap: () {
              if (isOnline) {
                ref.read(syncProvider.notifier).syncNow();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Terminal is offline. Sales are safely saved to local SQLite.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: !isOnline
                    ? AppColors.danger.withOpacity(0.15)
                    : (syncState.pendingSalesCount > 0
                        ? AppColors.pending.withOpacity(0.15)
                        : AppColors.synced.withOpacity(0.15)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    !isOnline
                        ? Icons.cloud_off
                        : (syncState.pendingSalesCount > 0
                            ? Icons.cloud_upload
                            : Icons.cloud_done),
                    size: 14,
                    color: !isOnline
                        ? AppColors.danger
                        : (syncState.pendingSalesCount > 0
                            ? AppColors.pending
                            : AppColors.synced),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    !isOnline
                        ? 'Offline (${syncState.pendingSalesCount})'
                        : (syncState.pendingSalesCount > 0
                            ? '${syncState.pendingSalesCount} sync'
                            : 'Live'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: !isOnline
                          ? AppColors.danger
                          : (syncState.pendingSalesCount > 0
                              ? AppColors.pending
                              : AppColors.synced),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bilingual Toggle
          TextButton(
            onPressed: () => ref.read(catalogProvider.notifier).toggleBilingual(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(40, 36),
            ),
            child: Text(
              catalogState.isBilingual ? 'සිං/EN' : 'EN',
              style: const TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),

          // Barcode Camera Trigger
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: AppColors.textPrimary),
            tooltip: 'Camera Barcode Scanner',
            onPressed: _openBarcodeScanner,
          ),

          // Popup Menu for Secondary Actions
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            tooltip: 'More Options',
            onSelected: (val) {
              switch (val) {
                case 'history':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (ctx) => const SalesHistoryScreen()),
                  );
                  break;
                case 'shift':
                  showDialog(
                    context: context,
                    builder: (ctx) => const CashSessionDialog(),
                  );
                  break;
                case 'settings':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (ctx) => const SettingsScreen()),
                  );
                  break;
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'history',
                child: Row(
                  children: [
                    Icon(Icons.receipt_long, size: 20, color: AppColors.textSecondary),
                    SizedBox(width: 10),
                    Text('Sales & History'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'shift',
                child: Row(
                  children: [
                    Icon(Icons.calculate_outlined, size: 20, color: AppColors.textSecondary),
                    SizedBox(width: 10),
                    Text('Shift Audit & X-Report'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20, color: AppColors.textSecondary),
                    SizedBox(width: 10),
                    Text('Terminal Settings'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTabletLandscape = constraints.maxWidth >= 720;

          if (isTabletLandscape) {
            // Tablet / iPad Split Screen (60% Catalog, 40% Cart)
            return Row(
              children: [
                // 60% Left Pane: Catalog
                Expanded(
                  flex: 6,
                  child: _buildCatalogPane(context, catalogState, isTablet: true),
                ),

                // 40% Right Pane: Fixed Cart Panel
                const Expanded(
                  flex: 4,
                  child: CartPanel(),
                ),
              ],
            );
          } else {
            // Phone / Portrait Single Column View (Queue Buster)
            return Stack(
              children: [
                // Full screen catalog
                _buildCatalogPane(context, catalogState, isTablet: false),

                // Floating Bottom Cart Sheet Bar
                if (!cartState.isEmpty)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: InkWell(
                      onTap: _openMobileCartSheet,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black26,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${cartState.totalItemCount} items',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  CurrencyFormatter.format(cartState.grandTotal, symbol: currencySymbol),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                              ],
                            ),
                            const Row(
                              children: [
                                Text(
                                  'View Cart & Pay',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildCatalogPane(BuildContext context, CatalogState catalogState, {required bool isTablet}) {
    return Column(
      children: [
        // Search & Barcode Row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search by product name, SKU, or barcode...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.textMuted),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(catalogProvider.notifier).setSearchQuery('');
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) {
                    ref.read(catalogProvider.notifier).setSearchQuery(val);
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.all(12),
                ),
                icon: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                tooltip: 'Scan Barcode with Camera',
                onPressed: _openBarcodeScanner,
              ),
            ],
          ),
        ),

        // Horizontal Category Chips
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              ChoiceChip(
                label: const Text('All Products'),
                selected: catalogState.selectedCategoryUuid == null,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surface,
                labelStyle: TextStyle(
                  color: catalogState.selectedCategoryUuid == null ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                onSelected: (_) => ref.read(catalogProvider.notifier).selectCategory(null),
              ),
              const SizedBox(width: 8),
              ...catalogState.categories.map((cat) {
                final isSelected = catalogState.selectedCategoryUuid == cat.uuid;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat.name),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    onSelected: (_) => ref.read(catalogProvider.notifier).selectCategory(cat.uuid),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Product Grid
        Expanded(
          child: catalogState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : catalogState.products.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textMuted.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          const Text(
                            'No products found',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 15),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, isTablet ? 16 : 80),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isTablet ? 3 : 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: isTablet ? 1.05 : 0.88,
                      ),
                      itemCount: catalogState.products.length,
                      itemBuilder: (ctx, i) => ProductCard(product: catalogState.products[i]),
                    ),
        ),
      ],
    );
  }
}
