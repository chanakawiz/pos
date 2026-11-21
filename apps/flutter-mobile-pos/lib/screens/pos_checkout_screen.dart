import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme/pos_theme.dart';
import '../models/pos_product.dart';
import '../providers/pos_auth_provider.dart';
import '../providers/pos_catalog_provider.dart';
import '../providers/pos_cart_provider.dart';
import 'barcode_scanner_dialog.dart';
import 'branch_stock_dialog.dart';
import 'customer_crm_dialog.dart';
import 'held_bills_dialog.dart';
import 'payment_tender_sheet.dart';
import 'sync_status_ribbon.dart';

class PosCheckoutScreen extends ConsumerStatefulWidget {
  const PosCheckoutScreen({super.key});

  @override
  ConsumerState<PosCheckoutScreen> createState() => _PosCheckoutScreenState();
}

class _PosCheckoutScreenState extends ConsumerState<PosCheckoutScreen> {
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _currency = NumberFormat.currency(symbol: 'LKR ', decimalDigits: 0);
  bool _showCartSheet = false;

  void _openPaymentTender() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PaymentTenderSheet(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openBarcodeScanner() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (_) => const BarcodeScannerDialog(),
    );
  }

  void _openHeldBills() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (_) => const HeldBillsDialog(),
    );
  }

  void _promptHoldBill() {
    final cart = ref.read(posCartProvider);
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot hold an empty cart.'),
          backgroundColor: PosTheme.statusWarning,
        ),
      );
      return;
    }

    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PosTheme.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: PosTheme.statusWarning, width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.pause_circle_filled, color: PosTheme.statusWarning),
            SizedBox(width: 8),
            Text('HOLD BILL (LINE-BUSTING)', style: TextStyle(color: PosTheme.textWhite, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Park this bill with ${cart.totalQuantity} items (${_currency.format(cart.total)}) so you can immediately serve the next waiting customer.',
              style: TextStyle(color: PosTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: noteController,
              style: const TextStyle(color: PosTheme.textWhite),
              decoration: InputDecoration(
                filled: true,
                fillColor: PosTheme.cardDark,
                hintText: 'Customer name or reference (e.g. VIP-JOHN)...',
                hintStyle: TextStyle(color: PosTheme.textMuted, fontSize: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: PosTheme.dividerDark),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL', style: TextStyle(color: PosTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: PosTheme.statusWarning,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              final note = noteController.text.trim();
              Navigator.pop(ctx);
              final holdRef = await ref.read(posCartProvider.notifier).holdBill(
                    referenceNote: note.isNotEmpty ? note : null,
                  );
              if (mounted && holdRef != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: PosTheme.primaryGold,
                    behavior: SnackBarBehavior.floating,
                    content: Text(
                      'Bill parked successfully as $holdRef! Ready for next shopper.',
                      style: const TextStyle(color: Color(0xFF111413), fontWeight: FontWeight.w700),
                    ),
                  ),
                );
              }
            },
            child: const Text('CONFIRM HOLD', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _promptCustomerLookup() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => const CustomerCrmDialog(),
    );
  }

  void _promptPromoCode() {
    final promoCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PosTheme.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: PosTheme.primaryGold, width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.local_offer_outlined, color: PosTheme.primaryGold),
            SizedBox(width: 8),
            Text('APPLY PROMO / COUPON', style: TextStyle(color: PosTheme.textWhite, fontSize: 15)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: promoCtrl,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(color: PosTheme.textWhite, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                hintText: 'Enter code (e.g. LUXE15)',
                prefixIcon: Icon(Icons.confirmation_number_outlined, color: PosTheme.primaryGold, size: 18),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: const ['LUXE15', 'WELCOME2500', 'FLASH20', 'B2G1']
                  .map(
                    (code) => ActionChip(
                      backgroundColor: PosTheme.cardDark,
                      label: Text(code, style: const TextStyle(color: PosTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.w700)),
                      onPressed: () => promoCtrl.text = code,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: PosTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = promoCtrl.text.trim();
              Navigator.pop(ctx);
              if (code.isEmpty) return;
              final ok = await ref.read(posCartProvider.notifier).applyPromoCode(code);
              if (!mounted) return;
              final latest = ref.read(posCartProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: ok ? PosTheme.statusSuccess : PosTheme.statusError,
                  content: Text(
                    ok
                        ? 'Applied ${latest.promoCode} (${latest.promoLabel})!'
                        : (latest.errorMessage ?? 'Could not apply promo code.'),
                  ),
                ),
              );
            },
            child: const Text('APPLY'),
          ),
        ],
      ),
    );
  }

  void _openBranchStockLookup({PosProduct? product}) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => BranchStockDialog(initialProduct: product),
    );
  }

  void _showVariantPicker(PosProduct product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: PosTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                product.name,
                style: const TextStyle(color: PosTheme.textWhite, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Select product option / size to add:',
                style: TextStyle(color: PosTheme.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: product.variants.map((v) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PosTheme.cardDark,
                      foregroundColor: PosTheme.textWhite,
                      side: const BorderSide(color: PosTheme.primaryGold),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ref.read(posCartProvider.notifier).addItem(product, selectedVariant: v);
                    },
                    child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(posCatalogProvider);
    final cartState = ref.watch(posCartProvider);
    final session = ref.watch(posAuthProvider).session;
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: PosTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: PosTheme.surfaceDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: PosTheme.textWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: PosTheme.primaryGold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: PosTheme.primaryGold.withOpacity(0.4)),
              ),
              child: Text(
                session.terminalCode,
                style: const TextStyle(
                  color: PosTheme.primaryGold,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              session.cashierName ?? 'Staff Register',
              style: const TextStyle(
                color: PosTheme.textWhite,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          // Cross-branch stock lookup
          IconButton(
            icon: const Icon(Icons.store_mall_directory_outlined, color: PosTheme.statusSuccess),
            tooltip: 'Cross-Branch Stock',
            onPressed: () => _openBranchStockLookup(),
          ),
          // Barcode scanner trigger
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: PosTheme.primaryGold),
            tooltip: 'Hardware Barcode Wedge',
            onPressed: _openBarcodeScanner,
          ),
          // Held bills queue button
          IconButton(
            icon: const Icon(Icons.pause_circle_outline, color: PosTheme.statusWarning),
            tooltip: 'Multi-Lane Held Bills',
            onPressed: _openHeldBills,
          ),
          // Attach customer
          IconButton(
            icon: Icon(
              cartState.customerName != null ? Icons.person : Icons.person_add_outlined,
              color: cartState.customerName != null ? PosTheme.primaryGold : PosTheme.textMuted,
            ),
            tooltip: 'VIP Customer',
            onPressed: _promptCustomerLookup,
          ),
          if (cartState.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: PosTheme.statusError),
              tooltip: 'Clear Cart',
              onPressed: () => ref.read(posCartProvider.notifier).clearCart(),
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          const SyncStatusRibbon(),
          Expanded(
            child: isWide
                ? Row(
                    children: [
                      Expanded(flex: 6, child: _buildCatalogSection(catalogState)),
                      Container(width: 1, color: PosTheme.dividerDark),
                      Expanded(flex: 4, child: _buildCartSection(cartState)),
                    ],
                  )
                : Stack(
                    children: [
                      _buildCatalogSection(catalogState),
                      if (_showCartSheet)
                        GestureDetector(
                          onTap: () => setState(() => _showCartSheet = false),
                          child: Container(color: Colors.black.withOpacity(0.6)),
                        ),
                      if (_showCartSheet)
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.75,
                            decoration: const BoxDecoration(
                              color: PosTheme.surfaceDark,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                            ),
                            child: _buildCartSection(cartState, isDrawer: true),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : _buildMobileBottomBar(cartState),
    );
  }

  Widget _buildCatalogSection(PosCatalogState catalogState) {
    return Column(
      children: [
        // Search & Category filters bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: PosTheme.surfaceDark,
          child: Column(
            children: [
              // Search input
              TextField(
                controller: _searchController,
                style: const TextStyle(color: PosTheme.textWhite, fontSize: 14),
                onChanged: (val) => ref.read(posCatalogProvider.notifier).search(val),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: PosTheme.cardDark,
                  hintText: 'Search products by name, SKU, or brand...',
                  hintStyle: TextStyle(color: PosTheme.textMuted, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: PosTheme.primaryGold, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: PosTheme.textMuted, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(posCatalogProvider.notifier).search('');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: PosTheme.dividerDark),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Category chips horizontal scroll
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: catalogState.categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = catalogState.categories[index];
                    final isSelected = cat == catalogState.selectedCategory;
                    return ChoiceChip(
                      selected: isSelected,
                      label: Text(cat),
                      labelStyle: TextStyle(
                        color: isSelected ? const Color(0xFF111413) : PosTheme.textMuted,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      ),
                      selectedColor: PosTheme.primaryGold,
                      backgroundColor: PosTheme.cardDark,
                      side: BorderSide(
                        color: isSelected ? PosTheme.primaryGold : PosTheme.dividerDark,
                      ),
                      onSelected: (_) {
                        ref.read(posCatalogProvider.notifier).filterByCategory(cat);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Product Catalog Grid
        Expanded(
          child: catalogState.isLoading
              ? const Center(child: CircularProgressIndicator(color: PosTheme.primaryGold))
              : catalogState.filteredProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 48, color: PosTheme.textMuted.withOpacity(0.4)),
                          const SizedBox(height: 10),
                          const Text('No products found', style: TextStyle(color: PosTheme.textWhite, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text('Try a different search query or category', style: TextStyle(color: PosTheme.textMuted, fontSize: 12)),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 220,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: catalogState.filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = catalogState.filteredProducts[index];
                        return _buildProductCard(product);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildProductCard(PosProduct product) {
    return Container(
      decoration: BoxDecoration(
        color: PosTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PosTheme.dividerDark),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: PosTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    product.brand.toUpperCase(),
                    style: const TextStyle(
                      color: PosTheme.primaryGold,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: product.inStock
                      ? PosTheme.statusSuccess.withValues(alpha: 0.15)
                      : PosTheme.statusError.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Qty: ${product.stock}',
                  style: TextStyle(
                    color: product.inStock ? PosTheme.statusSuccess : PosTheme.statusError,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              product.name,
              style: const TextStyle(
                color: PosTheme.textWhite,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            'SKU: ${product.sku}',
            style: TextStyle(color: PosTheme.textMuted, fontSize: 10),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  _currency.format(product.sellingPrice),
                  style: const TextStyle(
                    color: PosTheme.primaryGold,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => _openBranchStockLookup(product: product),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.storefront_outlined, size: 16, color: PosTheme.textMuted),
                ),
              ),
              const SizedBox(width: 4),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    if (product.hasVariants) {
                      _showVariantPicker(product);
                    } else {
                      ref.read(posCartProvider.notifier).addItem(product);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: PosTheme.primaryGold,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, size: 18, color: Color(0xFF111413)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCartSection(PosCartState cartState, {bool isDrawer = false}) {
    return Column(
      children: [
        // Cart Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: PosTheme.surfaceDark,
            border: Border(bottom: BorderSide(color: PosTheme.dividerDark)),
          ),
          child: Row(
            children: [
              const Icon(Icons.shopping_cart, color: PosTheme.primaryGold, size: 20),
              const SizedBox(width: 8),
              const Text(
                'REGISTER CART',
                style: TextStyle(
                  color: PosTheme.textWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: PosTheme.cardDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${cartState.totalQuantity} items',
                  style: const TextStyle(color: PosTheme.primaryGold, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
              if (isDrawer) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, color: PosTheme.textMuted),
                  onPressed: () => setState(() => _showCartSheet = false),
                ),
              ],
            ],
          ),
        ),

        // Attached VIP banner
        if (cartState.customerName != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: PosTheme.primaryGold.withOpacity(0.12),
            child: Row(
              children: [
                const Icon(Icons.verified, size: 16, color: PosTheme.primaryGold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cartState.vipDiscountPercent > 0
                        ? 'VIP: ${cartState.customerName} (${cartState.vipTier ?? "Gold"} • ${cartState.vipDiscountPercent.toStringAsFixed(0)}% OFF)'
                        : 'VIP: ${cartState.customerName} (${cartState.vipTier ?? "Gold"})',
                    style: const TextStyle(
                      color: PosTheme.primaryGold,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => ref.read(posCartProvider.notifier).detachCustomer(),
                  child: const Icon(Icons.close, size: 16, color: PosTheme.primaryGold),
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
                      Icon(Icons.shopping_bag_outlined, size: 48, color: PosTheme.textMuted.withOpacity(0.3)),
                      const SizedBox(height: 10),
                      const Text('Cart is empty', style: TextStyle(color: PosTheme.textWhite, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('Tap products or scan barcode to add items', style: TextStyle(color: PosTheme.textMuted, fontSize: 12)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: cartState.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = cartState.items[index];
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: PosTheme.cardDark,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: PosTheme.dividerDark),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.name,
                                  style: const TextStyle(
                                    color: PosTheme.textWhite,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (item.selectedVariant != null)
                                  Text(
                                    item.selectedVariant!,
                                    style: TextStyle(color: PosTheme.textMuted, fontSize: 11),
                                  ),
                                const SizedBox(height: 2),
                                Text(
                                  _currency.format(item.unitPrice),
                                  style: TextStyle(color: PosTheme.textMuted, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          // Stepper: - QTY +
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 16, color: PosTheme.textMuted),
                                onPressed: () {
                                  ref.read(posCartProvider.notifier).updateQuantity(item.id, item.quantity - 1);
                                },
                              ),
                              Text(
                                '${item.quantity}',
                                style: const TextStyle(color: PosTheme.textWhite, fontWeight: FontWeight.w700),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 16, color: PosTheme.primaryGold),
                                onPressed: () {
                                  ref.read(posCartProvider.notifier).updateQuantity(item.id, item.quantity + 1);
                                },
                              ),
                            ],
                          ),
                          Text(
                            _currency.format(item.total),
                            style: const TextStyle(
                              color: PosTheme.primaryGold,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        // Cart Summary & Checkout Action Buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: PosTheme.surfaceDark,
            border: Border(top: BorderSide(color: PosTheme.dividerDark)),
          ),
          child: Column(
            children: [
              if (cartState.promoCode != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: PosTheme.statusSuccess.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: PosTheme.statusSuccess.withValues(alpha: 0.45)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_offer, size: 14, color: PosTheme.statusSuccess),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${cartState.promoCode} (${cartState.promoLabel ?? "Promo"}): -${_currency.format(cartState.promoDiscountAmount)}',
                          style: const TextStyle(
                            color: PosTheme.statusSuccess,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => ref.read(posCartProvider.notifier).clearPromoCode(),
                        child: const Icon(Icons.close, size: 15, color: PosTheme.statusSuccess),
                      ),
                    ],
                  ),
                ),
              ] else if (cartState.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.local_offer_outlined, size: 14, color: PosTheme.primaryGold),
                    label: const Text(
                      'APPLY PROMO CODE',
                      style: TextStyle(color: PosTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                    onPressed: _promptPromoCode,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Subtotal', style: TextStyle(color: PosTheme.textMuted, fontSize: 13)),
                  Text(_currency.format(cartState.subtotal), style: const TextStyle(color: PosTheme.textWhite, fontSize: 13)),
                ],
              ),
              if (cartState.totalDiscount > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Discount', style: TextStyle(color: PosTheme.statusSuccess, fontSize: 13)),
                    Text('-${_currency.format(cartState.totalDiscount)}', style: const TextStyle(color: PosTheme.statusSuccess, fontSize: 13)),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              const Divider(color: PosTheme.dividerDark, height: 1),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL PAYABLE', style: TextStyle(color: PosTheme.textWhite, fontWeight: FontWeight.w800, fontSize: 15)),
                  Text(
                    _currency.format(cartState.total),
                    style: const TextStyle(
                      color: PosTheme.primaryGold,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Action buttons: Line-Busting HOLD & Gold CHARGE
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.pause, size: 16, color: PosTheme.statusWarning),
                      label: const Text('HOLD BILL'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: PosTheme.statusWarning,
                        side: const BorderSide(color: PosTheme.statusWarning),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                      onPressed: cartState.isEmpty ? null : _promptHoldBill,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 6,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.payments, size: 18),
                      label: const Text('CHARGE / TENDER'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PosTheme.primaryGold,
                        foregroundColor: const Color(0xFF111413),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      onPressed: cartState.isEmpty ? null : _openPaymentTender,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileBottomBar(PosCartState cartState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: PosTheme.surfaceDark,
        border: Border(top: BorderSide(color: PosTheme.dividerDark)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Badge(
              label: Text('${cartState.totalQuantity}'),
              isLabelVisible: cartState.isNotEmpty,
              backgroundColor: PosTheme.primaryGold,
              textColor: const Color(0xFF111413),
              child: const Icon(Icons.shopping_bag_outlined, color: PosTheme.primaryGold),
            ),
            onPressed: () => setState(() => _showCartSheet = !_showCartSheet),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${cartState.totalQuantity} items in cart',
                  style: TextStyle(color: PosTheme.textMuted, fontSize: 11),
                ),
                Text(
                  _currency.format(cartState.total),
                  style: const TextStyle(
                    color: PosTheme.primaryGold,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: PosTheme.textWhite,
              side: BorderSide(color: PosTheme.dividerDark),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => setState(() => _showCartSheet = true),
            child: const Text('CART', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: PosTheme.primaryGold,
              foregroundColor: const Color(0xFF111413),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: cartState.isEmpty ? null : _openPaymentTender,
            child: const Text('CHARGE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
