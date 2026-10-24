import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_provider.dart';
import 'product_detail_screen.dart';

class StoreCatalogScreen extends ConsumerWidget {
  final VoidCallback? onOpenBag;

  const StoreCatalogScreen({super.key, this.onOpenBag});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);
    final cart = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'EXPLORE BOUTIQUE',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.textPrimary),
                onPressed: onOpenBag,
              ),
              if (cart.totalItemCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${cart.totalItemCount}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (val) {
                ref.read(catalogProvider.notifier).setSearchQuery(val);
              },
              decoration: InputDecoration(
                hintText: 'Search Tech, Fashion, Footwear, Vehicles...',
                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                suffixIcon: catalog.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          ref.read(catalogProvider.notifier).setSearchQuery('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Department Filter Chips
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                _buildCategoryChip(
                  label: 'All Departments',
                  isSelected: catalog.selectedCategoryUuid == null,
                  onTap: () {
                    ref.read(catalogProvider.notifier).selectCategory(null);
                  },
                ),
                ...catalog.categories.map((cat) {
                  final isSelected = catalog.selectedCategoryUuid == cat.uuid;
                  return _buildCategoryChip(
                    label: cat.name,
                    isSelected: isSelected,
                    onTap: () {
                      ref.read(catalogProvider.notifier).selectCategory(cat.uuid);
                    },
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Catalog Grid
          Expanded(
            child: catalog.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : catalog.products.isEmpty
                    ? Center(
                        child: Text(
                          'No boutique items found matching "${catalog.searchQuery}"',
                          style: GoogleFonts.inter(color: AppColors.textSecondary),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.64,
                        ),
                        itemCount: catalog.products.length,
                        itemBuilder: (context, index) {
                          final product = catalog.products[index];
                          return _buildProductCard(context, ref, product);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.gold,
        backgroundColor: AppColors.surface,
        checkmarkColor: Colors.black,
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.black : AppColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppColors.gold : AppColors.border,
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, WidgetRef ref, ProductModel product) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'en_LK',
      symbol: 'Rs. ',
      decimalDigits: 2,
    );

    return InkWell(
      onTap: () async {
        final goToBag = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
        if (goToBag == true && onOpenBag != null) {
          onOpenBag!();
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media Preview Container
            Container(
              height: 125,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                gradient: _getCategoryGradient(product.categoryName),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Hero(
                      tag: 'prod-icon-${product.uuid}',
                      child: Icon(
                        _getCategoryIcon(product.categoryName),
                        size: 48,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'In Stock',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Card Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand Tag
                    Text(
                      product.brandName.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 3),

                    // Title
                    Text(
                      product.name,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    // Warranty Pill
                    if (product.warrantyPeriod != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.warrantyPeriod!,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],

                    // Price & Add Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            currencyFormatter.format(product.sellingPrice),
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            ref.read(cartProvider.notifier).addItem(product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.surface,
                                content: Text(
                                  'Added ${product.name} to Bag',
                                  style: GoogleFonts.inter(color: AppColors.textPrimary),
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.add, size: 14, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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

  LinearGradient _getCategoryGradient(String? categoryName) {
    final cat = (categoryName ?? '').toLowerCase();
    if (cat.contains('tech')) {
      return const LinearGradient(
        colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
      );
    } else if (cat.contains('fashion')) {
      return const LinearGradient(
        colors: [Color(0xFF232526), Color(0xFF414345)],
      );
    } else if (cat.contains('footwear')) {
      return const LinearGradient(
        colors: [Color(0xFF141E30), Color(0xFF243B55)],
      );
    } else {
      return const LinearGradient(
        colors: [Color(0xFF1F1C18), Color(0xFF8E0E00)],
      );
    }
  }
}
