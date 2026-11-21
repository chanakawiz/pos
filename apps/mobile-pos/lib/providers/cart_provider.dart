import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../data/models/cart_item.dart';
import '../data/models/customer.dart';
import '../data/models/product.dart';

class CartState {
  final List<CartItemModel> items;
  final CustomerModel? customer;
  final double billDiscount;
  final String? promoCode;
  final String? promoLabel;
  final double promoDiscount;
  final String? giftCardCode;
  final double giftCardApplied;
  final double? giftCardBalance;
  final String? discountError;
  final List<List<CartItemModel>> heldBills;

  const CartState({
    this.items = const [],
    this.customer,
    this.billDiscount = 0.0,
    this.promoCode,
    this.promoLabel,
    this.promoDiscount = 0.0,
    this.giftCardCode,
    this.giftCardApplied = 0.0,
    this.giftCardBalance,
    this.discountError,
    this.heldBills = const [],
  });

  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity.toInt());

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.subtotal);

  double get taxTotal => items.fold(0.0, (sum, item) => sum + item.taxAmount);

  double get totalSavings => (billDiscount + promoDiscount + giftCardApplied).clamp(0.0, subtotal);

  double get grandTotal {
    final net = subtotal - totalSavings;
    return (net > 0 ? net : 0.0) + taxTotal;
  }

  bool get isEmpty => items.isEmpty;

  CartState copyWith({
    List<CartItemModel>? items,
    CustomerModel? customer,
    bool clearCustomer = false,
    double? billDiscount,
    String? promoCode,
    String? promoLabel,
    double? promoDiscount,
    bool clearPromo = false,
    String? giftCardCode,
    double? giftCardApplied,
    double? giftCardBalance,
    bool clearGiftCard = false,
    String? discountError,
    bool clearError = false,
    List<List<CartItemModel>>? heldBills,
  }) {
    return CartState(
      items: items ?? this.items,
      customer: clearCustomer ? null : (customer ?? this.customer),
      billDiscount: billDiscount ?? this.billDiscount,
      promoCode: clearPromo ? null : (promoCode ?? this.promoCode),
      promoLabel: clearPromo ? null : (promoLabel ?? this.promoLabel),
      promoDiscount: clearPromo ? 0.0 : (promoDiscount ?? this.promoDiscount),
      giftCardCode: clearGiftCard ? null : (giftCardCode ?? this.giftCardCode),
      giftCardApplied: clearGiftCard ? 0.0 : (giftCardApplied ?? this.giftCardApplied),
      giftCardBalance: clearGiftCard ? null : (giftCardBalance ?? this.giftCardBalance),
      discountError: clearError ? null : (discountError ?? this.discountError),
      heldBills: heldBills ?? this.heldBills,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void addItem(
    ProductModel product, {
    double quantity = 1.0,
    String? serialNumber,
    String? warrantyNotes,
  }) {
    // If product requires serial, items with distinct serials are separate lines
    if (product.requiresSerial) {
      final newItem = CartItemModel(
        product: product,
        quantity: quantity,
        unitPrice: product.sellingPrice,
        taxRate: product.taxRate,
        serialNumber: serialNumber,
        warrantyNotes: warrantyNotes ?? product.warrantyPeriod,
      );
      state = state.copyWith(items: [...state.items, newItem]);
      return;
    }

    final existingIndex = state.items.indexWhere(
      (item) => item.product.uuid == product.uuid,
    );

    if (existingIndex >= 0) {
      final existingItem = state.items[existingIndex];
      final updatedItem = existingItem.copyWith(
        quantity: existingItem.quantity + quantity,
      );
      final updatedList = List<CartItemModel>.from(state.items);
      updatedList[existingIndex] = updatedItem;
      state = state.copyWith(items: updatedList);
    } else {
      final newItem = CartItemModel(
        product: product,
        quantity: quantity,
        unitPrice: product.sellingPrice,
        taxRate: product.taxRate,
        warrantyNotes: product.warrantyPeriod,
      );
      state = state.copyWith(items: [...state.items, newItem]);
    }
  }

  void incrementQuantity(String productUuid) {
    final index = state.items.indexWhere((i) => i.product.uuid == productUuid);
    if (index >= 0) {
      final item = state.items[index];
      final updated = item.copyWith(quantity: item.quantity + 1.0);
      final list = List<CartItemModel>.from(state.items);
      list[index] = updated;
      state = state.copyWith(items: list);
    }
  }

  void decrementQuantity(String productUuid) {
    final index = state.items.indexWhere((i) => i.product.uuid == productUuid);
    if (index >= 0) {
      final item = state.items[index];
      if (item.quantity > 1.0) {
        final updated = item.copyWith(quantity: item.quantity - 1.0);
        final list = List<CartItemModel>.from(state.items);
        list[index] = updated;
        state = state.copyWith(items: list);
      } else {
        removeItem(productUuid);
      }
    }
  }

  void updateQuantity(String productUuid, double newQty, {String? serialNumber}) {
    if (newQty <= 0) {
      removeItem(productUuid, serialNumber: serialNumber);
      return;
    }
    final index = state.items.indexWhere(
      (i) => i.product.uuid == productUuid && (serialNumber == null || i.serialNumber == serialNumber),
    );
    if (index >= 0) {
      final item = state.items[index];
      final updated = item.copyWith(quantity: newQty);
      final list = List<CartItemModel>.from(state.items);
      list[index] = updated;
      state = state.copyWith(items: list);
    }
  }

  void updateItemDiscount(String productUuid, double discount) {
    final index = state.items.indexWhere((i) => i.product.uuid == productUuid);
    if (index >= 0) {
      final item = state.items[index];
      final updated = item.copyWith(discountAmount: discount);
      final list = List<CartItemModel>.from(state.items);
      list[index] = updated;
      state = state.copyWith(items: list);
    }
  }

  void updateItemSerial(String productUuid, String serial) {
    final index = state.items.indexWhere((i) => i.product.uuid == productUuid);
    if (index >= 0) {
      final item = state.items[index];
      final updated = item.copyWith(serialNumber: serial);
      final list = List<CartItemModel>.from(state.items);
      list[index] = updated;
      state = state.copyWith(items: list);
    }
  }

  void removeItem(String productUuid, {String? serialNumber}) {
    state = state.copyWith(
      items: state.items
          .where((i) => !(i.product.uuid == productUuid && (serialNumber == null || i.serialNumber == serialNumber)))
          .toList(),
    );
  }

  void setBillDiscount(double discount) {
    state = state.copyWith(billDiscount: discount);
  }

  /// Validate and apply an omnichannel promo code via `/api/v1/promotions/validate` with offline fallback
  Future<bool> applyPromoCode(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty || state.isEmpty) {
      state = state.copyWith(discountError: 'Enter a valid promo code.');
      return false;
    }

    try {
      final response = await ApiClient.instance.dio.post(
        '/api/v1/promotions/validate',
        options: Options(sendTimeout: const Duration(seconds: 2), receiveTimeout: const Duration(seconds: 2)),
        data: {
          'code': code,
          'subtotal': state.subtotal,
          'channel': 'mobile',
          'items': state.items
              .map((i) => {'quantity': i.quantity, 'unit_price': i.unitPrice})
              .toList(),
        },
      );
      if (response.statusCode == 200 && response.data['data'] is Map) {
        final d = response.data['data'];
        final amt = (d['discount_amount'] as num?)?.toDouble() ?? 0.0;
        state = state.copyWith(
          promoCode: d['code']?.toString() ?? code,
          promoLabel: d['discount_label']?.toString() ?? 'Promo',
          promoDiscount: amt.clamp(0.0, state.subtotal),
          clearError: true,
        );
        return true;
      }
    } catch (_) {
      // Offline fallback rules
    }

    final sub = state.subtotal;
    if (code == 'LUXE15') {
      final amt = (sub * 0.15).clamp(0.0, 25000.0);
      state = state.copyWith(
        promoCode: code,
        promoLabel: '15% OFF',
        promoDiscount: amt,
        clearError: true,
      );
      return true;
    }
    if (code == 'WELCOME2500' && sub >= 10000.0) {
      state = state.copyWith(
        promoCode: code,
        promoLabel: 'Rs. 2,500 OFF',
        promoDiscount: 2500.0,
        clearError: true,
      );
      return true;
    }
    if (code == 'FLASH20' && sub >= 50000.0) {
      state = state.copyWith(
        promoCode: code,
        promoLabel: '20% FLASH',
        promoDiscount: (sub * 0.20).clamp(0.0, 50000.0),
        clearError: true,
      );
      return true;
    }

    state = state.copyWith(discountError: 'Promo code "$code" is invalid or minimum spend not met.');
    return false;
  }

  void clearPromoCode() {
    state = state.copyWith(clearPromo: true, clearError: true);
  }

  /// Verify and apply an OmniLuxe VIP Gift Card via `/api/v1/gift-cards/verify`
  Future<bool> applyGiftCard(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty || state.isEmpty) {
      state = state.copyWith(discountError: 'Enter a gift card code (GC-XXXX-XXXX-XXXX).');
      return false;
    }

    double? balance;
    try {
      final response = await ApiClient.instance.dio.post(
        '/api/v1/gift-cards/verify',
        options: Options(sendTimeout: const Duration(seconds: 2), receiveTimeout: const Duration(seconds: 2)),
        data: {'code': code},
      );
      if (response.statusCode == 200 && response.data['data'] is Map) {
        balance = (response.data['data']['balance'] as num?)?.toDouble();
      }
    } catch (_) {
      if (code.startsWith('GC-') && code.length >= 8) {
        balance = 25000.0;
      }
    }

    if (balance == null || balance <= 0) {
      state = state.copyWith(discountError: 'Gift card "$code" is invalid or has zero balance.');
      return false;
    }

    final remainingBeforeCard = (state.subtotal - state.billDiscount - state.promoDiscount).clamp(0.0, state.subtotal);
    final applied = balance.clamp(0.0, remainingBeforeCard);

    state = state.copyWith(
      giftCardCode: code,
      giftCardBalance: balance,
      giftCardApplied: applied,
      clearError: true,
    );
    return true;
  }

  void clearGiftCard() {
    state = state.copyWith(clearGiftCard: true, clearError: true);
  }

  void setCustomer(CustomerModel? customer) {
    if (customer == null) {
      state = state.copyWith(clearCustomer: true);
    } else {
      state = state.copyWith(customer: customer);
    }
  }

  void holdCurrentBill() {
    if (state.items.isEmpty) return;
    state = state.copyWith(
      heldBills: [...state.heldBills, List<CartItemModel>.from(state.items)],
      items: [],
      billDiscount: 0.0,
      clearCustomer: true,
      clearPromo: true,
      clearGiftCard: true,
      clearError: true,
    );
  }

  void resumeHeldBill(int index) {
    if (index < 0 || index >= state.heldBills.length) return;
    final held = state.heldBills[index];
    final updatedHeld = List<List<CartItemModel>>.from(state.heldBills)..removeAt(index);
    state = state.copyWith(
      items: held,
      heldBills: updatedHeld,
    );
  }

  void clearCart() {
    state = state.copyWith(
      items: [],
      billDiscount: 0.0,
      clearCustomer: true,
      clearPromo: true,
      clearGiftCard: true,
      clearError: true,
    );
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
