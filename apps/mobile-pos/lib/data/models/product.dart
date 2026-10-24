class ProductModel {
  final int? id;
  final String uuid;
  final String name;
  final String? sinhalaName;
  final String sku;
  final String? barcode;
  final String unit;
  final double costPrice;
  final double sellingPrice;
  final double taxRate;
  final double minStockLevel;
  final double stockQuantity;
  final String? categoryUuid;
  final String? categoryName;
  final String? warrantyPeriod;
  final bool requiresSerial;
  final bool isActive;
  final int version;

  const ProductModel({
    this.id,
    required this.uuid,
    required this.name,
    this.sinhalaName,
    required this.sku,
    this.barcode,
    this.unit = 'piece',
    this.costPrice = 0.0,
    required this.sellingPrice,
    this.taxRate = 0.0,
    this.minStockLevel = 5.0,
    this.stockQuantity = 0.0,
    this.categoryUuid,
    this.categoryName,
    this.warrantyPeriod,
    this.requiresSerial = false,
    this.isActive = true,
    this.version = 1,
  });

  /// Display name respecting bilingual representation
  String getDisplayName({bool bilingual = true}) {
    if (bilingual && sinhalaName != null && sinhalaName!.trim().isNotEmpty) {
      return '$name ($sinhalaName)';
    }
    return name;
  }

  bool get isLowStock => stockQuantity <= minStockLevel;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    String? catUuid;
    String? catName;
    if (json['category'] is Map) {
      catUuid = json['category']['uuid']?.toString();
      catName = json['category']['name']?.toString();
    } else if (json['category_name'] != null) {
      catName = json['category_name']?.toString();
      catUuid = json['category_uuid']?.toString();
    }

    return ProductModel(
      id: json['id'] is int ? json['id'] : null,
      uuid: json['uuid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      sinhalaName: json['sinhala_name']?.toString(),
      sku: json['sku']?.toString() ?? '',
      barcode: json['barcode']?.toString(),
      unit: json['unit']?.toString() ?? 'piece',
      costPrice: (json['cost_price'] is num) ? (json['cost_price'] as num).toDouble() : 0.0,
      sellingPrice: (json['selling_price'] is num) ? (json['selling_price'] as num).toDouble() : 0.0,
      taxRate: (json['tax_rate'] is num) ? (json['tax_rate'] as num).toDouble() : 0.0,
      minStockLevel: (json['min_stock_level'] is num) ? (json['min_stock_level'] as num).toDouble() : 5.0,
      stockQuantity: (json['stock_quantity'] is num) ? (json['stock_quantity'] as num).toDouble() : 0.0,
      categoryUuid: catUuid,
      categoryName: catName,
      warrantyPeriod: json['warranty_period']?.toString(),
      requiresSerial: json['requires_serial'] == true || json['requires_serial'] == 1,
      isActive: json['is_active'] == null || json['is_active'] == true || json['is_active'] == 1,
      version: json['version'] is int ? json['version'] : 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'sinhala_name': sinhalaName,
      'sku': sku,
      'barcode': barcode,
      'unit': unit,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
      'tax_rate': taxRate,
      'min_stock_level': minStockLevel,
      'stock_quantity': stockQuantity,
      'category_uuid': categoryUuid,
      'category_name': categoryName,
      'warranty_period': warrantyPeriod,
      'requires_serial': requiresSerial ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'version': version,
    };
  }

  factory ProductModel.fromDbMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as int?,
      uuid: map['uuid'] as String,
      name: map['name'] as String,
      sinhalaName: map['sinhala_name'] as String?,
      sku: map['sku'] as String,
      barcode: map['barcode'] as String?,
      unit: map['unit'] as String? ?? 'piece',
      costPrice: (map['cost_price'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (map['selling_price'] as num?)?.toDouble() ?? 0.0,
      taxRate: (map['tax_rate'] as num?)?.toDouble() ?? 0.0,
      minStockLevel: (map['min_stock_level'] as num?)?.toDouble() ?? 5.0,
      stockQuantity: (map['stock_quantity'] as num?)?.toDouble() ?? 0.0,
      categoryUuid: map['category_uuid'] as String?,
      categoryName: map['category_name'] as String?,
      warrantyPeriod: map['warranty_period'] as String?,
      requiresSerial: (map['requires_serial'] == 1),
      isActive: (map['is_active'] != 0),
      version: (map['version'] as int?) ?? 1,
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'uuid': uuid,
      'name': name,
      'sinhala_name': sinhalaName,
      'sku': sku,
      'barcode': barcode,
      'unit': unit,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
      'tax_rate': taxRate,
      'min_stock_level': minStockLevel,
      'stock_quantity': stockQuantity,
      'category_uuid': categoryUuid,
      'category_name': categoryName,
      'warranty_period': warrantyPeriod,
      'requires_serial': requiresSerial ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'version': version,
    };
  }
}
