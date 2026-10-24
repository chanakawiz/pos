import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/product.dart';
import '../../providers/cart_provider.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  String? _selectedVariant;
  int _quantity = 1;

  final currencyFormatter = NumberFormat.currency(
    locale: 'en_LK',
    symbol: 'Rs. ',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _initDefaultVariant();
  }

  void _initDefaultVariant() {
    final cat = (widget.product.categoryName ?? '').toLowerCase();
    if (cat.contains('fashion') || cat.contains('clothing')) {
      _selectedVariant = 'M';
    } else if (cat.contains('footwear') || cat.contains('shoes')) {
      _selectedVariant = 'UK 9';
    } else if (cat.contains('tech') || cat.contains('smartphones')) {
      _selectedVariant = 'Standard Titanium';
    } else if (cat.contains('vehicles') || cat.contains('auto')) {
      _selectedVariant = 'Official Flagship Spec';
    }
  }

  List<String> _getAvailableVariants() {
    final cat = (widget.product.categoryName ?? '').toLowerCase();
    if (cat.contains('fashion') || cat.contains('clothing')) {
      return ['S', 'M', 'L', 'XL', 'XXL'];
    } else if (cat.contains('footwear') || cat.contains('shoes')) {
      return ['UK 7', 'UK 8', 'UK 9', 'UK 10', 'UK 11'];
    } else if (cat.contains('tech') || cat.contains('smartphones')) {
      return ['128GB', '256GB', '512GB', '1TB'];
    } else if (cat.contains('vehicles') || cat.contains('auto')) {
      return ['AWD Flagship', 'Off-Road Spec', 'Executive Edition'];
    }
    return ['Standard'];
  }

  IconData _getCategoryIcon() {
    final cat = (widget.product.categoryName ?? '').toLowerCase();
    if (cat.contains('tech') || cat.contains('smartphones')) {
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

  LinearGradient _getCategoryGradient() {
    final cat = (widget.product.categoryName ?? '').toLowerCase();
    if (cat.contains('tech')) {
      return const LinearGradient(
        colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (cat.contains('fashion')) {
      return const LinearGradient(
        colors: [Color(0xFF232526), Color(0xFF414345)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (cat.contains('footwear')) {
      return const LinearGradient(
        colors: [Color(0xFF141E30), Color(0xFF243B55)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      return const LinearGradient(
        colors: [Color(0xFF1F1C18), Color(0xFF8E0E00)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final variants = _getAvailableVariants();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          widget.product.brandName.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            color: AppColors.gold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.textSecondary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Item link copied to clipboard'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Media Showcase Box
            Container(
              height: 280,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: _getCategoryGradient(),
                border: const Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Hero(
                      tag: 'prod-icon-${widget.product.uuid}',
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.06),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          _getCategoryIcon(),
                          size: 70,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  // In-Stock & Warranty Badges
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Flagship In-Stock (${widget.product.stockQuantity.toInt()} available)',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.product.warrantyPeriod != null)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.gold.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified, size: 14, color: AppColors.gold),
                            const SizedBox(width: 5),
                            Text(
                              widget.product.warrantyPeriod!,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.gold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Department Chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      (widget.product.categoryName ?? 'BOUTIQUE PIECE').toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Title
                  Text(
                    widget.product.name,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.25,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Price & SKU
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        currencyFormatter.format(widget.product.sellingPrice),
                        style: GoogleFonts.outfit(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Tax Included',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),
                  Text(
                    'SKU: ${widget.product.sku} • Barcode: ${widget.product.barcode}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),

                  const Divider(color: AppColors.border, height: 32),

                  // Variant Picker
                  if (variants.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SELECT SPECIFICATION / SIZE',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          _selectedVariant ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: variants.map((v) {
                        final isSelected = _selectedVariant == v;
                        return InkWell(
                          onTap: () {
                            setState(() => _selectedVariant = v);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.gold : AppColors.card,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? AppColors.gold : AppColors.border,
                                width: 1.2,
                              ),
                            ),
                            child: Text(
                              v,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.black : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Quantity Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'QUANTITY',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              color: _quantity > 1 ? AppColors.textPrimary : AppColors.textMuted,
                              onPressed: _quantity > 1
                                  ? () => setState(() => _quantity--)
                                  : null,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '$_quantity',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              color: AppColors.textPrimary,
                              onPressed: () {
                                if (_quantity < widget.product.stockQuantity) {
                                  setState(() => _quantity++);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Divider(color: AppColors.border, height: 32),

                  // Boutique Guarantees
                  _buildBoutiqueGuarantee(
                    icon: Icons.local_shipping_outlined,
                    title: 'Dispatched from Colombo Flagship',
                    subtitle: 'Complimentary white-glove packaging & courier service across Sri Lanka.',
                  ),
                  const SizedBox(height: 14),
                  _buildBoutiqueGuarantee(
                    icon: Icons.shield_outlined,
                    title: '100% Genuine Authenticity Guaranteed',
                    subtitle: widget.product.requiresSerial
                        ? 'Includes serial/VIN tracking & verifiable digital SMS e-receipt.'
                        : 'Authentic branded stock backed by manufacturer warranties.',
                  ),
                  const SizedBox(height: 14),
                  _buildBoutiqueGuarantee(
                    icon: Icons.storefront_outlined,
                    title: 'Click & Collect Available',
                    subtitle: 'Pick up immediately at 420 Galle Road, Colombo 03.',
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Price Total
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        letterSpacing: 1,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      currencyFormatter.format(widget.product.sellingPrice * _quantity),
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.forest,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Add to Cart Button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.forest,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  ref.read(cartProvider.notifier).addItem(
                        widget.product,
                        quantity: _quantity.toDouble(),
                        warrantyNotes: _selectedVariant != null
                            ? 'Variant: $_selectedVariant • ${widget.product.warrantyPeriod ?? ""}'
                            : widget.product.warrantyPeriod,
                      );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.forest,
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Added to your Cart (${_selectedVariant ?? "Standard"})',
                              style: GoogleFonts.inter(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                label: const Text('Add to Cart'),
              ),
              const SizedBox(width: 10),

              // Buy Now / Quick Checkout Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forest,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  ref.read(cartProvider.notifier).addItem(
                        widget.product,
                        quantity: _quantity.toDouble(),
                        warrantyNotes: _selectedVariant != null
                            ? 'Variant: $_selectedVariant • ${widget.product.warrantyPeriod ?? ""}'
                            : widget.product.warrantyPeriod,
                      );
                  Navigator.pop(context, true); // Pop back and switch to Cart tab
                },
                child: Text(
                  'Buy Now',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoutiqueGuarantee({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, size: 20, color: AppColors.gold),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
