import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_mobile_pos/models/payment_tender.dart';
import 'package:flutter_mobile_pos/models/pos_product.dart';
import 'package:flutter_mobile_pos/providers/pos_cart_provider.dart';
import 'package:flutter_mobile_pos/screens/payment_tender_sheet.dart';
import 'package:flutter_mobile_pos/screens/sale_success_dialog.dart';

void main() {
  testWidgets('PaymentTenderSheet renders payment tabs, cash denominations, and total payable', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const sampleProduct = PosProduct(
      id: 1,
      uuid: 'p-1',
      name: 'AirPods Pro 2',
      sku: 'SKU-APP-2',
      barcode: '667788',
      category: 'Smartphones & Tech',
      brand: 'Apple',
      sellingPrice: 78500.0,
      stock: 20,
    );

    final container = ProviderContainer();
    container.read(posCartProvider.notifier).addItem(sampleProduct);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: PaymentTenderSheet(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify title and total
    expect(find.text('CHECKOUT & PAYMENT TENDER'), findsOneWidget);
    expect(find.text('TOTAL PAYABLE'), findsOneWidget);

    // Verify payment methods
    expect(find.text('Cash'), findsOneWidget);
    expect(find.text('Card / mPOS'), findsOneWidget);
    expect(find.text('VIP Gift Card'), findsOneWidget);
    expect(find.text('LankaQR'), findsOneWidget);

    // Verify cash tender action
    expect(find.text('ADD CASH TENDER'), findsOneWidget);
  });

  testWidgets('SaleSuccessDialog renders invoice number, change due, and action buttons', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final receipt = SaleReceipt(
      uuid: 'tx-1234',
      invoiceNumber: 'INV-2026-9999',
      storeName: 'OmniLuxe Flagship',
      terminalCode: 'ROAMING-01',
      cashierName: 'Chanaka Staff',
      soldAt: DateTime.now(),
      items: [],
      subtotal: 78500.0,
      discountAmount: 0.0,
      taxAmount: 6280.0,
      totalAmount: 78500.0,
      paidAmount: 80000.0,
      changeAmount: 1500.0,
      payments: [
        PaymentTender(method: PosPaymentMethod.cash, amount: 78500.0, tenderedAmount: 80000.0, changeAmount: 1500.0),
      ],
      loyaltyPointsEarned: 390,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SaleSuccessDialog(receipt: receipt),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify dialog content
    expect(find.text('SALE COMPLETED'), findsOneWidget);
    expect(find.text('Invoice: INV-2026-9999'), findsOneWidget);
    expect(find.text('CASH CHANGE DUE TO CUSTOMER'), findsOneWidget);
    expect(find.text('PRINT'), findsOneWidget);
    expect(find.text('NEW SALE / DONE'), findsOneWidget);
  });
}
