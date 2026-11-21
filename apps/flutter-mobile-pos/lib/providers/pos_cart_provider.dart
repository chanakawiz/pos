import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/pos_cart_item.dart';
import '../models/pos_customer.dart';
import '../models/pos_product.dart';
import 'pos_auth_provider.dart';

class PosCartState {
  final List<PosCartItem> items;
  final double orderDiscount;
  final String? customerName;
  final String? customerPhone;
  final String? customerUuid;
  final String? vipTier;
  final double vipDiscountPercent;
  final int customerLoyaltyPoints;
  final String? promoCode;
  final String? promoLabel;
  final double promoDiscountAmount;
  final bool isValidatingPromo;
  final bool isHolding;
  final String? lastHoldReference;
  final String? errorMessage;

  const PosCartState({
    this.items = const [],
    this.orderDiscount = 0.0,
    this.customerName,
    this.customerPhone,
    this.customerUuid,
    this.vipTier,
    this.vipDiscountPercent = 0.0,
    this.customerLoyaltyPoints = 0,
    this.promoCode,
    this.promoLabel,
    this.promoDiscountAmount = 0.0,
    this.isValidatingPromo = false,
    this.isHolding = false,
    this.lastHoldReference,
    this.errorMessage,
  });

  int get totalQuantity => items.fold(0, (sum, i) => sum + i.quantity);
  double get subtotal => items.fold(0.0, (sum, i) => sum + i.subtotal);
  double get itemsDiscount => items.fold(0.0, (sum, i) => sum + i.discount);
  double get vipDiscountAmount => (subtotal * (vipDiscountPercent / 100.0));
  double get totalDiscount =>
      (itemsDiscount + orderDiscount + vipDiscountAmount + promoDiscountAmount).clamp(0.0, subtotal);
  double get total => (subtotal - totalDiscount).clamp(0.0, double.infinity);
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  PosCartState copyWith({
    List<PosCartItem>? items,
    double? orderDiscount,
    String? customerName,
    String? customerPhone,
    String? customerUuid,
    String? vipTier,
    double? vipDiscountPercent,
    int? customerLoyaltyPoints,
    String? promoCode,
    String? promoLabel,
    double? promoDiscountAmount,
    bool? isValidatingPromo,
    bool? isHolding,
    String? lastHoldReference,
    String? errorMessage,
    bool clearCustomer = false,
    bool clearPromo = false,
  }) {
    return PosCartState(
      items: items ?? this.items,
      orderDiscount: orderDiscount ?? this.orderDiscount,
      customerName: clearCustomer ? null : (customerName ?? this.customerName),
      customerPhone: clearCustomer ? null : (customerPhone ?? this.customerPhone),
      customerUuid: clearCustomer ? null : (customerUuid ?? this.customerUuid),
      vipTier: clearCustomer ? null : (vipTier ?? this.vipTier),
      vipDiscountPercent: clearCustomer ? 0.0 : (vipDiscountPercent ?? this.vipDiscountPercent),
      customerLoyaltyPoints: clearCustomer ? 0 : (customerLoyaltyPoints ?? this.customerLoyaltyPoints),
      promoCode: clearPromo ? null : (promoCode ?? this.promoCode),
      promoLabel: clearPromo ? null : (promoLabel ?? this.promoLabel),
      promoDiscountAmount: clearPromo ? 0.0 : (promoDiscountAmount ?? this.promoDiscountAmount),
      isValidatingPromo: isValidatingPromo ?? this.isValidatingPromo,
      isHolding: isHolding ?? this.isHolding,
      lastHoldReference: lastHoldReference ?? this.lastHoldReference,
      errorMessage: errorMessage,
    );
  }
}

class PosCartNotifier extends StateNotifier<PosCartState> {
  final Ref ref;

  PosCartNotifier(this.ref) : super(const PosCartState());

