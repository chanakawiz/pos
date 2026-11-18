import 'package:uuid/uuid.dart';
import 'pos_product.dart';

class PosCartItem {
  final String id;
  final PosProduct product;
  final int quantity;
  final double unitPrice;
  final double discount;
  final String? selectedVariant;
  final String? serialNumber;

  PosCartItem({
    String? id,
    required this.product,
    this.quantity = 1,
    double? unitPrice,
    this.discount = 0.0,
    this.selectedVariant,
    this.serialNumber,
  })  : id = id ?? const Uuid().v4(),
        unitPrice = unitPrice ?? product.sellingPrice;

  double get subtotal => unitPrice * quantity;
  double get total => (subtotal - discount).clamp(0.0, double.infinity);

  PosCartItem copyWith({
    String? id,
    PosProduct? product,
    int? quantity,
    double? unitPrice,
    double? discount,
    String? selectedVariant,
    String? serialNumber,
  }) {
    return PosCartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discount: discount ?? this.discount,
      selectedVariant: selectedVariant ?? this.selectedVariant,
      serialNumber: serialNumber ?? this.serialNumber,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': product.id,
    'product_name': product.name,
    'barcode': product.barcode,
    'quantity': quantity,
    'unit_price': unitPrice,
    'discount': discount,
    'total': total,
    'selected_variant': selectedVariant,
    'serial_number': serialNumber,
  };

  factory PosCartItem.fromJson(Map<String, dynamic> json, PosProduct product) {
    return PosCartItem(
      id: json['id'],
      product: product,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? product.sellingPrice,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      selectedVariant: json['selected_variant'],
      serialNumber: json['serial_number'],
    );
  }
}
