import 'dart:convert';
import 'cart_item.dart';

class HeldBillModel {
  final String uuid;
  final String holdReference;
  final String cashierName;
  final String? customerName;
  final String? customerPhone;
  final String? customerUuid;
  final int itemsCount;
  final double subtotal;
  final DateTime heldAt;
  final List<CartItemModel> items;

  const HeldBillModel({
    required this.uuid,
    required this.holdReference,
    required this.cashierName,
    this.customerName,
    this.customerPhone,
    this.customerUuid,
    required this.itemsCount,
    required this.subtotal,
    required this.heldAt,
    required this.items,
  });

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'hold_reference': holdReference,
      'cashier_name': cashierName,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_uuid': customerUuid,
      'items_count': itemsCount,
      'subtotal': subtotal,
      'held_at': heldAt.toIso8601String(),
      'cart_items_json': jsonEncode(items.map((i) => i.toMap()).toList()),
    };
  }

  factory HeldBillModel.fromMap(Map<String, dynamic> map) {
    List<CartItemModel> parsedItems = [];
    if (map['cart_items_json'] != null) {
      dynamic raw = map['cart_items_json'];
      if (raw is String) {
        try {
          raw = jsonDecode(raw);
        } catch (_) {}
      }
      if (raw is List) {
        parsedItems = raw.map((item) => CartItemModel.fromMap(item as Map<String, dynamic>)).toList();
      }
    }

    return HeldBillModel(
      uuid: map['uuid'] as String? ?? '',
      holdReference: map['hold_reference'] as String? ?? 'HOLD-BILL',
      cashierName: map['cashier_name'] as String? ?? 'Cashier',
      customerName: map['customer_name'] as String?,
      customerPhone: map['customer_phone'] as String?,
      customerUuid: map['customer_uuid'] as String?,
      itemsCount: (map['items_count'] as num?)?.toInt() ?? parsedItems.length,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      heldAt: map['held_at'] != null ? DateTime.parse(map['held_at'] as String) : DateTime.now(),
      items: parsedItems,
    );
  }

  HeldBillModel copyWith({
    String? uuid,
    String? holdReference,
    String? cashierName,
    String? customerName,
    String? customerPhone,
    String? customerUuid,
    int? itemsCount,
    double? subtotal,
    DateTime? heldAt,
    List<CartItemModel>? items,
  }) {
    return HeldBillModel(
      uuid: uuid ?? this.uuid,
      holdReference: holdReference ?? this.holdReference,
      cashierName: cashierName ?? this.cashierName,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerUuid: customerUuid ?? this.customerUuid,
      itemsCount: itemsCount ?? this.itemsCount,
      subtotal: subtotal ?? this.subtotal,
      heldAt: heldAt ?? this.heldAt,
      items: items ?? this.items,
    );
  }
}
