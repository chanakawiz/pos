class PosProduct {
  final int id;
  final String uuid;
  final String name;
  final String sku;
  final String barcode;
  final String category;
  final String brand;
  final double sellingPrice;
  final double costPrice;
  final int stock;
  final String unit;
  final String? warrantyPeriod;
  final bool requiresSerial;
  final String? imageUrl;
  final List<String> variants;

  const PosProduct({
    required this.id,
    required this.uuid,
    required this.name,
    required this.sku,
    required this.barcode,
    required this.category,
    required this.brand,
    required this.sellingPrice,
    this.costPrice = 0.0,
    required this.stock,
    this.unit = 'piece',
    this.warrantyPeriod,
    this.requiresSerial = false,
    this.imageUrl,
    this.variants = const [],
  });

  bool get inStock => stock > 0;
  bool get hasVariants => variants.isNotEmpty;

  factory PosProduct.fromJson(Map<String, dynamic> json) {
    return PosProduct(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      uuid: json['uuid'] ?? '',
      name: json['name'] ?? 'Product',
      sku: json['sku'] ?? '',
      barcode: json['barcode'] ?? '',
      category: json['category'] is Map
          ? (json['category']['name'] ?? '')
          : (json['category_name'] ?? json['category'] ?? 'General'),
      brand: json['brand'] is Map
          ? (json['brand']['name'] ?? '')
          : (json['brand_name'] ?? json['brand'] ?? 'OmniLuxe'),
      sellingPrice: (json['selling_price'] as num?)?.toDouble() ?? (json['price'] as num?)?.toDouble() ?? 0.0,
      costPrice: (json['cost_price'] as num?)?.toDouble() ?? 0.0,
      stock: (json['stock'] as num?)?.toInt() ?? (json['quantity'] as num?)?.toInt() ?? 10,
      unit: json['unit'] ?? 'piece',
      warrantyPeriod: json['warranty_period'],
      requiresSerial: json['requires_serial'] == true || json['requires_serial'] == 1,
      imageUrl: json['image_url'],
      variants: json['variants'] is List
          ? (json['variants'] as List).map((v) => v.toString()).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'uuid': uuid,
    'name': name,
    'sku': sku,
    'barcode': barcode,
    'category': category,
    'brand': brand,
    'selling_price': sellingPrice,
    'cost_price': costPrice,
    'stock': stock,
    'unit': unit,
    'warranty_period': warrantyPeriod,
    'requires_serial': requiresSerial,
    'image_url': imageUrl,
    'variants': variants,
  };
}
