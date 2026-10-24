import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../data/models/category.dart';
import '../../data/models/customer.dart';
import '../../data/models/held_bill.dart';
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
      onOpen: (db) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS held_bills (
            uuid TEXT PRIMARY KEY,
            hold_reference TEXT NOT NULL,
            cashier_name TEXT NOT NULL,
            customer_name TEXT,
            customer_phone TEXT,
            customer_uuid TEXT,
            items_count INTEGER NOT NULL,
            subtotal REAL NOT NULL,
            held_at TEXT NOT NULL,
            cart_items_json TEXT NOT NULL
          )
        ''');
      },
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

    // 6. Held Bills Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS held_bills (
        uuid TEXT PRIMARY KEY,
        hold_reference TEXT NOT NULL,
        cashier_name TEXT NOT NULL,
        customer_name TEXT,
        customer_phone TEXT,
        customer_uuid TEXT,
        items_count INTEGER NOT NULL,
        subtotal REAL NOT NULL,
        held_at TEXT NOT NULL,
        cart_items_json TEXT NOT NULL
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

  Future<void> insertCustomer(CustomerModel customer) async {
    final db = await database;
    await db.insert(
      'customers',
      customer.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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

  Future<List<SaleModel>> getRecentSales({int limit = 50, String? search}) async {
    final db = await database;
    String? whereClause;
    List<dynamic>? whereArgs;

    if (search != null && search.trim().isNotEmpty) {
      whereClause = 'invoice_number LIKE ? OR customer_name LIKE ?';
      final q = '%${search.trim()}%';
      whereArgs = [q, q];
    }

    final result = await db.query(
      'offline_sales',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return result.map((m) => SaleModel.fromDbMap(m)).toList();
  }

  Future<Map<String, dynamic>> getShiftSummary() async {
    final db = await database;
    final sales = await db.query('offline_sales', orderBy: 'created_at DESC');

    int count = sales.length;
    double gross = 0.0;
    double cash = 0.0;
    double card = 0.0;
    double bank = 0.0;
    double tax = 0.0;
    double discount = 0.0;

    for (final row in sales) {
      final sale = SaleModel.fromDbMap(row);
      gross += sale.totalAmount;
      tax += sale.taxAmount;
      discount += sale.discountAmount;

      for (final p in sale.payments) {
        if (p.method == PaymentMethod.cash) {
          cash += p.amount;
        } else if (p.method == PaymentMethod.card) {
          card += p.amount;
        } else if (p.method == PaymentMethod.bankTransfer) {
          bank += p.amount;
        }
      }
    }

    return {
      'totalSalesCount': count,
      'grossTotal': gross,
      'cashTotal': cash,
      'cardTotal': card,
      'bankTotal': bank,
      'taxTotal': tax,
      'discountTotal': discount,
    };
  }

  // --- Held Bills Operations ---
  Future<void> insertHeldBill(HeldBillModel bill) async {
    final db = await database;
    await db.insert(
      'held_bills',
      bill.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<HeldBillModel>> getAllHeldBills() async {
    final db = await database;
    final result = await db.query(
      'held_bills',
      orderBy: 'held_at DESC',
    );
    return result.map((m) => HeldBillModel.fromMap(m)).toList();
  }

  Future<void> deleteHeldBill(String uuid) async {
    final db = await database;
    await db.delete(
      'held_bills',
      where: 'uuid = ?',
      whereArgs: [uuid],
    );
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

  // --- Seed Demo Data (Multi-Vertical Retail Solution) ---
  Future<void> seedDemoCatalogIfEmpty({bool forceRefresh = false}) async {
    final db = await database;
    if (!forceRefresh) {
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM products'),
      );
      if (count != null && count >= 10) return;
    }

    final demoCategories = [
      const CategoryModel(uuid: 'cat-tech', name: 'Smartphones & Tech', slug: 'smartphones-tech', displayOrder: 1),
      const CategoryModel(uuid: 'cat-fashion', name: 'Designer Fashion & Apparel', slug: 'designer-fashion-apparel', displayOrder: 2),
      const CategoryModel(uuid: 'cat-footwear', name: 'Footwear & Sneakers', slug: 'footwear-sneakers', displayOrder: 3),
      const CategoryModel(uuid: 'cat-vehicles', name: 'Vehicles & Luxury Automotive', slug: 'vehicles-luxury-auto', displayOrder: 4),
    ];
    await upsertCategories(demoCategories);

    final demoProducts = [
      // 1. Smartphones & Tech
      const ProductModel(
        uuid: 'prod-iphone-16pm',
        name: 'Apple iPhone 16 Pro Max 256GB (Space Black)',
        sinhalaName: 'ඇපල් අයිෆෝන් 16 ප්‍රෝ මැක්ස් 256GB',
        sku: 'TECH-IPH-16PM',
        barcode: '445566',
        sellingPrice: 415000.0,
        costPrice: 370000.0,
        taxRate: 0.0,
        stockQuantity: 15.0,
        categoryUuid: 'cat-tech',
        categoryName: 'Smartphones & Tech',
        warrantyPeriod: '1 Year Apple Care',
        requiresSerial: true,
      ),
      const ProductModel(
        uuid: 'prod-iphone-15',
        name: 'Apple iPhone 15 Pro 128GB (Natural Titanium)',
        sinhalaName: 'ඇපල් අයිෆෝන් 15 ප්‍රෝ 128GB',
        sku: 'TECH-IPH-15P',
        barcode: '195949038234',
        sellingPrice: 345000.0,
        costPrice: 310000.0,
        taxRate: 0.0,
        stockQuantity: 10.0,
        categoryUuid: 'cat-tech',
        categoryName: 'Smartphones & Tech',
        warrantyPeriod: '1 Year Apple Care',
        requiresSerial: true,
      ),
      const ProductModel(
        uuid: 'prod-samsung-s24u',
        name: 'Samsung Galaxy S24 Ultra 512GB (Titanium Gray)',
        sinhalaName: 'සැම්සුන්ග් ගැලැක්සි S24 අල්ට්‍රා 512GB',
        sku: 'TECH-SAM-S24U',
        barcode: '556677',
        sellingPrice: 385000.0,
        costPrice: 340000.0,
        taxRate: 0.0,
        stockQuantity: 12.0,
        categoryUuid: 'cat-tech',
        categoryName: 'Smartphones & Tech',
        warrantyPeriod: '1 Year Samsung Care+',
        requiresSerial: true,
      ),
      const ProductModel(
        uuid: 'prod-airpods-pro-2',
        name: 'Apple AirPods Pro 2 (USB-C MagSafe)',
        sinhalaName: 'එයාපොඩ්ස් ප්‍රෝ 2 USB-C',
        sku: 'TECH-APP-APP2',
        barcode: '667788',
        sellingPrice: 78500.0,
        costPrice: 68000.0,
        taxRate: 0.0,
        stockQuantity: 25.0,
        categoryUuid: 'cat-tech',
        categoryName: 'Smartphones & Tech',
        warrantyPeriod: '1 Year Genxt Warranty',
        requiresSerial: true,
      ),
      const ProductModel(
        uuid: 'prod-watch-ultra-2',
        name: 'Apple Watch Ultra 2 (Titanium GPS + Cellular)',
        sinhalaName: 'ඇපල් වොච් අල්ට්‍රා 2 ටයිටේනියම්',
        sku: 'TECH-APP-WCHULT2',
        barcode: '667799',
        sellingPrice: 275000.0,
        costPrice: 240000.0,
        taxRate: 0.0,
        stockQuantity: 8.0,
        categoryUuid: 'cat-tech',
        categoryName: 'Smartphones & Tech',
        warrantyPeriod: '1 Year Official Warranty',
        requiresSerial: true,
      ),
      const ProductModel(
        uuid: 'prod-anker-65w',
        name: 'Anker Nano II 65W GaN Fast Charger',
        sinhalaName: 'ඇන්කර් 65W GaN චාජරය',
        sku: 'TECH-ANK-65W',
        barcode: '990011',
        sellingPrice: 13500.0,
        costPrice: 9500.0,
        taxRate: 0.0,
        stockQuantity: 45.0,
        categoryUuid: 'cat-tech',
        categoryName: 'Smartphones & Tech',
        warrantyPeriod: '18 Months Replacement',
        requiresSerial: false,
      ),

      // 2. Designer Fashion & Apparel
      const ProductModel(
        uuid: 'prod-linen-shirt',
        name: 'The Everyday Linen Shirt (Relaxed Fit)',
        sinhalaName: 'සැහැල්ලු ලිනන් කමිසය',
        sku: 'APP-LIN-SHT01',
        barcode: '112233',
        sellingPrice: 6900.0,
        costPrice: 4200.0,
        taxRate: 0.0,
        stockQuantity: 50.0,
        categoryUuid: 'cat-fashion',
        categoryName: 'Designer Fashion & Apparel',
        requiresSerial: false,
      ),
      const ProductModel(
        uuid: 'prod-midi-dress',
        name: 'Sunday Midi Linen Dress (Warm Ivory)',
        sinhalaName: 'සන්ඩේ ලිනන් මිඩි ඇඳුම',
        sku: 'APP-DRS-MID01',
        barcode: '887766',
        sellingPrice: 8900.0,
        costPrice: 5500.0,
        taxRate: 0.0,
        stockQuantity: 30.0,
        categoryUuid: 'cat-fashion',
        categoryName: 'Designer Fashion & Apparel',
        requiresSerial: false,
      ),
      const ProductModel(
        uuid: 'prod-wool-blazer',
        name: 'Italian Tailored Wool Blazer (Charcoal)',
        sinhalaName: 'ඉතාලි විලාසිතාවේ බ්ලේසරය',
        sku: 'APP-BLZ-CHR01',
        barcode: '223344',
        sellingPrice: 24500.0,
        costPrice: 16000.0,
        taxRate: 0.0,
        stockQuantity: 18.0,
        categoryUuid: 'cat-fashion',
        categoryName: 'Designer Fashion & Apparel',
        requiresSerial: false,
      ),
      const ProductModel(
        uuid: 'prod-rl-polo',
        name: 'Ralph Lauren Custom Slim Fit Mesh Polo',
        sinhalaName: 'රැල්ෆ් ලෝරන් කස්ටම් පොලෝ',
        sku: 'APP-RL-POLO01',
        barcode: '223355',
        sellingPrice: 28500.0,
        costPrice: 18000.0,
        taxRate: 0.0,
        stockQuantity: 25.0,
        categoryUuid: 'cat-fashion',
        categoryName: 'Designer Fashion & Apparel',
        requiresSerial: false,
      ),
      const ProductModel(
        uuid: 'prod-levis-501',
        name: 'Levi\'s 501 Original Fit Denim Jeans',
        sinhalaName: 'ලෙවීස් 501 ඔරිජිනල් ඩෙනිම්',
        sku: 'APP-DNM-501',
        barcode: '334455',
        sellingPrice: 14500.0,
        costPrice: 9500.0,
        taxRate: 0.0,
        stockQuantity: 40.0,
        categoryUuid: 'cat-fashion',
        categoryName: 'Designer Fashion & Apparel',
        requiresSerial: false,
      ),

      // 3. Footwear & Sneakers
      const ProductModel(
        uuid: 'prod-nike-peg40',
        name: 'Nike Air Zoom Pegasus 40 Running Shoes',
        sinhalaName: 'නයික් එයාර් සූම් පෙගසස් 40',
        sku: 'FTW-NIK-PEG40',
        barcode: '789012',
        sellingPrice: 38500.0,
        costPrice: 26000.0,
        taxRate: 0.0,
        stockQuantity: 28.0,
        categoryUuid: 'cat-footwear',
        categoryName: 'Footwear & Sneakers',
        warrantyPeriod: '6 Months Guarantee',
        requiresSerial: false,
      ),
      const ProductModel(
        uuid: 'prod-adidas-ub',
        name: 'Adidas Ultraboost Light Running Shoes',
        sinhalaName: 'ඇඩිඩාස් අල්ට්‍රාබූස්ට් ලයිට්',
        sku: 'FTW-ADI-UB01',
        barcode: '890123',
        sellingPrice: 42000.0,
        costPrice: 29000.0,
        taxRate: 0.0,
        stockQuantity: 20.0,
        categoryUuid: 'cat-footwear',
        categoryName: 'Footwear & Sneakers',
        warrantyPeriod: '6 Months Guarantee',
        requiresSerial: false,
      ),
      const ProductModel(
        uuid: 'prod-clarks-oxford',
        name: 'Clarks Batcombe Lord Leather Oxford',
        sinhalaName: 'ක්ලාක්ස් ලෙදර් ඔක්ස්ෆර්ඩ් සපත්තු',
        sku: 'FTW-CLK-OXF01',
        barcode: '123456',
        sellingPrice: 29500.0,
        costPrice: 19500.0,
        taxRate: 0.0,
        stockQuantity: 22.0,
        categoryUuid: 'cat-footwear',
        categoryName: 'Footwear & Sneakers',
        warrantyPeriod: '1 Year Leather Care',
        requiresSerial: false,
      ),
      const ProductModel(
        uuid: 'prod-puma-suede',
        name: 'Puma Suede Classic XXI Heritage Shoes',
        sinhalaName: 'පූමා ස්වේඩ් ක්ලැසික් සපත්තු',
        sku: 'FTW-PUM-SUD01',
        barcode: '123457',
        sellingPrice: 26500.0,
        costPrice: 18000.0,
        taxRate: 0.0,
        stockQuantity: 25.0,
        categoryUuid: 'cat-footwear',
        categoryName: 'Footwear & Sneakers',
        warrantyPeriod: '6 Months Guarantee',
        requiresSerial: false,
      ),

      // 4. Vehicles & Luxury Automotive
      const ProductModel(
        uuid: 'prod-toyota-prado',
        name: 'Toyota Land Cruiser Prado 250 (2025 Hybrid)',
        sinhalaName: 'ටොයෝටා ලෑන්ඩ් කෲසර් ප්‍රාඩෝ 250',
        sku: 'AUTO-TOY-PRADO250',
        barcode: '900001',
        sellingPrice: 48500000.0,
        costPrice: 42000000.0,
        taxRate: 0.0,
        stockQuantity: 3.0,
        categoryUuid: 'cat-vehicles',
        categoryName: 'Vehicles & Luxury Automotive',
        warrantyPeriod: '3 Years / 100,000 km Warranty',
        requiresSerial: true, // VIN / Chassis Number
      ),
      const ProductModel(
        uuid: 'prod-defender-110',
        name: 'Land Rover Defender 110 X-Dynamic HSE',
        sinhalaName: 'ලෑන්ඩ් රෝවර් ඩිෆෙන්ඩර් 110',
        sku: 'AUTO-LRV-DEF110',
        barcode: '900002',
        sellingPrice: 62000000.0,
        costPrice: 54000000.0,
        taxRate: 0.0,
        stockQuantity: 2.0,
        categoryUuid: 'cat-vehicles',
        categoryName: 'Vehicles & Luxury Automotive',
        warrantyPeriod: '3 Years Warranty',
        requiresSerial: true, // VIN Number
      ),
      const ProductModel(
        uuid: 'prod-byd-seal',
        name: 'BYD Seal EV Performance AWD (82.5 kWh)',
        sinhalaName: 'බී.වයි.ඩී සීල් සුපිරි විදුලි මෝටර් රථය',
        sku: 'AUTO-BYD-SEAL01',
        barcode: '900003',
        sellingPrice: 19800000.0,
        costPrice: 17000000.0,
        taxRate: 0.0,
        stockQuantity: 4.0,
        categoryUuid: 'cat-vehicles',
        categoryName: 'Vehicles & Luxury Automotive',
        warrantyPeriod: '8 Years Battery Warranty',
        requiresSerial: true, // Battery Serial / VIN
      ),
      const ProductModel(
        uuid: 'prod-honda-civic',
        name: 'Honda Civic RS Turbo (Sport Edition)',
        sinhalaName: 'හොන්ඩා සිවික් ආර්.එස් ටර්බෝ',
        sku: 'AUTO-HND-CIVICRS',
        barcode: '900004',
        sellingPrice: 16500000.0,
        costPrice: 14500000.0,
        taxRate: 0.0,
        stockQuantity: 3.0,
        categoryUuid: 'cat-vehicles',
        categoryName: 'Vehicles & Luxury Automotive',
        warrantyPeriod: '3 Years Official Warranty',
        requiresSerial: true,
      ),
      const ProductModel(
        uuid: 'prod-toyota-brakepads',
        name: 'Toyota Genuine Ceramic Brake Pad Set & Hybrid Filter',
        sinhalaName: 'ටොයෝටා ඔරිජිනල් බ්‍රේක් පෑඩ් කට්ටලය',
        sku: 'AUTO-TOY-BRK01',
        barcode: '900005',
        sellingPrice: 35000.0,
        costPrice: 24000.0,
        taxRate: 0.0,
        stockQuantity: 20.0,
        categoryUuid: 'cat-vehicles',
        categoryName: 'Vehicles & Luxury Automotive',
        warrantyPeriod: '1 Year Parts Guarantee',
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
        name: 'Kasun Fernando',
        phone: '0771234567',
        email: 'kasun.f@example.lk',
        loyaltyPoints: 320,
        creditLimit: 250000.0,
        balance: 0.0,
      ),
    ];
    await upsertCustomers(demoCustomers);
  }
}
