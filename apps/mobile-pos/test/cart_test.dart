import 'package:flutter_test/flutter_test.dart';
import 'package:smartshop_mobile_pos/data/models/product.dart';
import 'package:smartshop_mobile_pos/providers/cart_provider.dart';

void main() {
  group('CartNotifier Unit Tests', () {
    late CartNotifier cartNotifier;

    setUp(() {
      cartNotifier = CartNotifier();
    });

    final testProduct = const ProductModel(
      uuid: 'prod-iphone-15',
      name: 'Apple iPhone 15 128GB',
      sinhalaName: 'ඇපල් අයිෆෝන් 15',
      sku: 'APL-IP15',
      sellingPrice: 285000.0,
      costPrice: 250000.0,
      warrantyPeriod: '1 Year Apple Care',
      requiresSerial: true,
    );

    final regularProduct = const ProductModel(
      uuid: 'prod-anker-cable',
      name: 'Anker USB-C Cable',
      sku: 'ANK-CBL',
      sellingPrice: 5000.0,
      costPrice: 3500.0,
      requiresSerial: false,
    );

    test('Add regular product increments quantity if added twice', () {
      cartNotifier.addItem(regularProduct, quantity: 1.0);
      expect(cartNotifier.state.items.length, 1);
      expect(cartNotifier.state.items.first.quantity, 1.0);

      cartNotifier.addItem(regularProduct, quantity: 2.0);
      expect(cartNotifier.state.items.length, 1);
      expect(cartNotifier.state.items.first.quantity, 3.0);
      expect(cartNotifier.state.subtotal, 15000.0);
    });

    test('Add serial-tracked product keeps separate items for different serial numbers', () {
      cartNotifier.addItem(
        testProduct,
        quantity: 1.0,
        serialNumber: 'IMEI-001',
      );
      cartNotifier.addItem(
        testProduct,
        quantity: 1.0,
        serialNumber: 'IMEI-002',
      );

      expect(cartNotifier.state.items.length, 2);
      expect(cartNotifier.state.items[0].serialNumber, 'IMEI-001');
      expect(cartNotifier.state.items[1].serialNumber, 'IMEI-002');
      expect(cartNotifier.state.totalItemCount, 2);
      expect(cartNotifier.state.grandTotal, 570000.0);
    });

    test('Bill discount applies correctly to grand total', () {
      cartNotifier.addItem(regularProduct, quantity: 2.0); // 10,000
      expect(cartNotifier.state.grandTotal, 10000.0);

      cartNotifier.setBillDiscount(1500.0);
      expect(cartNotifier.state.billDiscount, 1500.0);
      expect(cartNotifier.state.grandTotal, 8500.0);
    });

    test('Hold and resume bill maintains full items state', () {
      cartNotifier.addItem(regularProduct, quantity: 2.0);
      expect(cartNotifier.state.items.length, 1);

      // Hold
      cartNotifier.holdCurrentBill();
      expect(cartNotifier.state.items.isEmpty, true);
      expect(cartNotifier.state.heldBills.length, 1);

      // Resume
      cartNotifier.resumeHeldBill(0);
      expect(cartNotifier.state.items.length, 1);
      expect(cartNotifier.state.items.first.quantity, 2.0);
      expect(cartNotifier.state.heldBills.isEmpty, true);
    });

    test('Quantity decrement removes item when reaching zero', () {
      cartNotifier.addItem(regularProduct, quantity: 1.0);
      expect(cartNotifier.state.items.length, 1);

      cartNotifier.decrementQuantity(regularProduct.uuid);
      expect(cartNotifier.state.items.isEmpty, true);
    });
  });
}
