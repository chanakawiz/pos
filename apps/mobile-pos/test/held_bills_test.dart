import 'package:flutter_test/flutter_test.dart';
import 'package:smartshop_mobile_pos/core/database/database_helper.dart';
import 'package:smartshop_mobile_pos/data/models/cart_item.dart';
import 'package:smartshop_mobile_pos/data/models/product.dart';
import 'package:smartshop_mobile_pos/data/repositories/catalog_repository.dart';
import 'package:smartshop_mobile_pos/data/repositories/held_bill_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Cloud & Offline Held Bills Tests', () {
    late DatabaseHelper dbHelper;
    late HeldBillRepository heldRepo;
    late CatalogRepository catalogRepo;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      heldRepo = HeldBillRepository();
      catalogRepo = CatalogRepository();
      await dbHelper.seedDemoCatalogIfEmpty();
    });

    test('Customer can be created and retrieved via search', () async {
      final customer = await catalogRepo.createCustomer(
        name: 'Sunil Wickramasinghe',
        phone: '0719876543',
        email: 'sunil.w@example.com',
        creditLimit: 25000.0,
      );

      expect(customer.uuid.isNotEmpty, true);
      expect(customer.name, 'Sunil Wickramasinghe');

      // Search for created customer
      final results = await catalogRepo.searchCustomers('Sunil');
      expect(results.isNotEmpty, true);
      expect(results.first.phone, '0719876543');
    });

    test('Hold bill persists items into local SQLite and can be retrieved or deleted', () async {
      const product = ProductModel(
        uuid: 'prod-iphone-15',
        name: 'Apple iPhone 15 128GB',
        sku: 'APL-IP15',
        sellingPrice: 285000.0,
      );

      final items = [
        const CartItemModel(
          product: product,
          quantity: 1.0,
          unitPrice: 285000.0,
          serialNumber: 'SN-IP15-998822',
        ),
      ];

      final held = await heldRepo.holdBill(
        items: items,
        subtotal: 285000.0,
        cashierName: 'Sarah Miller',
      );

      expect(held.uuid.isNotEmpty, true);
      expect(held.holdReference.startsWith('HOLD-'), true);
      expect(held.items.length, 1);
      expect(held.items.first.serialNumber, 'SN-IP15-998822');

      // Query held bills
      final allHeld = await heldRepo.getHeldBills();
      expect(allHeld.any((b) => b.uuid == held.uuid), true);

      // Recall / delete held bill
      await heldRepo.recallOrDeleteBill(held.uuid);
      final afterRecall = await heldRepo.getHeldBills();
      expect(afterRecall.any((b) => b.uuid == held.uuid), false);
    });
  });
}
