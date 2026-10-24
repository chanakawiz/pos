import 'package:flutter_test/flutter_test.dart';
import 'package:smartshop_mobile_pos/core/database/database_helper.dart';
import 'package:smartshop_mobile_pos/data/models/cart_item.dart';
import 'package:smartshop_mobile_pos/data/models/product.dart';
import 'package:smartshop_mobile_pos/data/models/sale.dart';
import 'package:smartshop_mobile_pos/data/repositories/sales_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sales History & Shift Summary Tests', () {
    late DatabaseHelper dbHelper;
    late SalesRepository salesRepo;

    setUp(() async {
      dbHelper = DatabaseHelper.instance;
      salesRepo = SalesRepository();
      await dbHelper.seedDemoCatalogIfEmpty();
    });

    test('Inserting sales allows querying via getRecentSales with search filter', () async {
      final now = DateTime.now();
      const product = ProductModel(
        uuid: 'prod-anker-65w',
        name: 'Anker Nano II 65W GaN Fast Charger',
        sku: 'ANK-CHG-65W',
        sellingPrice: 13500.0,
      );

      final sale1 = SaleModel(
        transactionUuid: 'hist-tx-001',
        invoiceNumber: 'INV-HIST-001',
        cashierUuid: 'cashier-01',
        cashierName: 'Sarah Miller',
        customerName: 'Nimal Silva',
        storeUuid: 'store-01',
        deviceUuid: 'device-01',
        subtotal: 13500.0,
        totalAmount: 13500.0,
        paidAmount: 15000.0,
        changeAmount: 1500.0,
        soldAt: now,
        items: [
          const CartItemModel(product: product, quantity: 1.0, unitPrice: 13500.0),
        ],
        payments: [
          const PaymentModel(method: PaymentMethod.cash, amount: 13500.0),
        ],
      );

      final sale2 = SaleModel(
        transactionUuid: 'hist-tx-002',
        invoiceNumber: 'INV-HIST-002',
        cashierUuid: 'cashier-01',
        cashierName: 'Sarah Miller',
        customerName: 'Kamal Perera',
        storeUuid: 'store-01',
        deviceUuid: 'device-01',
        subtotal: 27000.0,
        totalAmount: 27000.0,
        paidAmount: 27000.0,
        changeAmount: 0.0,
        soldAt: now,
        items: [
          const CartItemModel(product: product, quantity: 2.0, unitPrice: 13500.0),
        ],
        payments: [
          const PaymentModel(method: PaymentMethod.card, amount: 27000.0),
        ],
      );

      await salesRepo.createSale(sale1);
      await salesRepo.createSale(sale2);

      // Verify getRecentSales returns the sales
      final allSales = await salesRepo.getRecentSales();
      expect(allSales.any((s) => s.invoiceNumber == 'INV-HIST-001'), true);
      expect(allSales.any((s) => s.invoiceNumber == 'INV-HIST-002'), true);

      // Verify search by invoice
      final searchByInvoice = await salesRepo.getRecentSales(search: 'HIST-001');
      expect(searchByInvoice.length, 1);
      expect(searchByInvoice.first.customerName, 'Nimal Silva');

      // Verify search by customer name
      final searchByCustomer = await salesRepo.getRecentSales(search: 'Kamal');
      expect(searchByCustomer.length, 1);
      expect(searchByCustomer.first.invoiceNumber, 'INV-HIST-002');
    });

    test('getShiftSummary aggregates sales count and payment tender breakdown', () async {
      final summary = await salesRepo.getShiftSummary();

      expect(summary['totalSalesCount'] is int, true);
      expect((summary['totalSalesCount'] as int) >= 2, true);
      expect((summary['grossTotal'] as num) > 0, true);
      expect((summary['cashTotal'] as num) >= 13500.0, true);
      expect((summary['cardTotal'] as num) >= 27000.0, true);
    });
  });
}
