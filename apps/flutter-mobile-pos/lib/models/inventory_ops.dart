class StocktakeLine {
  final int productId;
  final String productName;
  final String sku;
  final String barcode;
  final int expectedQty;
  final int countedQty;
  final double unitCost;

  const StocktakeLine({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.barcode,
    required this.expectedQty,
    required this.countedQty,
    this.unitCost = 0.0,
  });

  int get varianceQty => countedQty - expectedQty;
  double get varianceValue => varianceQty * unitCost;
  bool get isMatched => varianceQty == 0;
  bool get isOver => varianceQty > 0;
  bool get isShort => varianceQty < 0;

  StocktakeLine copyWith({int? countedQty}) {
    return StocktakeLine(
      productId: productId,
      productName: productName,
      sku: sku,
      barcode: barcode,
      expectedQty: expectedQty,
      countedQty: countedQty ?? this.countedQty,
      unitCost: unitCost,
    );
  }

  Map<String, dynamic> toApiJson() => {
    'product_id': productId,
    'barcode': barcode,
    'sku': sku,
    'counted_quantity': countedQty,
  };
}

class PurchaseOrderItemLine {
  final int productId;
  final String productName;
  final String sku;
  final String barcode;
  final int orderedQty;
  final int receivedQty;
  final double unitCost;

  const PurchaseOrderItemLine({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.barcode,
    required this.orderedQty,
    this.receivedQty = 0,
    this.unitCost = 0.0,
  });

  bool get isComplete => receivedQty >= orderedQty;
  int get remainingQty => (orderedQty - receivedQty).clamp(0, orderedQty);

  PurchaseOrderItemLine copyWith({int? receivedQty}) {
    return PurchaseOrderItemLine(
      productId: productId,
      productName: productName,
      sku: sku,
      barcode: barcode,
      orderedQty: orderedQty,
      receivedQty: receivedQty ?? this.receivedQty,
      unitCost: unitCost,
    );
  }

  factory PurchaseOrderItemLine.fromJson(Map<String, dynamic> json) {
    final product = json['product'] is Map ? Map<String, dynamic>.from(json['product']) : null;
    final ordered = (json['quantity'] as num?)?.toInt() ?? 1;
    return PurchaseOrderItemLine(
      productId: (json['product_id'] as num?)?.toInt() ?? (product?['id'] as num?)?.toInt() ?? 0,
      productName: json['product_name']?.toString() ?? product?['name']?.toString() ?? 'Catalog SKU',
      sku: json['sku']?.toString() ?? product?['sku']?.toString() ?? '',
      barcode: json['barcode']?.toString() ?? product?['barcode']?.toString() ?? '',
      orderedQty: ordered,
      receivedQty: (json['received_qty'] as num?)?.toInt() ?? 0,
      unitCost: (json['unit_cost'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toReceiveApiJson() => {
    'product_id': productId,
    'quantity': receivedQty,
  };
}

class PurchaseOrderRecord {
  final String uuid;
  final String purchaseNumber;
  final String supplierName;
  final String status; // 'ordered', 'received'
  final double totalAmount;
  final DateTime purchasedAt;
  final List<PurchaseOrderItemLine> items;

  const PurchaseOrderRecord({
    required this.uuid,
    required this.purchaseNumber,
    required this.supplierName,
    this.status = 'ordered',
    required this.totalAmount,
    required this.purchasedAt,
    required this.items,
  });

  bool get isReceived => status.toLowerCase() == 'received';
  int get totalOrderedUnits => items.fold(0, (s, i) => s + i.orderedQty);
  int get totalReceivedUnits => items.fold(0, (s, i) => s + i.receivedQty);

  PurchaseOrderRecord copyWith({
    String? status,
    List<PurchaseOrderItemLine>? items,
  }) {
    return PurchaseOrderRecord(
      uuid: uuid,
      purchaseNumber: purchaseNumber,
      supplierName: supplierName,
      status: status ?? this.status,
      totalAmount: totalAmount,
      purchasedAt: purchasedAt,
      items: items ?? this.items,
    );
  }

  factory PurchaseOrderRecord.fromApiJson(Map<String, dynamic> json) {
    final supplier = json['supplier'] is Map ? Map<String, dynamic>.from(json['supplier']) : null;
    final rawItems = (json['items'] as List?) ?? [];
    return PurchaseOrderRecord(
      uuid: json['uuid']?.toString() ?? 'po-local',
      purchaseNumber: json['purchase_number']?.toString() ?? 'PO-LOCAL',
      supplierName: supplier?['name']?.toString() ?? json['supplier_name']?.toString() ?? 'Authorized Distributor',
      status: json['status']?.toString() ?? 'ordered',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      purchasedAt: json['purchased_at'] != null
          ? (DateTime.tryParse(json['purchased_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      items: rawItems.map((e) => PurchaseOrderItemLine.fromJson(Map<String, dynamic>.from(e))).toList(),
    );
  }
}
