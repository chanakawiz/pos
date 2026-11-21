import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_mobile_pos/models/branch_stock.dart';
import 'package:flutter_mobile_pos/models/pos_customer.dart';
import 'package:flutter_mobile_pos/models/pos_product.dart';
import 'package:flutter_mobile_pos/models/sale_history_entry.dart';
import 'package:flutter_mobile_pos/models/shift_session_report.dart';
import 'package:flutter_mobile_pos/providers/pos_auth_provider.dart';
import 'package:flutter_mobile_pos/providers/pos_branch_stock_provider.dart';
import 'package:flutter_mobile_pos/providers/pos_cart_provider.dart';
import 'package:flutter_mobile_pos/providers/pos_customer_provider.dart';
import 'package:flutter_mobile_pos/providers/pos_sales_history_provider.dart';
import 'package:flutter_mobile_pos/providers/pos_shift_provider.dart';
import 'package:flutter_mobile_pos/screens/branch_stock_dialog.dart';
import 'package:flutter_mobile_pos/screens/cash_movement_dialog.dart';
import 'package:flutter_mobile_pos/screens/customer_crm_dialog.dart';
import 'package:flutter_mobile_pos/screens/refund_dialog.dart';
import 'package:flutter_mobile_pos/screens/sales_history_screen.dart';
import 'package:flutter_mobile_pos/services/esc_pos_service.dart';
import 'package:flutter_mobile_pos/services/pos_database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PosDatabaseService.instance.isMockMode = true;
    PosDatabaseService.instance.clearMockData();
    EscPosService.printAuditLog.clear();
  });

  const sampleProduct = PosProduct(
    id: 1,
    uuid: 'prod-1',
    name: 'Apple iPhone 16 Pro Max 256GB',
    sku: 'APP-IP16PM-256',
    barcode: '445566',
    category: 'Smartphones & Tech',
    brand: 'Apple',
    sellingPrice: 400000.0,
    stock: 12,
  );

  group('Milestone 28: VIP Customer CRM & Auto-Tier Discounting Tests', () {
    test('PosCustomer calculates tier titles, discount percentages, multipliers, and masked phone', () {
      const black = PosCustomer(
        uuid: 'c-black',
        name: 'Natasha Perera',
        phone: '+94719876543',
        vipTier: 'black',
        loyaltyPoints: 3400,
      );
      expect(black.tierTitle, equals('Black Diamond'));
      expect(black.tierDiscountPercent, equals(10.0));
      expect(black.pointsMultiplier, equals(2.0));
      expect(black.maskedPhone, contains('••••'));

      const gold = PosCustomer(
        uuid: 'c-gold',
        name: 'Alexander Wright',
        phone: '+94771234567',
        vipTier: 'gold',
        loyaltyPoints: 1450,
      );
      expect(gold.tierTitle, equals('Gold Elite'));
      expect(gold.tierDiscountPercent, equals(5.0));
      expect(gold.pointsMultiplier, equals(1.5));

      const silver = PosCustomer(
        uuid: 'c-silver',
        name: 'Amaya Fernando',
        phone: '+94763210987',
        vipTier: 'silver',
      );
      expect(silver.tierTitle, equals('Silver Privilege'));
      expect(silver.tierDiscountPercent, equals(0.0));
    });

    test('Attaching Gold Elite / Black Diamond customer auto-applies tier discount and clears on detach', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final cartNotifier = container.read(posCartProvider.notifier);
      cartNotifier.addItem(sampleProduct, quantity: 1); // LKR 400,000

      // Attach Gold Elite (5% discount -> LKR 20,000 off -> 380,000)
      const goldCustomer = PosCustomer(
        uuid: 'c-gold-1',
        name: 'Alexander Wright',
        phone: '+94 77 123 4567',
        vipTier: 'gold',
        loyaltyPoints: 1450,
      );
      cartNotifier.attachPosCustomer(goldCustomer);

      var cart = container.read(posCartProvider);
      expect(cart.vipDiscountPercent, equals(5.0));
      expect(cart.vipDiscountAmount, equals(20000.0));
      expect(cart.total, equals(380000.0));

      // Switch to Black Diamond (10% discount -> LKR 40,000 off -> 360,000)
      const blackCustomer = PosCustomer(
        uuid: 'c-black-1',
        name: 'Natasha Perera',
        phone: '+94 71 987 6543',
        vipTier: 'black',
        loyaltyPoints: 3420,
      );
      cartNotifier.attachPosCustomer(blackCustomer);

      cart = container.read(posCartProvider);
      expect(cart.vipDiscountPercent, equals(10.0));
      expect(cart.vipDiscountAmount, equals(40000.0));
      expect(cart.total, equals(360000.0));

      // Detach clears discount cleanly
      cartNotifier.detachCustomer();
      cart = container.read(posCartProvider);
      expect(cart.customerName, isNull);
      expect(cart.vipDiscountPercent, equals(0.0));
      expect(cart.total, equals(400000.0));
    });

    test('PosCustomerNotifier filters directory and registers new VIP member offline', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(posCustomerProvider.notifier);
      notifier.setSearchQuery('Natasha');
      expect(container.read(posCustomerProvider).filteredCustomers.length, equals(1));
      expect(container.read(posCustomerProvider).filteredCustomers.first.name, equals('Natasha Perera'));

      notifier.setSearchQuery('');
      final created = await notifier.registerCustomer(
        name: 'Kasun Jayasinghe',
        phone: '+94 77 555 8899',
        email: 'kasun@omniluxe.store',
      );
      expect(created, isNotNull);
      expect(created!.name, equals('Kasun Jayasinghe'));
      expect(created.loyaltyPoints, equals(100));
      expect(container.read(posCustomerProvider).customers.first.name, equals('Kasun Jayasinghe'));
    });
  });

  group('Milestone 28: Cross-Branch Stock Locator Tests', () {
    test('BranchStock classifies in-stock, low-stock, and out-of-stock states accurately', () {
      const inStock = BranchStock(
        storeId: 1,
        storeCode: 'STORE-001',
        storeName: 'Colombo Flagship',
        address: 'Colombo 03',
        phone: '+94 11 234 5678',
        quantityOnHand: 15,
        quantityReserved: 2,
        quantityAvailable: 13,
      );
      expect(inStock.isInStock, isTrue);
      expect(inStock.availabilityLabel, equals('In Stock (13)'));

      const lowStock = BranchStock(
        storeId: 2,
        storeCode: 'STORE-002',
        storeName: 'Kandy Galleria',
        address: 'KCC',
        phone: '+94 81 223 4455',
        quantityOnHand: 3,
        quantityAvailable: 3,
      );
      expect(lowStock.isLowStock, isTrue);
      expect(lowStock.availabilityLabel, equals('Low Stock (3)'));

      const outOfStock = BranchStock(
        storeId: 3,
        storeCode: 'STORE-003',
        storeName: 'Galle Fort',
        address: 'Pedlar St',
        phone: '+94 91 224 7788',
        quantityOnHand: 0,
        quantityAvailable: 0,
      );
      expect(outOfStock.isOutOfStock, isTrue);
      expect(outOfStock.availabilityLabel, equals('Out of Stock'));
    });

    test('PosBranchStockNotifier resolves boutique inventory with offline resilience', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final stores = await container.read(posBranchStockProvider.notifier).lookupProductStock(sampleProduct);
      expect(stores.length, equals(3));
      expect(container.read(posBranchStockProvider).selectedProduct?.sku, equals('APP-IP16PM-256'));
      expect(container.read(posBranchStockProvider).totalNetworkAvailable, greaterThan(0));
    });
  });

  group('Milestone 28: Sales History, Receipt Reprint & Refund Processing Tests', () {
    test('Loads sales history, reprints thermal receipt, and processes itemized refund with ESC/POS voucher', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final authNotifier = container.read(posAuthProvider.notifier);
      await authNotifier.openShift(openingFloat: 150000.0);
      await container.read(posShiftProvider.notifier).loadCurrentSummary();

      final historyNotifier = container.read(posSalesHistoryProvider.notifier);
      await historyNotifier.loadSales();

      final sales = container.read(posSalesHistoryProvider).sales;
      expect(sales, isNotEmpty);

      final targetSale = sales.first;

      // 1. Reprint historical receipt
      historyNotifier.reprintReceipt(targetSale);
      expect(EscPosService.printAuditLog.last, contains(targetSale.invoiceNumber));

      // 2. Process partial/full refund
      final firstItem = targetSale.items.first;
      final refund = await historyNotifier.processRefund(
        sale: targetSale,
        items: [
          RefundItemLine(
            saleItemId: firstItem.id,
            saleItemUuid: firstItem.uuid,
            productName: firstItem.productName,
            quantity: 1,
            unitPrice: firstItem.unitPrice,
          ),
        ],
        reason: 'Size / Fit Exchange',
        restock: true,
        printReceipt: true,
      );

      expect(refund, isNotNull);
      expect(refund!.totalRefunded, equals(firstItem.unitPrice));
      expect(refund.restocked, isTrue);
      expect(EscPosService.printAuditLog.last, contains('Refund Slip'));

      // Verify sale status updated to refunded
      final updatedSale = container
          .read(posSalesHistoryProvider)
          .sales
          .firstWhere((s) => s.uuid == targetSale.uuid);
      expect(updatedSale.isRefunded, isTrue);
      expect(updatedSale.refundNumber, equals(refund.refundNumber));
    });
  });

  group('Milestone 28: Petty Cash Drops & Float Pay-Ins Tests', () {
    test('Recording safe drop, petty cash, and pay-in updates expected drawer cash and prints vouchers', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(posAuthProvider.notifier).openShift(openingFloat: 20000.0);
      final shiftNotifier = container.read(posShiftProvider.notifier);
      await shiftNotifier.loadCurrentSummary();

      // Safe cash drop -5,000 -> expected 15,000
      final drop = await shiftNotifier.recordCashMovement(
        type: CashMovementType.cashOut,
        amount: 5000.0,
        reason: 'Mid-Shift Safe Drop',
        printVoucher: true,
      );
      expect(drop, isNotNull);
      expect(container.read(posShiftProvider).activeSummary!.cashDropTotal, equals(5000.0));
      expect(container.read(posShiftProvider).activeSummary!.expectedCash, equals(15000.0));
      expect(EscPosService.printAuditLog.last, contains('Cash Movement'));

      // Float pay-in +3,000 -> expected 18,000
      final payIn = await shiftNotifier.recordCashMovement(
        type: CashMovementType.cashIn,
        amount: 3000.0,
        reason: 'Change Replenishment',
        printVoucher: true,
      );
      expect(payIn, isNotNull);
      expect(container.read(posShiftProvider).activeSummary!.cashInTotal, equals(3000.0));
      expect(container.read(posShiftProvider).activeSummary!.expectedCash, equals(18000.0));
      expect(container.read(posShiftProvider).movements.length, equals(2));
    });
  });

  group('Milestone 28: Widget Tests for New Screens & Dialogs', () {
    testWidgets('SalesHistoryScreen renders search bar, status filters, and seeded invoices', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: SalesHistoryScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SALES HISTORY & RECEIPTS'), findsOneWidget);
      expect(find.text('Synced'), findsOneWidget);
      expect(find.text('Refunded'), findsOneWidget);
      expect(find.text('INV-2026-8841'), findsOneWidget);
    });

    testWidgets('CustomerCrmDialog renders VIP lookup list and attaches customer with auto-discount', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(posCartProvider.notifier).addItem(sampleProduct, quantity: 1);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: CustomerCrmDialog())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('VIP CUSTOMER CRM & LOYALTY'), findsOneWidget);
      expect(find.text('Alexander Wright'), findsOneWidget);
      expect(find.text('Natasha Perera'), findsOneWidget);

      await tester.tap(find.text('Natasha Perera'));
      await tester.pumpAndSettle();

      expect(container.read(posCartProvider).customerName, equals('Natasha Perera'));
      expect(container.read(posCartProvider).vipDiscountPercent, equals(10.0));
    });

    testWidgets('BranchStockDialog renders multi-boutique availability cards', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: BranchStockDialog(initialProduct: sampleProduct))),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CROSS-BRANCH STOCK LOCATOR'), findsOneWidget);
      expect(find.text('OmniLuxe Colombo Flagship'), findsOneWidget);
      expect(find.text('OmniLuxe Kandy Galleria'), findsOneWidget);
    });

    testWidgets('CashMovementDialog renders type chips and live updated drawer preview', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: CashMovementDialog())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PETTY CASH & SAFE DROPS'), findsOneWidget);
      expect(find.text('Safe Cash Drop'), findsOneWidget);
      expect(find.text('Float Pay-In'), findsOneWidget);
    });

    testWidgets('RefundDialog renders invoice finder and quick-pick recent invoices', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: RefundDialog())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('IN-STORE REFUND & EXCHANGE'), findsOneWidget);
      expect(find.text('FIND'), findsOneWidget);
    });
  });
}
