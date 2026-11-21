import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/cart_provider.dart';
import 'store_checkout_screen.dart';

class StoreCartScreen extends ConsumerWidget {
  final VoidCallback? onBrowseCatalog;

  const StoreCartScreen({super.key, this.onBrowseCatalog});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final currencyFormatter = NumberFormat.currency(
      locale: 'en_LK',
      symbol: 'Rs. ',
      decimalDigits: 2,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'SHOPPING CART (${cart.totalItemCount})',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: AppColors.forest,
          ),
        ),
        actions: [
          if (!cart.isEmpty)
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    title: Text(
                      'Clear Shopping Cart?',
                      style: GoogleFonts.outfit(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                    ),
                    content: Text(
                      'Are you sure you want to remove all pieces from your cart?',
                      style: GoogleFonts.inter(color: AppColors.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(cartProvider.notifier).clearCart();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Clear All', style: TextStyle(color: AppColors.danger)),
                      ),
                    ],
                  ),
                );
              },
              child: Text(
                'Clear',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ),
        ],
      ),
      body: cart.isEmpty
          ? _buildEmptyCart(context)
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Thumbnail Box
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: AppColors.cream,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Center(
                                child: Icon(
                                  _getCategoryIcon(item.product.categoryName),
                                  size: 28,
                                  color: AppColors.sage,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Item Meta
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.brandName.toUpperCase(),
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                      color: AppColors.sage,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.product.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                      height: 1.25,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (item.warrantyNotes != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      item.warrantyNotes!,
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: AppColors.forest,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        currencyFormatter.format(item.total),
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.forest,
                                        ),
                                      ),

                                      // Stepper
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          color: AppColors.cream,
                                          border: Border.all(color: AppColors.border),
                                        ),
                                        child: Row(
                                          children: [
                                            InkWell(
                                              onTap: () {
                                                ref.read(cartProvider.notifier).updateQuantity(
                                                      item.product.uuid,
                                                      item.quantity - 1,
                                                      serialNumber: item.serialNumber,
                                                    );
                                              },
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                child: Icon(Icons.remove, size: 14, color: AppColors.forest),
                                              ),
                                            ),
                                            Text(
                                              '${item.quantity.toInt()}',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                ref.read(cartProvider.notifier).updateQuantity(
                                                      item.product.uuid,
                                                      item.quantity + 1,
                                                      serialNumber: item.serialNumber,
                                                    );
                                              },
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                child: Icon(Icons.add, size: 14, color: AppColors.forest),
                                              ),
                                            ),
                                          ],
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
                    },
                  ),
                ),

                // Cart Summary Sticky Footer
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AppColors.border, width: 1)),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Promo Code & VIP Gift Card Quick Bar
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.forest,
                                  side: const BorderSide(color: AppColors.border),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => _showPromoOrGiftDialog(context, ref, isGiftCard: false),
                                icon: const Icon(Icons.local_offer_outlined, size: 15),
                                label: Text(
                                  cart.promoCode ?? 'Add Promo Code',
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.gold,
                                  side: BorderSide(color: AppColors.gold.withValues(alpha: 0.5)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => _showPromoOrGiftDialog(context, ref, isGiftCard: true),
                                icon: const Icon(Icons.card_giftcard_outlined, size: 15),
                                label: Text(
                                  cart.giftCardCode ?? 'VIP Gift Card',
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (cart.promoCode != null || cart.giftCardCode != null) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              if (cart.promoCode != null)
                                InputChip(
                                  backgroundColor: AppColors.cream,
                                  label: Text(
                                    '${cart.promoCode} (-${currencyFormatter.format(cart.promoDiscount)})',
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.forest),
                                  ),
                                  onDeleted: () => ref.read(cartProvider.notifier).clearPromoCode(),
                                ),
                              if (cart.giftCardCode != null)
                                InputChip(
                                  backgroundColor: AppColors.cream,
                                  label: Text(
                                    '${cart.giftCardCode} (-${currencyFormatter.format(cart.giftCardApplied)})',
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gold),
                                  ),
                                  onDeleted: () => ref.read(cartProvider.notifier).clearGiftCard(),
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Subtotal',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              currencyFormatter.format(cart.subtotal),
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        if (cart.totalSavings > 0) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Promo & Gift Card Savings',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.forest,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '-${currencyFormatter.format(cart.totalSavings)}',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.forest,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Delivery / Packaging',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              'COMPLIMENTARY',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.forest,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Payable',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              currencyFormatter.format(cart.grandTotal),
                              style: GoogleFonts.outfit(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.forest,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.forest,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const StoreCheckoutScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'PROCEED TO SECURE CHECKOUT',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showPromoOrGiftDialog(BuildContext context, WidgetRef ref, {required bool isGiftCard}) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text(
          isGiftCard ? 'Apply VIP Gift Card' : 'Apply Seasonal Promo Code',
          style: GoogleFonts.outfit(color: AppColors.forest, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: ctrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: isGiftCard ? 'GC-XXXX-XXXX-XXXX' : 'e.g. LUXE15 or WELCOME2500',
                filled: true,
                fillColor: AppColors.cream,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            if (!isGiftCard) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                children: ['LUXE15', 'WELCOME2500', 'FLASH20']
                    .map(
                      (code) => ActionChip(
                        backgroundColor: AppColors.cream,
                        label: Text(code, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.forest)),
                        onPressed: () => ctrl.text = code,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.forest, foregroundColor: Colors.white),
            onPressed: () async {
              final value = ctrl.text.trim();
              Navigator.pop(ctx);
              if (value.isEmpty) return;
              final notifier = ref.read(cartProvider.notifier);
              final ok = isGiftCard ? await notifier.applyGiftCard(value) : await notifier.applyPromoCode(value);
              if (!context.mounted) return;
              final latest = ref.read(cartProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: ok ? AppColors.forest : AppColors.danger,
                  content: Text(
                    ok
                        ? (isGiftCard ? 'Gift card ${latest.giftCardCode} applied!' : 'Promo ${latest.promoCode} applied!')
                        : (latest.discountError ?? 'Could not apply code.'),
                  ),
                ),
              );
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cream,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 42,
                color: AppColors.sage,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Your Shopping Cart is Empty',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Explore our curated flagship departments in Tech, Haute Couture, Designer Footwear, and Luxury Automobili.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forest,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onBrowseCatalog,
              child: const Text('Explore Flagship Catalog'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String? categoryName) {
    final cat = (categoryName ?? '').toLowerCase();
    if (cat.contains('tech') || cat.contains('smartphone')) {
      return Icons.phone_iphone;
    } else if (cat.contains('fashion') || cat.contains('clothing')) {
      return Icons.checkroom;
    } else if (cat.contains('footwear') || cat.contains('shoes')) {
      return Icons.roller_skating;
    } else if (cat.contains('vehicle') || cat.contains('auto')) {
      return Icons.directions_car_filled;
    }
    return Icons.inventory_2;
  }
}
