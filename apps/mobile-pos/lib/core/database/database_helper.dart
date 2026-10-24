import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../data/models/category.dart';
import '../../data/models/customer.dart';
import '../../data/models/product.dart';
import '../../data/models/sale.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('smartshop_pos.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // If running on desktop (macOS / Linux / Windows) initialize FFI
    if (!kIsWeb && (Platform.isMacOS || Platform.isLinux || Platform.isWindows)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path;
    if (kIsWeb) {
      path = filePath;
    } else {
      try {
        final documentsDirectory = await getApplicationDocumentsDirectory();
        path = join(documentsDirectory.path, filePath);
      } catch (_) {
        path = inMemoryDatabasePath;
      }
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Products Table
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        sinhala_name TEXT,
        sku TEXT NOT NULL,
        barcode TEXT,
        unit TEXT DEFAULT 'piece',
        cost_price REAL DEFAULT 0.0,
        selling_price REAL NOT NULL,
        tax_rate REAL DEFAULT 0.0,
        min_stock_level REAL DEFAULT 5.0,
        stock_quantity REAL DEFAULT 0.0,
        category_uuid TEXT,
        category_name TEXT,
        warranty_period TEXT,
        requires_serial INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        version INTEGER DEFAULT 1
      )
    ''');

    // Indexes on products for sub-second barcode scans and searches
    await db.execute('CREATE INDEX idx_products_barcode ON products(barcode)');
    await db.execute('CREATE INDEX idx_products_category ON products(category_uuid)');
    await db.execute('CREATE INDEX idx_products_sku ON products(sku)');

    // 2. Categories Table
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        slug TEXT NOT NULL,
        display_order INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        version INTEGER DEFAULT 1
      )
    ''');

    // 3. Customers Table
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        loyalty_points INTEGER DEFAULT 0,
        credit_limit REAL DEFAULT 0.0,
        balance REAL DEFAULT 0.0,
        version INTEGER DEFAULT 1
      )
    ''');
    await db.execute('CREATE INDEX idx_customers_phone ON customers(phone)');

    // 4. Offline Sales Queue Table
    await db.execute('''
      CREATE TABLE offline_sales (
        transaction_uuid TEXT PRIMARY KEY,
        invoice_number TEXT NOT NULL,
        cashier_uuid TEXT NOT NULL,
        cashier_name TEXT NOT NULL,
        customer_uuid TEXT,
        customer_name TEXT,
        store_uuid TEXT NOT NULL,
        device_uuid TEXT NOT NULL,
        subtotal REAL NOT NULL,
        discount_amount REAL DEFAULT 0.0,
        tax_amount REAL DEFAULT 0.0,
        total_amount REAL NOT NULL,
        paid_amount REAL NOT NULL,
        change_amount REAL DEFAULT 0.0,
        sold_at TEXT NOT NULL,
        items_json TEXT NOT NULL,
        payments_json TEXT NOT NULL,
        sync_status TEXT DEFAULT 'pending',
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_sales_sync_status ON offline_sales(sync_status)');

    // 5. Sync Metadata
    await db.execute('''
      CREATE TABLE sync_meta (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  // --- Products Operations ---
  Future<List<ProductModel>> getAllProducts({String? categoryUuid, String? search}) async {
    final db = await database;
    String whereClause = 'is_active = 1';
    List<dynamic> whereArgs = [];

    if (categoryUuid != null && categoryUuid.isNotEmpty) {
      whereClause += ' AND category_uuid = ?';
      whereArgs.add(categoryUuid);
    }

    if (search != null && search.trim().isNotEmpty) {
      whereClause += ' AND (name LIKE ? OR sinhala_name LIKE ? OR barcode LIKE ? OR sku LIKE ?)';
      final q = '%${search.trim()}%';
      whereArgs.addAll([q, q, q, q]);
    }

    final result = await db.query(
      'products',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );

    return result.map((map) => ProductModel.fromDbMap(map)).toList();
  }

  Future<ProductModel?> findProductByBarcode(String barcode) async {
    final db = await database;
    final result = await db.query(
      'products',
      where: 'barcode = ? AND is_active = 1',
      whereArgs: [barcode],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return ProductModel.fromDbMap(result.first);
    }
    return null;
  }

  Future<void> upsertProducts(List<ProductModel> products) async {
    final db = await database;
    final batch = db.batch();
    for (final p in products) {
      batch.insert(
        'products',
        p.toDbMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  // --- Categories Operations ---
  Future<List<CategoryModel>> getAllCategories() async {
    final db = await database;
    final result = await db.query(
      'categories',
      where: 'is_active = 1',
      orderBy: 'display_order ASC, name ASC',
    );
    return result.map((map) => CategoryModel.fromDbMap(map)).toList();
  }

  Future<void> upsertCategories(List<CategoryModel> categories) async {
    final db = await database;
    final batch = db.batch();
    for (final c in categories) {
      batch.insert(
        'categories',
        c.toDbMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  // --- Customers Operations ---
  Future<List<CustomerModel>> searchCustomers(String query) async {
    final db = await database;
    final q = '%${query.trim()}%';
    final result = await db.query(
      'customers',
      where: 'name LIKE ? OR phone LIKE ?',
      whereArgs: [q, q],
      limit: 20,
    );
    return result.map((map) => CustomerModel.fromDbMap(map)).toList();
  }

  Future<void> upsertCustomers(List<CustomerModel> customers) async {
    final db = await database;
    final batch = db.batch();
    for (final c in customers) {
      batch.insert(
        'customers',
        c.toDbMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  // --- Sales & Offline Queue ---
  Future<void> insertSale(SaleModel sale) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        'offline_sales',
        sale.toDbMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Locally decrement stock for products
      for (final item in sale.items) {
        await txn.rawUpdate(
          'UPDATE products SET stock_quantity = stock_quantity - ? WHERE uuid = ?',
          [item.quantity, item.product.uuid],
        );
      }
    });
  }

  Future<List<SaleModel>> getPendingSales() async {
    final db = await database;
    final result = await db.query(
      'offline_sales',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
    );
    return result.map((m) => SaleModel.fromDbMap(m)).toList();
  }

  Future<void> markSalesSynced(List<String> transactionUuids) async {
    final db = await database;
    final batch = db.batch();
    for (final uuid in transactionUuids) {
      batch.update(
        'offline_sales',
        {'sync_status': 'synced'},
        where: 'transaction_uuid = ?',
        whereArgs: [uuid],
      );
    }
    await batch.commit(noResult: true);
  }

  // --- Sync Meta (Last Revision Version) ---
  Future<int> getLastSyncVersion() async {
    final db = await database;
    final result = await db.query(
      'sync_meta',
      where: 'key = ?',
      whereArgs: ['catalog_version'],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return int.tryParse(result.first['value'] as String? ?? '0') ?? 0;
    }
    return 0;
  }

  Future<void> setLastSyncVersion(int version) async {
    final db = await database;
    await db.insert(
      'sync_meta',
      {'key': 'catalog_version', 'value': version.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- Seed Demo Data (If empty on first run) ---
  Future<void> seedDemoCatalogIfEmpty() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM products'),
    );
    if (count != null && count > 0) return;

    final demoCategories = [
      const CategoryModel(uuid: 'cat-phones', name: 'Smartphones & Tech', slug: 'smartphones', displayOrder: 1),
      const CategoryModel(uuid: 'cat-audio', name: 'Audio & Wearables', slug: 'audio', displayOrder: 2),
      const CategoryModel(uuid: 'cat-power', name: 'Chargers & Cables', slug: 'power', displayOrder: 3),
      const CategoryModel(uuid: 'cat-grocery', name: 'Supermarket & Essentials', slug: 'groceries', displayOrder: 4),
    ];
    await upsertCategories(demoCategories);

    final demoProducts = [
      const ProductModel(
        uuid: 'prod-iphone-15',
        name: 'Apple iPhone 15 128GB Black',
        sinhalaName: 'ඇපල් අයිෆෝන් 15 කළු',
        sku: 'APL-IP15-128-BLK',
        barcode: '195949038234',
        sellingPrice: 285000.0,
        costPrice: 260000.0,
        taxRate: 0.0,
        stockQuantity: 12.0,
        categoryUuid: 'cat-phones',
        categoryName: 'Smartphones & Tech',
        warrantyPeriod: '1 Year Apple Care',
        requiresSerial: true,
      ),
      const ProductModel(
        uuid: 'prod-samsung-s24',
        name: 'Samsung Galaxy S24 256GB Gray',
        sinhalaName: 'සැම්සුන්ග් ගැලැක්සි S24',
        sku: 'SAM-S24-256-GRY',
        barcode: '880609531823',
        sellingPrice: 259000.0,
        costPrice: 235000.0,
        taxRate: 0.0,
        stockQuantity: 8.0,
        categoryUuid: 'cat-phones',
        categoryName: 'Smartphones & Tech',
        warrantyPeriod: '1 Year Samsung Warranty',
        requiresSerial: true,
      ),
      const ProductModel(
        uuid: 'prod-airpods-pro-2',
        name: 'Apple AirPods Pro 2 USB-C',
        sinhalaName: 'එයාපොඩ්ස් ප්‍රෝ 2',
        sku: 'APL-APP2-USBC',
        barcode: '195949052513',
        sellingPrice: 78500.0,
        costPrice: 69000.0,
        taxRate: 0.0,
        stockQuantity: 18.0,
        categoryUuid: 'cat-audio',
        categoryName: 'Audio & Wearables',
        warrantyPeriod: '1 Year Genxt Warranty',
        requiresSerial: true,
      ),
      const ProductModel(
        uuid: 'prod-anker-65w',
        name: 'Anker Nano II 65W GaN Fast Charger',
        sinhalaName: 'ඇන්කර් 65W චාජරය',
        sku: 'ANK-CHG-65W',
        barcode: '194644068524',
        sellingPrice: 13500.0,
        costPrice: 10500.0,
        taxRate: 0.0,
        stockQuantity: 35.0,
        categoryUuid: 'cat-power',
        categoryName: 'Chargers & Cables',
        warrantyPeriod: '18 Months Replacement',
        requiresSerial: false,
      ),
      const ProductModel(
        uuid: 'prod-anker-braided-c',
        name: 'Anker PowerLine Flow USB-C to USB-C 6ft',
        sinhalaName: 'ඇන්කර් ටයිප් C කේබලය',
        sku: 'ANK-CBL-FLOW',
        barcode: '194644078127',
        sellingPrice: 5200.0,
        costPrice: 3800.0,
        taxRate: 0.0,
        stockQuantity: 50.0,
        categoryUuid: 'cat-power',
        categoryName: 'Chargers & Cables',
        warrantyPeriod: '12 Months Warranty',
        requiresSerial: false,
      ),
      const ProductModel(
        uuid: 'prod-dilmah-tea',
        name: 'Dilmah Premium Ceylon Tea 200g',
        sinhalaName: 'දිල්මා සිලෝන් තේ 200g',
        sku: 'TEA-DLM-200G',
        barcode: '931263114221',
        sellingPrice: 1450.0,
        costPrice: 1100.0,
        taxRate: 0.0,
        stockQuantity: 100.0,
        categoryUuid: 'cat-grocery',
        categoryName: 'Supermarket & Essentials',
        requiresSerial: false,
      ),
    ];
    await upsertProducts(demoProducts);

    final demoCustomers = [
      const CustomerModel(
        uuid: 'cust-walkin',
        name: 'Walk-in Customer',
        phone: '0770000000',
        loyaltyPoints: 0,
        creditLimit: 0.0,
        balance: 0.0,
      ),
      const CustomerModel(
        uuid: 'cust-kasun',
        name: 'Kasun Perera',
        phone: '0771234567',
        email: 'kasun.p@example.com',
        loyaltyPoints: 450,
        creditLimit: 50000.0,
        balance: 0.0,
      ),
    ];
    await upsertCustomers(demoCustomers);
  }
}
