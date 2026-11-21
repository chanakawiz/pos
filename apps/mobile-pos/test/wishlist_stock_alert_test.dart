import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartshop_mobile_pos/data/models/product.dart';
import 'package:smartshop_mobile_pos/providers/wishlist_provider.dart';
import 'package:smartshop_mobile_pos/screens/store/product_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleProduct = ProductModel(
    id: 34,
    uuid: 'prod-34',
    name: 'Tom Ford Oud Wood 100ml',
    sku: 'TF-OUD-100',
    barcode: '888066000034',
    categoryName: 'Fragrances',
    sellingPrice: 89500.0,
    costPrice: 64000.0,
    taxRate: 0.0,
    stockQuantity: 4.0,
    warrantyPeriod: 'Authentic Guarantee',
  );

  group('Milestone 34: Consumer Mobile Wishlist & Back-in-Stock Alerts', () {
    test('WishlistNotifier toggles saved items cleanly', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(wishlistProvider.notifier);
      expect(container.read(wishlistProvider).isSaved(sampleProduct), isFalse);

      final saved = await notifier.toggleWishlist(sampleProduct, variantLabel: '100ml');
      expect(saved, isTrue);
      expect(container.read(wishlistProvider).isSaved(sampleProduct), isTrue);
      expect(container.read(wishlistProvider).savedCount, equals(1));

      final removed = await notifier.toggleWishlist(sampleProduct);
      expect(removed, isFalse);
      expect(container.read(wishlistProvider).isSaved(sampleProduct), isFalse);
      expect(container.read(wishlistProvider).savedCount, equals(0));
    });

    test('WishlistNotifier validates input and registers back-in-stock SMS alerts', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(wishlistProvider.notifier);

      final invalid = await notifier.subscribeBackInStock(
        product: sampleProduct,
        phone: '   ',
      );
      expect(invalid, isFalse);
      expect(container.read(wishlistProvider).hasStockAlert(sampleProduct), isFalse);

      final subscribed = await notifier.subscribeBackInStock(
        product: sampleProduct,
        phone: '0771234567',
        customerName: 'Nimali Perera',
      );
      expect(subscribed, isTrue);
      expect(container.read(wishlistProvider).hasStockAlert(sampleProduct), isTrue);
    });

    testWidgets('ProductDetailScreen displays active wishlist heart and subscribed restock alert badge', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.runAsync(() async {
        await container.read(wishlistProvider.notifier).toggleWishlist(sampleProduct);
        await container.read(wishlistProvider.notifier).subscribeBackInStock(
              product: sampleProduct,
              phone: '0779998888',
            );
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: ProductDetailScreen(product: sampleProduct)),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byKey(const Key('wishlist-toggle-btn')), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byKey(const Key('restock-alert-tile')), findsOneWidget);
      expect(find.text('Restock SMS Alert Active'), findsOneWidget);
      expect(find.text('SUBSCRIBED'), findsOneWidget);
    });
  });
}
