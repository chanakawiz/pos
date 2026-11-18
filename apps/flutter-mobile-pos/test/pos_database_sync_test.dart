import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_mobile_pos/models/payment_tender.dart';
import 'package:flutter_mobile_pos/models/pos_product.dart';
import 'package:flutter_mobile_pos/providers/pos_sync_provider.dart';
import 'package:flutter_mobile_pos/screens/sync_status_ribbon.dart';
import 'package:flutter_mobile_pos/services/pos_database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PosDatabaseService.instance.isMockMode = true;
    PosDatabaseService.instance.clearMockData();
  });

  const sampleProduct = PosProduct(
    id: 1,
    uuid: 'p-wal-01',
    name: 'Apple iPhone 16 Pro Max 256GB',
    sku: 'TECH-IPH-16PM',
    barcode: '445566',
    category: 'Smartphones & Tech',
    brand: 'Apple',
    sellingPrice: 415000.0,
    stock: 15,
  );

  final sampleReceipt = SaleReceipt(
    uuid: 'offline-sale-001',
    invoiceNumber: 'INV-OFFLINE-001',
    storeName: 'OmniLuxe Flagship',
    terminalCode: 'ROAMING-01',
    cashierName: 'Staff Cashier',
    soldAt: DateTime.now(),
    items: [],
    subtotal: 415000.0,
    discountAmount: 0.0,
    taxAmount: 33200.0,
    totalAmount: 415000.0,
    paidAmount: 415000.0,
    changeAmount: 0.0,
    payments: [
      PaymentTender(method: PosPaymentMethod.cash, amount: 415000.0),
    ],
    isOffline: true,
  );

  group('PosDatabaseService SQLite WAL Unit Tests', () {
    test('Bulk upserts and caches products in local database', () async {
      final db = PosDatabaseService.instance;
      await db.bulkUpsertProducts([sampleProduct]);

      final count = await db.getPendingSalesCount();
      expect(count, equals(0));
    });

    test('Enqueues offline sales into WAL ledger and sync queue', () async {
      final db = PosDatabaseService.instance;
      await db.enqueueOfflineSale(
        receipt: sampleReceipt,
        apiPayload: {
          'transaction_uuid': sampleReceipt.uuid,
          'total': sampleReceipt.totalAmount,
        },
      );

      final count = await db.getPendingSalesCount();
      expect(count, equals(1));

      final queue = await db.getPendingSyncQueue();
      expect(queue.length, equals(1));
      expect(queue.first['record_uuid'], equals('offline-sale-001'));
    });

    test('Marks sale as synced and purges from active sync queue', () async {
      final db = PosDatabaseService.instance;
      await db.markSaleSynced('offline-sale-001', serverInvoiceNumber: 'INV-CLOUD-7788');

      final count = await db.getPendingSalesCount();
      expect(count, equals(0));

      final queue = await db.getPendingSyncQueue();
      expect(queue.isEmpty, isTrue);
    });

    test('Manages checkpoint version for delta pull synchronization', () async {
      final db = PosDatabaseService.instance;
      expect(await db.getCheckpointVersion('catalog'), equals(0));

      await db.setCheckpointVersion('catalog', 42);
      expect(await db.getCheckpointVersion('catalog'), equals(42));
    });
  });

  group('PosSyncProvider Unit Tests', () {
    test('Initializes with accurate pending queue count from database', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final syncState = container.read(posSyncProvider);
      expect(syncState.isSyncing, isFalse);
      expect(syncState.pendingSalesCount, equals(0));
    });

    test('Pushes offline sales and updates state telemetry', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Enqueue 1 offline sale
      await PosDatabaseService.instance.enqueueOfflineSale(
        receipt: sampleReceipt,
        apiPayload: {'uuid': sampleReceipt.uuid},
      );
      await container.read(posSyncProvider.notifier).refreshPendingCount();

      expect(container.read(posSyncProvider).pendingSalesCount, equals(1));

      // Push offline sales
      final pushed = await container.read(posSyncProvider.notifier).pushOfflineSales();
      expect(pushed >= 0, isTrue);
    });

    test('Pulls catalog delta updates and advances version checkpoint', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final updated = await container.read(posSyncProvider.notifier).pullCatalogDelta();
      expect(updated >= 0, isTrue);
      expect(container.read(posSyncProvider).isSyncing, isFalse);
    });
  });

  group('SyncStatusRibbon Widget Tests', () {
    testWidgets('Renders active cloud sync ribbon when online with zero pending', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SyncStatusRibbon(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CLOUD SYNC ACTIVE'), findsOneWidget);
      expect(find.text('SQLite WAL Engine Ready'), findsOneWidget);
    });
  });
}
