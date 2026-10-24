import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/product.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/catalog_provider.dart';

class ProductCard extends ConsumerWidget {
  final ProductModel product;

  const ProductCard({super.key, required this.product});

  void _handleTap(BuildContext context, WidgetRef ref) {
    if (product.requiresSerial) {
      _showSerialCaptureDialog(context, ref);
    } else {
      ref.read(cartProvider.notifier).addItem(product);
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${product.name} to cart'),
          duration: const Duration(milliseconds: 900),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSerialCaptureDialog(BuildContext context, WidgetRef ref) {
    final serialController = TextEditingController();
    final authState = ref.read(authProvider);
    final currencySymbol = authState.user?.store?.currencySymbol ?? 'Rs.';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            const Icon(Icons.qr_code_scanner, color: AppColors.secondary),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Enter Serial / IMEI',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              CurrencyFormatter.format(product.sellingPrice, symbol: currencySymbol),
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
            if (product.warrantyPeriod != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '🛡️ ${product.warrantyPeriod}',
                  style: const TextStyle(fontSize: 12, color: AppColors.secondary),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: serialController,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Device IMEI or Serial Number',
                hintText: 'e.g. 358941098234123',
                prefixIcon: Icon(Icons.memory, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final serial = serialController.text.trim();
              ref.read(cartProvider.notifier).addItem(
                    product,
                    serialNumber: serial.isNotEmpty ? serial : null,
                  );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Added ${product.name} (SN: ${serial.isNotEmpty ? serial : "None"})'),
                  duration: const Duration(milliseconds: 1200),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Add to Cart'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogState = ref.watch(catalogProvider);
    final authState = ref.watch(authProvider);
    final currencySymbol = authState.user?.store?.currencySymbol ?? 'Rs.';

    return InkWell(
      onTap: () => _handleTap(context, ref),
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: product.isLowStock
                ? AppColors.danger.withOpacity(0.5)
                : AppColors.border,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top tags / badges
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Category / Serial Badge
                      if (product.requiresSerial)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.smartphone, size: 11, color: AppColors.secondary),
                              SizedBox(width: 3),
                              Text(
                                'IMEI/SN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (product.categoryName != null)
                        Text(
                          product.categoryName!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        const SizedBox.shrink(),

                      // Stock status badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: product.isLowStock
                              ? AppColors.danger.withOpacity(0.15)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.stockQuantity > 0
                              ? '${CurrencyFormatter.formatQuantity(product.stockQuantity)} left'
                              : 'Out of Stock',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: product.isLowStock
                                ? AppColors.danger
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Product Name
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Sinhala Name (if bilingual enabled)
                  if (catalogState.isBilingual &&
                      product.sinhalaName != null &&
                      product.sinhalaName!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      product.sinhalaName!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary.withOpacity(0.85),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Warranty badge
                  if (product.warrantyPeriod != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '🛡️ ${product.warrantyPeriod}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),

              // Bottom Price & Add Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      CurrencyFormatter.format(product.sellingPrice, symbol: currencySymbol),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add, size: 18, color: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
