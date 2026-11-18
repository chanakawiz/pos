import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_mobile_pos/providers/pos_catalog_provider.dart';
import 'package:flutter_mobile_pos/providers/pos_cart_provider.dart';
import 'package:flutter_mobile_pos/models/pos_product.dart';
import 'package:flutter_mobile_pos/models/pos_cart_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PosCatalogProvider Tests', () {
    test('Catalog loads curated products on init', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(posCatalogProvider);
      expect(state.products.isNotEmpty, isTrue);
      expect(state.categories.contains('All'), isTrue);
      expect(state.categories.contains('Smartphones & Tech'), isTrue);
    });

    test('Catalog filters correctly by category', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(posCatalogProvider.notifier).filterByCategory('Designer Fashion');
      final filtered = container.read(posCatalogProvider).filteredProducts;
      expect(filtered.every((p) => p.category == 'Designer Fashion'), isTrue);
      expect(filtered.any((p) => p.brand == 'Studio Ceylon'), isTrue);
    });

    test('Catalog searches by name and SKU query', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(posCatalogProvider.notifier).search('AirPods');
      final searchResults = container.read(posCatalogProvider).filteredProducts;
      expect(searchResults.length, equals(1));
      expect(searchResults.first.name.contains('AirPods'), isTrue);
    });

    test('Catalog looks up product by barcode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final product = container.read(posCatalogProvider.notifier).lookupByBarcode('445566');
      expect(product, isNotNull);
      expect(product!.name, contains('iPhone 16 Pro Max'));
      expect(product.sellingPrice, equals(415000.00));
    });
  });

  group('PosCartProvider Tests', () {
    const testProduct1 = PosProduct(
      id: 1,
      uuid: 'p-1',
      name: 'iPhone 16 Pro Max',
      sku: 'SKU-IPH-16',
      barcode: '445566',
      category: 'Smartphones & Tech',
      brand: 'Apple',
      sellingPrice: 400000.0,
      stock: 10,
    );

    const testProduct2 = PosProduct(
      id: 2,
      uuid: 'p-2',
      name: 'AirPods Pro 2',
      sku: 'SKU-APP-2',
      barcode: '667788',
      category: 'Smartphones & Tech',
      brand: 'Apple',
      sellingPrice: 80000.0,
      stock: 20,
    );

    test('Cart starts empty with zero subtotal and total', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final cart = container.read(posCartProvider);
      expect(cart.isEmpty, isTrue);
      expect(cart.totalQuantity, equals(0));
      expect(cart.subtotal, equals(0.0));
      expect(cart.total, equals(0.0));
    });

    test('Adding product adds line item and computes total', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(posCartProvider.notifier).addItem(testProduct1, quantity: 1);
      final cart = container.read(posCartProvider);

      expect(cart.items.length, equals(1));
      expect(cart.totalQuantity, equals(1));
      expect(cart.subtotal, equals(400000.0));
      expect(cart.total, equals(400000.0));
    });

    test('Adding same product increments quantity rather than creating duplicate', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(posCartProvider.notifier);
      notifier.addItem(testProduct1, quantity: 1);
      notifier.addItem(testProduct1, quantity: 2);

      final cart = container.read(posCartProvider);
      expect(cart.items.length, equals(1));
      expect(cart.totalQuantity, equals(3));
      expect(cart.subtotal, equals(1200000.0));
    });

    test('Stepper updates quantity and removes on 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(posCartProvider.notifier);
      notifier.addItem(testProduct1, quantity: 2);
      final itemId = container.read(posCartProvider).items.first.id;

      notifier.updateQuantity(itemId, 5);
      expect(container.read(posCartProvider).items.first.quantity, equals(5));

      notifier.updateQuantity(itemId, 0);
      expect(container.read(posCartProvider).isEmpty, isTrue);
    });

    test('Order discount applies and clamps to subtotal', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(posCartProvider.notifier);
      notifier.addItem(testProduct2, quantity: 1); // 80,000

      notifier.applyOrderDiscount(5000.0);
      expect(container.read(posCartProvider).totalDiscount, equals(5000.0));
      expect(container.read(posCartProvider).total, equals(75000.0));

      // Over-discount clamps to zero
      notifier.applyOrderDiscount(100000.0);
      expect(container.read(posCartProvider).total, equals(0.0));
    });

    test('Attaching and detaching VIP customer', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(posCartProvider.notifier);
      notifier.attachCustomer(
        name: 'Alexander Wright',
        phone: '+94 77 123 4567',
        vipTier: 'Platinum VIP',
      );

      var cart = container.read(posCartProvider);
      expect(cart.customerName, equals('Alexander Wright'));
      expect(cart.vipTier, equals('Platinum VIP'));

      notifier.detachCustomer();
      cart = container.read(posCartProvider);
      expect(cart.customerName, isNull);
    });

    test('Line-Busting holdBill saves reference and resets active cart for next customer', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(posCartProvider.notifier);
      notifier.addItem(testProduct1, quantity: 1);
      notifier.addItem(testProduct2, quantity: 1);
      notifier.attachCustomer(name: 'Sarah Connor', phone: '+94 71 555 4444');

      expect(container.read(posCartProvider).totalQuantity, equals(2));

      final holdRef = await notifier.holdBill(referenceNote: 'VIP-SARAH');
      expect(holdRef, equals('HOLD-VIP-SARAH'));

      // Active register cart should now be empty and ready for next shopper
      final freshCart = container.read(posCartProvider);
      expect(freshCart.isEmpty, isTrue);
      expect(freshCart.customerName, isNull);
      expect(freshCart.lastHoldReference, equals('HOLD-VIP-SARAH'));
    });

    test('Recalling held bill restores items and customer data', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(posCartProvider.notifier);
      final recalledItems = [
        PosCartItem(product: testProduct1, quantity: 2),
      ];

      notifier.recallHeldBill(
        items: recalledItems,
        customerName: 'Alexander Wright',
        customerPhone: '+94 77 123 4567',
        vipTier: 'Gold VIP',
      );

      final cart = container.read(posCartProvider);
      expect(cart.items.length, equals(1));
      expect(cart.totalQuantity, equals(2));
      expect(cart.subtotal, equals(800000.0));
      expect(cart.customerName, equals('Alexander Wright'));
    });
  });
}
