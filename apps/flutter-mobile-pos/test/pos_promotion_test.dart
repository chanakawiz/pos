import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_mobile_pos/models/pos_product.dart';
import 'package:flutter_mobile_pos/providers/pos_cart_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const luxuryWatch = PosProduct(
    id: 10,
    uuid: 'prod-watch',
    name: 'Fossil Heritage Automatic Watch',
    sku: 'FOS-HER-01',
    barcode: '778899',
    category: 'Accessories',
    brand: 'Fossil',
    sellingPrice: 60000.0,
    stock: 8,
  );

  const fragrance = PosProduct(
    id: 11,
    uuid: 'prod-frag',
    name: 'Dior Sauvage 60ml',
    sku: 'DIOR-60',
    barcode: '334455',
    category: 'Fragrances & Beauty',
    brand: 'Dior',
    sellingPrice: 20000.0,
    stock: 15,
  );

  group('Milestone 29: Omnichannel Promotions & Coupon Codes Tests', () {
    test('Applies percentage coupon with cap and clears cleanly', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final cartNotifier = container.read(posCartProvider.notifier);
      cartNotifier.addItem(luxuryWatch, quantity: 1); // 60,000

      // LUXE15 = 15% off -> 9,000 off -> total 51,000
      final ok = await cartNotifier.applyPromoCode('luxe15');
      expect(ok, isTrue);

      var cart = container.read(posCartProvider);
      expect(cart.promoCode, equals('LUXE15'));
      expect(cart.promoDiscountAmount, equals(9000.0));
      expect(cart.total, equals(51000.0));

      cartNotifier.clearPromoCode();
      cart = container.read(posCartProvider);
      expect(cart.promoCode, isNull);
      expect(cart.promoDiscountAmount, equals(0.0));
      expect(cart.total, equals(60000.0));
    });

    test('Applies fixed coupon and enforces minimum order threshold', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final cartNotifier = container.read(posCartProvider.notifier);
      cartNotifier.addItem(fragrance, quantity: 1); // 20,000

      // FLASH20 requires >= 50,000 -> rejected
      final rejected = await cartNotifier.applyPromoCode('FLASH20');
      expect(rejected, isFalse);
      expect(container.read(posCartProvider).promoCode, isNull);

      // WELCOME2500 requires >= 10,000 -> accepted
      final accepted = await cartNotifier.applyPromoCode('WELCOME2500');
      expect(accepted, isTrue);
      expect(container.read(posCartProvider).promoDiscountAmount, equals(2500.0));
      expect(container.read(posCartProvider).total, equals(17500.0));
    });

    test('Applies Buy 2 Get 1 Free (B2G1) discounting cheapest unit', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final cartNotifier = container.read(posCartProvider.notifier);
      cartNotifier.addItem(luxuryWatch, quantity: 2); // 120,000
      cartNotifier.addItem(fragrance, quantity: 1);   // 20,000 -> total 140,000

      final ok = await cartNotifier.applyPromoCode('B2G1');
      expect(ok, isTrue);
      expect(container.read(posCartProvider).promoDiscountAmount, equals(20000.0));
      expect(container.read(posCartProvider).total, equals(120000.0));
    });
  });
}
