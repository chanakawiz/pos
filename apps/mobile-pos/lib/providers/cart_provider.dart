import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/cart_item.dart';
import '../data/models/customer.dart';
import '../data/models/product.dart';

class CartState {
  final List<CartItemModel> items;
  final CustomerModel? customer;
  final double billDiscount;
  final List<List<CartItemModel>> heldBills;

  const CartState({
    this.items = const [],
    this.customer,
    this.billDiscount = 0.0,
    this.heldBills = const [],
  });

  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity.toInt());

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.subtotal);

  double get taxTotal => items.fold(0.0, (sum, item) => sum + item.taxAmount);

  double get grandTotal {
    final net = subtotal - billDiscount;
    return (net > 0 ? net : 0.0) + taxTotal;
  }

  bool get isEmpty => items.isEmpty;

  CartState copyWith({
    List<CartItemModel>? items,
    CustomerModel? customer,
    bool clearCustomer = false,
    double? billDiscount,
    List<List<CartItemModel>>? heldBills,
  }) {
    return CartState(
      items: items ?? this.items,
      customer: clearCustomer ? null : (customer ?? this.customer),
      billDiscount: billDiscount ?? this.billDiscount,
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

  void updateQuantity(String productUuid, double newQty) {
    if (newQty <= 0) {
      removeItem(productUuid);
      return;
    }
    final index = state.items.indexWhere((i) => i.product.uuid == productUuid);
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

  void removeItem(String productUuid) {
    state = state.copyWith(
      items: state.items.where((i) => i.product.uuid != productUuid).toList(),
    );
  }

  void setBillDiscount(double discount) {
    state = state.copyWith(billDiscount: discount);
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
    );
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
