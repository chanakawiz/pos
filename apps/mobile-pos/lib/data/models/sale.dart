import 'dart:convert';
import 'cart_item.dart';
import 'product.dart';

enum PaymentMethod { cash, card, bankTransfer, credit }

class PaymentModel {
  final PaymentMethod method;
  final double amount;
  final String? referenceNumber;

  const PaymentModel({
    required this.method,
    required this.amount,
    this.referenceNumber,
  });

  String get methodString {
    switch (method) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.card:
        return 'card';
      case PaymentMethod.bankTransfer:
        return 'bank_transfer';
      case PaymentMethod.credit:
        return 'credit';
    }
  }

  static PaymentMethod fromString(String val) {
    switch (val) {
      case 'card':
        return PaymentMethod.card;
      case 'bank_transfer':
        return PaymentMethod.bankTransfer;
      case 'credit':
        return PaymentMethod.credit;
      case 'cash':
      default:
        return PaymentMethod.cash;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'payment_method': methodString,
      'amount': amount,
      'reference_number': referenceNumber,
    };
  }

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      method: fromString(json['payment_method']?.toString() ?? 'cash'),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      referenceNumber: json['reference_number']?.toString(),
    );
  }
}

class SaleModel {
  final String transactionUuid;
  final String invoiceNumber;
  final String cashierUuid;
  final String cashierName;
  final String? customerUuid;
  final String? customerName;
  final String storeUuid;
  final String deviceUuid;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final double paidAmount;
  final double changeAmount;
  final DateTime soldAt;
  final List<CartItemModel> items;
  final List<PaymentModel> payments;
  final String syncStatus; // 'pending' | 'synced'

  const SaleModel({
    required this.transactionUuid,
    required this.invoiceNumber,
    required this.cashierUuid,
    required this.cashierName,
    this.customerUuid,
    this.customerName,
    required this.storeUuid,
    required this.deviceUuid,
    required this.subtotal,
    this.discountAmount = 0.0,
    this.taxAmount = 0.0,
    required this.totalAmount,
    required this.paidAmount,
    this.changeAmount = 0.0,
    required this.soldAt,
    required this.items,
    required this.payments,
    this.syncStatus = 'pending',
  });

  Map<String, dynamic> toJson() {
    return {
      'transaction_uuid': transactionUuid,
      'invoice_number': invoiceNumber,
      'cashier_uuid': cashierUuid,
      'cashier_name': cashierName,
      'customer_uuid': customerUuid,
      'customer_name': customerName,
      'store_uuid': storeUuid,
      'device_uuid': deviceUuid,
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'change_amount': changeAmount,
      'sold_at': soldAt.toIso8601String(),
      'items': items.map((i) => i.toJson()).toList(),
      'payments': payments.map((p) => p.toJson()).toList(),
      'sync_status': syncStatus,
    };
  }

  Map<String, dynamic> toDbMap() {
    return {
      'transaction_uuid': transactionUuid,
      'invoice_number': invoiceNumber,
      'cashier_uuid': cashierUuid,
      'cashier_name': cashierName,
      'customer_uuid': customerUuid,
      'customer_name': customerName,
      'store_uuid': storeUuid,
      'device_uuid': deviceUuid,
      'subtotal': subtotal,
      'discount_amount': discountAmount,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'change_amount': changeAmount,
      'sold_at': soldAt.toIso8601String(),
      'items_json': jsonEncode(items.map((i) => i.toJson()).toList()),
      'payments_json': jsonEncode(payments.map((p) => p.toJson()).toList()),
      'sync_status': syncStatus,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  factory SaleModel.fromDbMap(Map<String, dynamic> map) {
    final rawItems = jsonDecode(map['items_json'] as String) as List;
    final parsedItems = rawItems.map((item) {
      final itemMap = item as Map<String, dynamic>;
      final product = ProductModel(
        uuid: itemMap['product_uuid']?.toString() ?? '',
        name: itemMap['product_name']?.toString() ?? 'Product',
        sinhalaName: itemMap['sinhala_name']?.toString(),
        sku: '',
        sellingPrice: (itemMap['unit_price'] as num?)?.toDouble() ?? 0.0,
      );
      return CartItemModel.fromJson(itemMap, product);
    }).toList();

    final rawPayments = jsonDecode(map['payments_json'] as String) as List;
    final parsedPayments = rawPayments
        .map((p) => PaymentModel.fromJson(p as Map<String, dynamic>))
        .toList();

    return SaleModel(
      transactionUuid: map['transaction_uuid'] as String,
      invoiceNumber: map['invoice_number'] as String,
      cashierUuid: map['cashier_uuid'] as String,
      cashierName: map['cashier_name'] as String,
      customerUuid: map['customer_uuid'] as String?,
      customerName: map['customer_name'] as String?,
      storeUuid: map['store_uuid'] as String,
      deviceUuid: map['device_uuid'] as String,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (map['discount_amount'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0.0,
      changeAmount: (map['change_amount'] as num?)?.toDouble() ?? 0.0,
      soldAt: DateTime.parse(map['sold_at'] as String),
      items: parsedItems,
      payments: parsedPayments,
      syncStatus: map['sync_status'] as String? ?? 'pending',
    );
  }
}
