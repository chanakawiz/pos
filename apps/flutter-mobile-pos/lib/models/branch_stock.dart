class BranchStock {
  final int storeId;
  final String storeCode;
  final String storeName;
  final String address;
  final String phone;
  final double quantityOnHand;
  final double quantityReserved;
  final double quantityAvailable;

  const BranchStock({
    required this.storeId,
    required this.storeCode,
    required this.storeName,
    required this.address,
    required this.phone,
    required this.quantityOnHand,
    this.quantityReserved = 0.0,
    required this.quantityAvailable,
  });

  bool get isOutOfStock => quantityAvailable <= 0;
  bool get isLowStock => quantityAvailable > 0 && quantityAvailable <= 5;
  bool get isInStock => quantityAvailable > 5;

  String get availabilityLabel {
    if (isOutOfStock) return 'Out of Stock';
    if (isLowStock) return 'Low Stock (${quantityAvailable.toInt()})';
    return 'In Stock (${quantityAvailable.toInt()})';
  }

  factory BranchStock.fromJson(Map<String, dynamic> json) {
    final onHand = (json['quantity_on_hand'] as num?)?.toDouble() ?? 0.0;
    final reserved = (json['quantity_reserved'] as num?)?.toDouble() ?? 0.0;
    final available = (json['quantity_available'] as num?)?.toDouble() ??
        (onHand - reserved).clamp(0.0, double.infinity);

    return BranchStock(
      storeId: (json['store_id'] as num?)?.toInt() ?? 0,
      storeCode: json['store_code']?.toString() ?? 'STORE',
      storeName: json['store_name']?.toString() ?? 'OmniLuxe Boutique',
      address: json['address']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      quantityOnHand: onHand,
      quantityReserved: reserved,
      quantityAvailable: available,
    );
  }
}