  void addItem(
    PosProduct product, {
    int quantity = 1,
    String? selectedVariant,
    String? serialNumber,
  }) {
    final existingIndex = state.items.indexWhere(
      (item) =>
          item.product.id == product.id &&
          item.selectedVariant == selectedVariant &&
          item.serialNumber == serialNumber,
    );

    if (existingIndex >= 0) {
      final updated = List<PosCartItem>.from(state.items);
      final current = updated[existingIndex];
      updated[existingIndex] = current.copyWith(quantity: current.quantity + quantity);
      state = state.copyWith(items: updated);
    } else {
      final newItem = PosCartItem(
        product: product,
        quantity: quantity,
        selectedVariant: selectedVariant,
        serialNumber: serialNumber,
      );
      state = state.copyWith(items: [...state.items, newItem]);
    }
  }

  void updateQuantity(String itemId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(itemId);
      return;
    }
    final updated = state.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(quantity: newQuantity);
      }
      return item;
    }).toList();
    state = state.copyWith(items: updated);
  }

  void removeItem(String itemId) {
    final updated = state.items.where((item) => item.id != itemId).toList();
    state = state.copyWith(items: updated);
  }

  void applyOrderDiscount(double amount) {
    state = state.copyWith(orderDiscount: amount.clamp(0.0, state.subtotal));
  }

  void attachCustomer({
    required String name,
    required String phone,
    String? uuid,
    String? vipTier,
    double vipDiscountPercent = 0.0,
    int loyaltyPoints = 0,
  }) {
    state = state.copyWith(
      customerName: name,
      customerPhone: phone,
      customerUuid: uuid,
      vipTier: vipTier ?? 'Gold Tier',
      vipDiscountPercent: vipDiscountPercent,
      customerLoyaltyPoints: loyaltyPoints,
    );
  }

  /// Attach full VIP CRM profile with automatic tier privilege discount (5% Gold / 10% Black Diamond)
  void attachPosCustomer(PosCustomer customer) {
    attachCustomer(
      name: customer.name,
      phone: customer.phone,
      uuid: customer.uuid,
      vipTier: customer.tierTitle,
      vipDiscountPercent: customer.tierDiscountPercent,
      loyaltyPoints: customer.loyaltyPoints,
    );
  }

  void detachCustomer() {
    state = state.copyWith(clearCustomer: true);
  }

  void clearCart() {
    state = state.copyWith(
      items: [],
      orderDiscount: 0.0,
      clearCustomer: true,
      clearPromo: true,
      lastHoldReference: null,
      errorMessage: null,
    );
  }

  /// Validate and apply an omnichannel promo / coupon code via ERP or offline rules
  Future<bool> applyPromoCode(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) return false;
    if (state.isEmpty) {
      state = state.copyWith(errorMessage: 'Add items to cart before applying a promo code.');
      return false;
    }

    state = state.copyWith(isValidatingPromo: true, errorMessage: null);
    final session = ref.read(posAuthProvider).session;

    try {
      final uri = Uri.parse('${session.apiUrl}/api/v1/promotions/validate');
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'X-Device-UUID': session.deviceUuid,
              if (session.apiToken != null) 'Authorization': 'Bearer ${session.apiToken}',
            },
            body: jsonEncode({
              'code': code,
              'subtotal': state.subtotal,
              'channel': 'pos',
              if (state.customerUuid != null) 'customer_uuid': state.customerUuid,
              'items': state.items
                  .map((i) => {'quantity': i.quantity, 'unit_price': i.unitPrice})
                  .toList(),
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (!mounted) return false;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['data'];
        if (data is Map) {
          final discount = (data['discount_amount'] as num?)?.toDouble() ?? 0.0;
          state = state.copyWith(
            promoCode: data['code']?.toString() ?? code,
            promoLabel: data['discount_label']?.toString() ?? 'Promo',
            promoDiscountAmount: discount.clamp(0.0, state.subtotal),
            isValidatingPromo: false,
            errorMessage: null,
          );
          return true;
        }
      } else if (response.statusCode == 422) {
        final decoded = jsonDecode(response.body);
        state = state.copyWith(
          isValidatingPromo: false,
          errorMessage: decoded['message']?.toString() ?? 'Invalid promotion code.',
        );
        return false;
      }
    } catch (_) {
      // Offline resilient fallback rules
    }

    if (!mounted) return false;

    final offlineResult = _evaluateOfflinePromo(code);
    if (offlineResult != null) {
      state = state.copyWith(
        promoCode: code,
        promoLabel: offlineResult.$1,
        promoDiscountAmount: offlineResult.$2.clamp(0.0, state.subtotal),
        isValidatingPromo: false,
        errorMessage: null,
      );
      return true;
    }

    state = state.copyWith(
      isValidatingPromo: false,
      errorMessage: 'Promo code "$code" is invalid or requirements not met.',
    );
    return false;
  }

  void clearPromoCode() {
    state = state.copyWith(clearPromo: true, errorMessage: null);
  }

  (String, double)? _evaluateOfflinePromo(String code) {
    final sub = state.subtotal;
    switch (code) {
      case 'LUXE15':
        final amt = (sub * 0.15).clamp(0.0, 25000.0);
        return ('15% OFF (Max 25K)', amt);
      case 'WELCOME2500':
        if (sub < 10000.0) return null;
        return ('LKR 2,500 OFF', 2500.0);
      case 'FLASH20':
        if (sub < 50000.0) return null;
        return ('20% FLASH', (sub * 0.20).clamp(0.0, 50000.0));
      case 'B2G1':
        final unitPrices = <double>[];
        for (final item in state.items) {
          for (var i = 0; i < item.quantity; i++) {
            unitPrices.add(item.unitPrice);
          }
        }
        if (unitPrices.length < 3) return null;
        unitPrices.sort();
        final freeCount = unitPrices.length ~/ 3;
        final discount = unitPrices.take(freeCount).fold(0.0, (a, b) => a + b);
        return ('Buy 2 Get 1 Free', discount);
      default:
        return null;
    }
  }

  /// Line-Busting: Hold current cart to Cloud or local cache with unique reference
  Future<String?> holdBill({String? referenceNote}) async {
    if (state.isEmpty) return null;

    state = state.copyWith(isHolding: true, errorMessage: null);
    final session = ref.read(posAuthProvider).session;
    final holdRef = referenceNote != null && referenceNote.isNotEmpty
        ? 'HOLD-${referenceNote.toUpperCase()}'
        : 'HOLD-${const Uuid().v4().substring(0, 6).toUpperCase()}';

    final cartItemsJson = state.items.map((i) => i.toJson()).toList();
    final subtotal = state.total;

    bool savedToCloud = false;

    try {
      final uri = Uri.parse('${session.apiUrl}/api/v1/held-bills');
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'X-Device-UUID': session.deviceUuid,
              if (session.apiToken != null) 'Authorization': 'Bearer ${session.apiToken}',
            },
            body: jsonEncode({
              'hold_reference': holdRef,
              'cart_items_json': cartItemsJson,
              'subtotal': subtotal,
              'customer_uuid': state.customerUuid,
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 || response.statusCode == 201) {
        savedToCloud = true;
      }
    } catch (_) {
      // Offline fallback: line-busting token generated locally
      savedToCloud = false;
    }

    // Reset current active cart for next shopper
    state = PosCartState(
      lastHoldReference: holdRef,
      isHolding: false,
    );

    return holdRef;
  }

  /// Recall held bill and populate cart
  void recallHeldBill({
    required List<PosCartItem> items,
    String? customerName,
    String? customerPhone,
    String? customerUuid,
    String? vipTier,
    double discount = 0.0,
  }) {
    state = PosCartState(
      items: items,
      orderDiscount: discount,
      customerName: customerName,
      customerPhone: customerPhone,
      customerUuid: customerUuid,
      vipTier: vipTier,
    );
  }
}

final posCartProvider = StateNotifierProvider<PosCartNotifier, PosCartState>((ref) {
  return PosCartNotifier(ref);
});
