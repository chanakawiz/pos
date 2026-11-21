import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_mobile_pos/providers/pos_inventory_ops_provider.dart';
import 'package:flutter_mobile_pos/screens/inventory_ops_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Milestone 30: Mobile Stocktake & Barcode PO Receiving Tests', () {
    test('Scanning barcodes accumulates cycle count quantities and calculates variance', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(posInventoryOpsProvider.notifier);

      // Scan iPhone 16 Pro Max (barcode 445566) twice
      final firstScan = notifier.scanBarcodeForStocktake('445566');
      expect(firstScan, isNotNull);
      expect(firstScan!.countedQty, equals(1));

      final secondScan = notifier.scanBarcodeForStocktake('445566');
      expect(secondScan!.countedQty, equals(2));

      final state = container.read(posInventoryOpsProvider);
      expect(state.totalCountedSkus, equals(1));
      expect(state.stocktakeLines.first.varianceQty, equals(2 - firstScan.expectedQty));

      // Finalize stocktake clears list and records reference number
      final refNumber = await notifier.submitStocktake(notes: 'Aisle 1 audit');
      expect(refNumber, isNotNull);
      expect(refNumber!, startsWith('STK-'));
      expect(container.read(posInventoryOpsProvider).stocktakeLines, isEmpty);
      expect(container.read(posInventoryOpsProvider).lastStocktakeNumber, equals(refNumber));
    });

    test('Barcode PO receiving verifies arriving items and marks PO received', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(posInventoryOpsProvider.notifier);
      await notifier.loadPurchaseOrders();

      final orders = container.read(posInventoryOpsProvider).purchaseOrders;
      expect(orders, isNotEmpty);

      final applePo = orders.first;
      expect(applePo.isReceived, isFalse);

      // Scan barcode 445566 twice on Apple PO
      expect(notifier.scanBarcodeForPo(applePo.uuid, '445566'), isTrue);
      expect(notifier.scanBarcodeForPo(applePo.uuid, '445566'), isTrue);
      expect(notifier.scanBarcodeForPo(applePo.uuid, 'INVALID-999'), isFalse);

      final updatedPo = container
          .read(posInventoryOpsProvider)
          .purchaseOrders
          .firstWhere((p) => p.uuid == applePo.uuid);
      expect(updatedPo.totalReceivedUnits, equals(2));

      // Confirm goods receipt
      final ok = await notifier.confirmReceivePo(applePo.uuid);
      expect(ok, isTrue);

      final receivedPo = container
          .read(posInventoryOpsProvider)
          .purchaseOrders
          .firstWhere((p) => p.uuid == applePo.uuid);
      expect(receivedPo.isReceived, isTrue);
    });

    testWidgets('InventoryOpsScreen renders Stocktake and PO Receiving tabs', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: InventoryOpsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('INVENTORY STOCKTAKE & PO RECEIVING'), findsOneWidget);
      expect(find.text('STOCKTAKE AUDIT'), findsOneWidget);
      expect(find.text('PO RECEIVING'), findsOneWidget);

      // Tap quick barcode chip to add SKU to stocktake
      await tester.tap(find.text('445566 • iPhone 16'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Apple iPhone 16'), findsOneWidget);

      // Switch to PO Receiving tab
      await tester.tap(find.text('PO RECEIVING'));
      await tester.pumpAndSettle();
      expect(find.text('PO-2026-APPLE-01'), findsOneWidget);
    });
  });
}
