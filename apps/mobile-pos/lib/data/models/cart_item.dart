import 'product.dart';

class CartItemModel {
  final ProductModel product;
  final double quantity;
  final double unitPrice;
  final double discountAmount;
  final double taxRate;
  final String? serialNumber;
  final String? warrantyNotes;

  const CartItemModel({
    required this.product,
    this.quantity = 1.0,
    required this.unitPrice,
    this.discountAmount = 0.0,
    this.taxRate = 0.0,
    this.serialNumber,
    this.warrantyNotes,
  });

  double get subtotal => (unitPrice * quantity) - discountAmount;
  double get taxAmount => subtotal * (taxRate / 100);
  double get total => subtotal + taxAmount;

  CartItemModel copyWith({
    ProductModel? product,
    double? quantity,
    double? unitPrice,
    double? discountAmount,
    double? taxRate,
    String? serialNumber,
    String? warrantyNotes,
  }) {
    return CartItemModel(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discountAmount: discountAmount ?? this.discountAmount,
      taxRate: taxRate ?? this.taxRate,
      serialNumber: serialNumber ?? this.serialNumber,
      warrantyNotes: warrantyNotes ?? this.warrantyNotes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_uuid': product.uuid,
      'product_name': product.name,
      'sinhala_name': product.sinhalaName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount_amount': discountAmount,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'subtotal': subtotal,
      'total': total,
      'serial_number': serialNumber,
      'warranty_notes': warrantyNotes,
    };
  }

  Map<String, dynamic> toMap() {
    final map = toJson();
    map['product'] = product.toDbMap();
    return map;
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    ProductModel prod;
    if (map['product'] != null && map['product'] is Map<String, dynamic>) {
      prod = ProductModel.fromDbMap(map['product'] as Map<String, dynamic>);
    } else {
      prod = ProductModel(
        uuid: map['product_uuid']?.toString() ?? '',
        name: map['product_name']?.toString() ?? 'Product',
        sinhalaName: map['sinhala_name']?.toString(),
        sku: map['sku']?.toString() ?? '',
        sellingPrice: (map['unit_price'] as num?)?.toDouble() ?? 0.0,
      );
    }
    return CartItemModel.fromJson(map, prod);
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json, ProductModel product) {
    return CartItemModel(
      product: product,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 1.0,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? product.sellingPrice,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? product.taxRate,
      serialNumber: json['serial_number']?.toString(),
      warrantyNotes: json['warranty_notes']?.toString(),
    );
  }
}
