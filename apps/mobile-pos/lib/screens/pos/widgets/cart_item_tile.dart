import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/cart_item.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/catalog_provider.dart';

class CartItemTile extends ConsumerWidget {
  final CartItemModel item;

  const CartItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogState = ref.watch(catalogProvider);
    final authState = ref.watch(authProvider);
    final currencySymbol = authState.user?.store?.currencySymbol ?? 'Rs.';
    final cartNotifier = ref.read(cartProvider.notifier);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Name & Delete Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (catalogState.isBilingual &&
                        item.product.sinhalaName != null &&
                        item.product.sinhalaName!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.product.sinhalaName!,
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                onPressed: () => cartNotifier.removeItem(item.product.uuid),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          // Serial / IMEI badge if present
          if (item.serialNumber != null && item.serialNumber!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'SN: ${item.serialNumber}',
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: AppColors.secondary,
                ),
              ),
            ),
          ],

          const SizedBox(height: 8),

          // Quantity controls & Total price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Quantity buttons
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => cartNotifier.decrementQuantity(item.product.uuid),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Icon(Icons.remove, size: 14, color: AppColors.textPrimary),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        CurrencyFormatter.formatQuantity(item.quantity),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => cartNotifier.incrementQuantity(item.product.uuid),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Icon(Icons.add, size: 14, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),

              // Subtotal Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(item.total, symbol: currencySymbol),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  if (item.quantity > 1)
                    Text(
                      '@ ${CurrencyFormatter.format(item.unitPrice, symbol: currencySymbol)}',
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
