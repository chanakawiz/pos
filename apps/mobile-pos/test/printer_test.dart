import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartshop_mobile_pos/core/printer/esc_pos_builder.dart';
import 'package:smartshop_mobile_pos/core/printer/printer_service.dart';
import 'package:smartshop_mobile_pos/data/models/cart_item.dart';
import 'package:smartshop_mobile_pos/data/models/product.dart';
import 'package:smartshop_mobile_pos/data/models/sale.dart';
import 'package:smartshop_mobile_pos/data/models/user.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  group('ESC/POS Receipt & Cash Drawer Tests', () {
    final testStore = const StoreModel(
      uuid: 'store-01',
      name: 'Main Downtown Store',
      currencySymbol: 'Rs.',
      phone: '+94 11 234 5678',
      receiptHeader: 'SMARTSHOP POS',
      receiptFooter: 'Thank you! Come again.',
    );

    final testProduct = const ProductModel(
      uuid: 'prod-iphone-15',
      name: 'iPhone 15 128GB',
      sku: 'APL-IP15',
      sellingPrice: 285000.0,
      warrantyPeriod: '1 Year Apple Care',
      requiresSerial: true,
    );

    final testSale = SaleModel(
      transactionUuid: 'test-print-tx',
      invoiceNumber: 'INV-20261024-1001',
      cashierUuid: 'cashier-01',
      cashierName: 'Sarah Miller',
      customerUuid: 'cust-01',
      customerName: 'Kasun Perera',
      storeUuid: 'store-01',
      deviceUuid: 'device-01',
      subtotal: 285000.0,
      totalAmount: 285000.0,
      paidAmount: 300000.0,
      changeAmount: 15000.0,
      soldAt: DateTime.parse('2026-10-24 11:30:00'),
      items: [
        CartItemModel(
          product: testProduct,
          quantity: 1.0,
          unitPrice: 285000.0,
          serialNumber: 'IMEI-358941098234123',
          warrantyNotes: '1 Year Apple Care',
        ),
      ],
      payments: [
        const PaymentModel(method: PaymentMethod.cash, amount: 300000.0),
      ],
    );

    test('Cash drawer pulse generates correct pin 2 & pin 5 ESC p commands', () {
      final builderPin2 = EscPosBuilder(drawerPin: 2);
      final pulsePin2 = builderPin2.buildDrawerPulse();
      expect(pulsePin2, [0x1B, 0x70, 0x00, 25, 250]);

      final builderPin5 = EscPosBuilder(drawerPin: 5);
      final pulsePin5 = builderPin5.buildDrawerPulse();
      expect(pulsePin5, [0x1B, 0x70, 0x01, 25, 250]);
    });

    test('80mm receipt contains header, items, IMEI, warranty, and cutter commands', () {
      final builder = EscPosBuilder(paperWidth: 80, autoCut: true);
      final bytes = builder.buildReceipt(testSale, testStore);

      // Verify ESC/POS init at the start
      expect(bytes[0], 0x1B);
      expect(bytes[1], 0x40);

      // Verify partial cutter command at the end
      expect(bytes[bytes.length - 4], 0x1D); // GS
      expect(bytes[bytes.length - 3], 0x56); // V
      expect(bytes[bytes.length - 2], 0x42); // 'B'
      expect(bytes[bytes.length - 1], 0x00); // 0

      final text = latin1.decode(bytes, allowInvalid: true);
      expect(text, contains('SMARTSHOP POS'));
      expect(text, contains('INV-20261024-1001'));
      expect(text, contains('Sarah Miller'));
      expect(text, contains('iPhone 15 128GB'));
      expect(text, contains('SN: IMEI-358941098234123'));
      expect(text, contains('Warranty: 1 Year Apple Care'));
      expect(text, contains('285,000.00'));
      expect(text, contains('Change:'));
      expect(text, contains('15,000.00'));
    });

    test('58mm receipt formats within 32 character columns', () {
      final builder = EscPosBuilder(paperWidth: 58, autoCut: false);
      expect(builder.columns, 32);

      final bytes = builder.buildReceipt(testSale, testStore);
      final text = latin1.decode(bytes, allowInvalid: true);

      expect(text, contains('iPhone 15 128GB'));
      expect(text, contains('INV-20261024-1001'));
      // No cut command when autoCut is false
      expect(bytes.contains(0x1D) && bytes.contains(0x56), false);
    });

    test('PrinterService mock mode logs print jobs and drawer kicks', () async {
      final printer = PrinterService.instance;
      printer.type = 'mock';
      printer.mockPrintLogs.clear();
      printer.mockDrawerKickCount = 0;

      final printSuccess = await printer.printSaleReceipt(testSale, testStore);
      expect(printSuccess, true);
      expect(printer.mockPrintLogs.length, 1);
      expect(printer.mockPrintLogs.first.isNotEmpty, true);

      final kickSuccess = await printer.kickCashDrawer();
      expect(kickSuccess, true);
      expect(printer.mockDrawerKickCount, 1);
    });
  });
}
