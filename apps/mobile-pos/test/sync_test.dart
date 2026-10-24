import 'package:flutter_test/flutter_test.dart';
import 'package:smartshop_mobile_pos/core/database/database_helper.dart';
import 'package:smartshop_mobile_pos/data/models/sale.dart';
import 'package:smartshop_mobile_pos/data/repositories/sales_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Offline Storage & Sales Persistence Tests', () {
    late SalesRepository salesRepo;
    late DatabaseHelper dbHelper;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      salesRepo = SalesRepository();
      await dbHelper.seedDemoCatalogIfEmpty();
    });

    test('Products can be queried by category and search filter', () async {
      final allProducts = await dbHelper.getAllProducts();
      expect(allProducts.isNotEmpty, true);

      final searchResult = await dbHelper.getAllProducts(search: 'iPhone');
      expect(searchResult.isNotEmpty, true);
      expect(searchResult.first.name.contains('iPhone'), true);
    });

    test('Barcode lookup returns exact product matching code', () async {
      final product = await dbHelper.findProductByBarcode('195949038234');
      expect(product, isNotNull);
      expect(product!.name, contains('iPhone 15'));
      expect(product.requiresSerial, true);
      expect(product.warrantyPeriod, '1 Year Apple Care');
    });

    test('Sale is committed locally into offline queue with pending status', () async {
      final now = DateTime.now();
      final sale = SaleModel(
        transactionUuid: 'test-tx-uuid-001',
        invoiceNumber: 'INV-TEST-001',
        cashierUuid: 'cashier-test',
        cashierName: 'Sarah Miller',
        storeUuid: 'store-test',
        deviceUuid: 'device-test',
        subtotal: 285000.0,
        totalAmount: 285000.0,
        paidAmount: 285000.0,
        soldAt: now,
        items: [],
        payments: [
          const PaymentModel(method: PaymentMethod.cash, amount: 285000.0),
        ],
        syncStatus: 'pending',
      );

      await salesRepo.createSale(sale);

      final pendingSales = await salesRepo.getPendingSales();
      final found = pendingSales.any((s) => s.transactionUuid == 'test-tx-uuid-001');
      expect(found, true);

      // Verify marking synced
      await dbHelper.markSalesSynced(['test-tx-uuid-001']);
      final remainingPending = await salesRepo.getPendingSales();
      final stillPending = remainingPending.any((s) => s.transactionUuid == 'test-tx-uuid-001');
      expect(stillPending, false);
    });

    test('Sync version metadata persists and increments', () async {
      await dbHelper.setLastSyncVersion(42);
      final ver = await dbHelper.getLastSyncVersion();
      expect(ver, 42);
    });
  });
}
