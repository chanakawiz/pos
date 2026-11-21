import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartshop_mobile_pos/data/models/product.dart';
import 'package:smartshop_mobile_pos/providers/cart_provider.dart';
import 'package:smartshop_mobile_pos/providers/product_reviews_provider.dart';
import 'package:smartshop_mobile_pos/screens/store/product_detail_screen.dart';
import 'package:smartshop_mobile_pos/screens/store/store_cart_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleProduct = ProductModel(
    id: 23,
    uuid: 'prod-23',
    name: 'Dior Sauvage Elixir 60ml',
    sku: 'DIOR-SAUV-60',
    barcode: '334455',
    categoryName: 'Fragrances',
    sellingPrice: 40000.0,
    costPrice: 28000.0,
    taxRate: 0.0,
    stockQuantity: 10.0,
    warrantyPeriod: 'Authentic Guarantee',
  );

  group('Milestone 32: Consumer Mobile Promo Codes & Gift Cards Tests', () {
    test('Applies promo code, stacks VIP gift card, and clears savings cleanly', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final cart = container.read(cartProvider.notifier);
      cart.addItem(sampleProduct, quantity: 1); // Rs. 40,000

      // 1. Apply LUXE15 (15% off -> Rs. 6,000 off -> 34,000)
      final promoOk = await cart.applyPromoCode('luxe15');
      expect(promoOk, isTrue);
      expect(container.read(cartProvider).promoCode, equals('LUXE15'));
      expect(container.read(cartProvider).promoDiscount, equals(6000.0));
      expect(container.read(cartProvider).grandTotal, equals(34000.0));

      // 2. Stack VIP Gift Card GC-OMNI-2026 (25,000 balance -> remaining 9,000)
      final gcOk = await cart.applyGiftCard('GC-OMNI-2026');
      expect(gcOk, isTrue);
      expect(container.read(cartProvider).giftCardCode, equals('GC-OMNI-2026'));
      expect(container.read(cartProvider).giftCardApplied, equals(25000.0));
      expect(container.read(cartProvider).totalSavings, equals(31000.0));
      expect(container.read(cartProvider).grandTotal, equals(9000.0));

      // 3. Clearing promo and gift card restores full subtotal
      cart.clearPromoCode();
      cart.clearGiftCard();
      expect(container.read(cartProvider).totalSavings, equals(0.0));
      expect(container.read(cartProvider).grandTotal, equals(40000.0));
    });

    test('Rejects invalid promo code and invalid gift card format', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final cart = container.read(cartProvider.notifier);
      cart.addItem(sampleProduct, quantity: 1);

      expect(await cart.applyPromoCode('INVALID99'), isFalse);
      expect(container.read(cartProvider).discountError, isNotNull);

      expect(await cart.applyGiftCard('BAD'), isFalse);
      expect(container.read(cartProvider).giftCardCode, isNull);
    });
  });

  group('Milestone 32: Verified Product Reviews Provider Tests', () {
    test('Loads curated verified reviews, increments helpful votes, and submits new review', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(productReviewsProvider('23').notifier);
      await notifier.loadReviews();

      final initial = container.read(productReviewsProvider('23'));
      expect(initial.count, greaterThanOrEqualTo(2));
      expect(initial.averageRating, equals(5.0));

      final firstUuid = initial.reviews.first.uuid;
      final initialVotes = initial.reviews.first.helpfulVotes;
      await notifier.voteHelpful(firstUuid);
      expect(
        container.read(productReviewsProvider('23')).reviews.first.helpfulVotes,
        equals(initialVotes + 1),
      );

      final posted = await notifier.submitReview(
        customerName: 'Kasun Silva',
        rating: 4,
        title: 'Long lasting scent',
        comment: 'Really impressed with the projection and boutique box.',
      );
      expect(posted, isTrue);
      expect(container.read(productReviewsProvider('23')).reviews.first.customerName, equals('Kasun Silva'));
    });
  });

  group('Milestone 32: Consumer Mobile Widget Tests', () {
    testWidgets('StoreCartScreen displays Promo Code & VIP Gift Card buttons and applied savings', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(cartProvider.notifier).addItem(sampleProduct, quantity: 1);
      await tester.runAsync(() async {
        await container.read(cartProvider.notifier).applyPromoCode('LUXE15');
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: StoreCartScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('LUXE15'), findsOneWidget);
      expect(find.text('VIP Gift Card'), findsOneWidget);
      expect(find.text('Promo & Gift Card Savings'), findsOneWidget);
    });

    testWidgets('ProductDetailScreen renders verified reviews preview card', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: ProductDetailScreen(product: sampleProduct)),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('Customer Reviews'), findsOneWidget);
      expect(find.textContaining('VERIFIED'), findsWidgets);
    });
  });
}
