import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/payment_tender.dart';
import '../models/pos_product.dart';

class PosDatabaseService {
  static PosDatabaseService? _instance;
  static Database? _database;
  bool isMockMode = false;

  // In-memory tables for headless unit tests
  final Map<String, Map<String, dynamic>> _mockProducts = {};
  final Map<String, Map<String, dynamic>> _mockOfflineSales = {};
  final List<Map<String, dynamic>> _mockSyncQueue = [];
  final Map<String, int> _mockCheckpoints = {};

  PosDatabaseService._();

  static PosDatabaseService get instance {
    _instance ??= PosDatabaseService._();
    return _instance!;
  }

  void clearMockData() {
    _mockProducts.clear();
    _mockOfflineSales.clear();
    _mockSyncQueue.clear();
    _mockCheckpoints.clear();
  }

  Future<Database?> get database async {
    if (isMockMode) return null;
    if (_database != null) return _database!;
    try {
      _database = await _initDatabase();
      return _database;
    } catch (_) {
      isMockMode = true;
      return null;
    }
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'omniluxe_staff_pos.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // WAL mode for maximum concurrent read/write throughput
        await db.execute('PRAGMA journal_mode = WAL;');

        // 1. Cached Products Table
        await db.execute('''
          CREATE TABLE products (
            id INTEGER PRIMARY KEY,
            uuid TEXT UNIQUE,
            name TEXT NOT NULL,
            sku TEXT NOT NULL,
            barcode TEXT,
            category TEXT,
            brand TEXT,
            selling_price REAL NOT NULL,
            cost_price REAL DEFAULT 0.0,
            stock INTEGER DEFAULT 0,
            unit TEXT DEFAULT 'piece',
            warranty_period TEXT,
            requires_serial INTEGER DEFAULT 0,
            variants_json TEXT,
            image_url TEXT,
            synced_at TEXT
          );
        ''');

        // 2. Offline Sales Ledger Table
        await db.execute('''
          CREATE TABLE offline_sales (
            uuid TEXT PRIMARY KEY,
            invoice_number TEXT NOT NULL,
            transaction_uuid TEXT,
            store_id INTEGER,
            device_code TEXT,
            cashier_id INTEGER,
            cashier_name TEXT,
            subtotal REAL NOT NULL,
            discount_amount REAL DEFAULT 0.0,
            tax_amount REAL DEFAULT 0.0,
            total_amount REAL NOT NULL,
            paid_amount REAL NOT NULL,
            change_amount REAL DEFAULT 0.0,
            items_json TEXT NOT NULL,
            payments_json TEXT NOT NULL,
            sold_at TEXT NOT NULL,
            status TEXT DEFAULT 'pending',
            created_at TEXT NOT NULL
          );
        ''');

        // 3. Background Sync Queue
        await db.execute('''
          CREATE TABLE sync_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            record_type TEXT NOT NULL,
            record_uuid TEXT NOT NULL,
            payload_json TEXT NOT NULL,
            retry_count INTEGER DEFAULT 0,
            status TEXT DEFAULT 'queued',
            created_at TEXT NOT NULL,
            last_attempted_at TEXT
          );
        ''');

        // 4. Sync Checkpoint & Delta Versions
        await db.execute('''
          CREATE TABLE sync_checkpoints (
            key TEXT PRIMARY KEY,
            version INTEGER NOT NULL,
            last_synced_at TEXT NOT NULL
          );
        ''');
      },
    );
  }

  /// Bulk upsert products into local SQLite
  Future<void> bulkUpsertProducts(List<PosProduct> products) async {
    if (isMockMode) {
      for (final p in products) {
        _mockProducts[p.barcode.isNotEmpty ? p.barcode : p.id.toString()] = p.toJson();
      }
      return;
    }

    final db = await database;
    if (db == null) return;

    final batch = db.batch();
    for (final p in products) {
      batch.insert(
        'products',
        {
          'id': p.id,
          'uuid': p.uuid,
          'name': p.name,
          'sku': p.sku,
          'barcode': p.barcode,
          'category': p.category,
          'brand': p.brand,
          'selling_price': p.sellingPrice,
          'cost_price': p.costPrice,
          'stock': p.stock,
          'unit': p.unit,
          'warranty_period': p.warrantyPeriod,
          'requires_serial': p.requiresSerial ? 1 : 0,
          'variants_json': jsonEncode(p.variants),
          'image_url': p.imageUrl,
          'synced_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Enqueue offline sale and write to local SQLite WAL tables
  Future<void> enqueueOfflineSale({
    required SaleReceipt receipt,
    required Map<String, dynamic> apiPayload,
  }) async {
    final now = DateTime.now().toIso8601String();

    if (isMockMode) {
      _mockOfflineSales[receipt.uuid] = {
        'uuid': receipt.uuid,
        'invoice_number': receipt.invoiceNumber,
        'total_amount': receipt.totalAmount,
        'status': 'pending',
        'sold_at': receipt.soldAt.toIso8601String(),
        'items_json': jsonEncode(receipt.items.map((i) => i.toJson()).toList()),
        'payments_json': jsonEncode(receipt.payments.map((t) => t.toJson()).toList()),
      };
      _mockSyncQueue.add({
        'record_type': 'sale',
        'record_uuid': receipt.uuid,
        'payload_json': jsonEncode(apiPayload),
        'status': 'queued',
        'created_at': now,
      });
      return;
    }

    final db = await database;
    if (db == null) return;

    await db.transaction((txn) async {
      await txn.insert(
        'offline_sales',
        {
          'uuid': receipt.uuid,
          'invoice_number': receipt.invoiceNumber,
          'transaction_uuid': receipt.uuid,
          'device_code': receipt.terminalCode,
          'cashier_name': receipt.cashierName,
          'subtotal': receipt.subtotal,
          'discount_amount': receipt.discountAmount,
          'tax_amount': receipt.taxAmount,
          'total_amount': receipt.totalAmount,
          'paid_amount': receipt.paidAmount,
          'change_amount': receipt.changeAmount,
          'items_json': jsonEncode(receipt.items.map((i) => i.toJson()).toList()),
          'payments_json': jsonEncode(receipt.payments.map((t) => t.toJson()).toList()),
          'sold_at': receipt.soldAt.toIso8601String(),
          'status': 'pending',
          'created_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await txn.insert(
        'sync_queue',
        {
          'record_type': 'sale',
          'record_uuid': receipt.uuid,
          'payload_json': jsonEncode(apiPayload),
          'status': 'queued',
          'created_at': now,
        },
      );
    });
  }

  /// Get count of pending offline sales awaiting cloud push
  Future<int> getPendingSalesCount() async {
    if (isMockMode) {
      return _mockOfflineSales.values.where((s) => s['status'] == 'pending').length;
    }
    final db = await database;
    if (db == null) return 0;

    final count = Sqflite.firstIntValue(
      await db.rawQuery("SELECT COUNT(*) FROM offline_sales WHERE status = 'pending'"),
    );
    return count ?? 0;
  }

  /// Get pending queue payloads for batch push
  Future<List<Map<String, dynamic>>> getPendingSyncQueue() async {
    if (isMockMode) {
      return List.from(_mockSyncQueue.where((q) => q['status'] == 'queued'));
    }
    final db = await database;
    if (db == null) return [];

    return await db.query(
      'sync_queue',
      where: "status = 'queued'",
      orderBy: 'id ASC',
      limit: 50,
    );
  }

  /// Mark sale as synced and purge from active queue
  Future<void> markSaleSynced(String recordUuid, {String? serverInvoiceNumber}) async {
    if (isMockMode) {
      if (_mockOfflineSales.containsKey(recordUuid)) {
        _mockOfflineSales[recordUuid]!['status'] = 'synced';
        if (serverInvoiceNumber != null) {
          _mockOfflineSales[recordUuid]!['invoice_number'] = serverInvoiceNumber;
        }
      }
      _mockSyncQueue.removeWhere((q) => q['record_uuid'] == recordUuid);
      return;
    }

    final db = await database;
    if (db == null) return;

    await db.transaction((txn) async {
      await txn.update(
        'offline_sales',
        {
          'status': 'synced',
          if (serverInvoiceNumber != null) 'invoice_number': serverInvoiceNumber,
        },
        where: 'uuid = ?',
        whereArgs: [recordUuid],
      );

      await txn.delete(
        'sync_queue',
        where: 'record_uuid = ?',
        whereArgs: [recordUuid],
      );
    });
  }

  /// Checkpoint management for delta pull
  Future<int> getCheckpointVersion(String key) async {
    if (isMockMode) {
      return _mockCheckpoints[key] ?? 0;
    }
    final db = await database;
    if (db == null) return 0;

    final result = await db.query(
      'sync_checkpoints',
      columns: ['version'],
      where: 'key = ?',
      whereArgs: [key],
    );
    if (result.isNotEmpty) {
      return (result.first['version'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }

  Future<void> setCheckpointVersion(String key, int version) async {
    final now = DateTime.now().toIso8601String();
    if (isMockMode) {
      _mockCheckpoints[key] = version;
      return;
    }
    final db = await database;
    if (db == null) return;

    await db.insert(
      'sync_checkpoints',
      {'key': key, 'version': version, 'last_synced_at': now},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
