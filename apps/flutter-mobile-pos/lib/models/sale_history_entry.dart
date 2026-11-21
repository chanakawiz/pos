import 'payment_tender.dart';
import 'pos_cart_item.dart';
import 'pos_product.dart';

class SaleHistoryItem {
  final int? id;
  final String uuid;
  final int productId;
  final String productName;
  final String sku;
  final String barcode;
  final int quantity;
  final double unitPrice;
  final double discount;
  final double total;
  final String? selectedVariant;
  final String? serialNumber;

  const SaleHistoryItem({
    this.id,
    required this.uuid,
    required this.productId,
    required this.productName,
    this.sku = '',
    this.barcode = '',
    required this.quantity,
    required this.unitPrice,
    this.discount = 0.0,
    required this.total,
    this.selectedVariant,
    this.serialNumber,
  });

  factory SaleHistoryItem.fromJson(Map<String, dynamic> json) {
    final prod = json['product'] is Map ? Map<String, dynamic>.from(json['product']) : null;
    final qty = (json['quantity'] as num?)?.toInt() ?? 1;
    final unitPrice = (json['unit_price'] as num?)?.toDouble() ?? 0.0;
    final discount = (json['discount_amount'] as num?)?.toDouble() ?? (json['discount'] as num?)?.toDouble() ?? 0.0;
    final total = (json['total'] as num?)?.toDouble() ?? ((unitPrice * qty) - discount).clamp(0.0, double.infinity);

    return SaleHistoryItem(
      id: (json['id'] as num?)?.toInt(),
      uuid: json['uuid']?.toString() ?? json['id']?.toString() ?? 'item-0',
      productId: (json['product_id'] as num?)?.toInt() ?? (prod?['id'] as num?)?.toInt() ?? 0,
      productName: json['product_name']?.toString() ?? prod?['name']?.toString() ?? 'OmniLuxe Item',
      sku: json['sku']?.toString() ?? prod?['sku']?.toString() ?? '',
      barcode: json['barcode']?.toString() ?? prod?['barcode']?.toString() ?? '',
      quantity: qty,
      unitPrice: unitPrice,
      discount: discount,
      total: total,
      selectedVariant: json['selected_variant']?.toString(),
      serialNumber: json['serial_number']?.toString(),
    );
  }

  PosCartItem toCartItem() {
    return PosCartItem(
      id: uuid,
      product: PosProduct(
        id: productId,
        uuid: 'prod-$productId',
        name: productName,
        sku: sku,
        barcode: barcode,
        category: 'General',
        brand: 'OmniLuxe',
        sellingPrice: unitPrice,
        stock: 1,
      ),
      quantity: quantity,
      unitPrice: unitPrice,
      discount: discount,
      selectedVariant: selectedVariant,
      serialNumber: serialNumber,
    );
  }
}

class SaleHistoryEntry {
  final String uuid;
  final String invoiceNumber;
  final String storeName;
  final String terminalCode;
  final String cashierName;
  final DateTime soldAt;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final double paidAmount;
  final double changeAmount;
  final String syncStatus; // 'synced', 'pending', 'refunded'
  final String? refundNumber;
  final double refundedAmount;
  final String? customerName;
  final String? customerPhone;
  final int loyaltyPointsEarned;
  final List<SaleHistoryItem> items;
  final List<PaymentTender> payments;

  const SaleHistoryEntry({
    required this.uuid,
    required this.invoiceNumber,
    required this.storeName,
    required this.terminalCode,
    required this.cashierName,
    required this.soldAt,
    required this.subtotal,
    this.discountAmount = 0.0,
    this.taxAmount = 0.0,
    required this.totalAmount,
    required this.paidAmount,
    this.changeAmount = 0.0,
    this.syncStatus = 'synced',
    this.refundNumber,
    this.refundedAmount = 0.0,
    this.customerName,
    this.customerPhone,
    this.loyaltyPointsEarned = 0,
    this.items = const [],
    this.payments = const [],
  });

  bool get isPending => syncStatus == 'pending';
  bool get isRefunded => syncStatus == 'refunded' || refundedAmount > 0;
  int get totalQuantity => items.fold(0, (sum, i) => sum + i.quantity);

  SaleHistoryEntry copyWith({
    String? syncStatus,
    String? refundNumber,
    double? refundedAmount,
  }) {
    return SaleHistoryEntry(
      uuid: uuid,
      invoiceNumber: invoiceNumber,
      storeName: storeName,
      terminalCode: terminalCode,
      cashierName: cashierName,
      soldAt: soldAt,
      subtotal: subtotal,
      discountAmount: discountAmount,
      taxAmount: taxAmount,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      changeAmount: changeAmount,
      syncStatus: syncStatus ?? this.syncStatus,
      refundNumber: refundNumber ?? this.refundNumber,
      refundedAmount: refundedAmount ?? this.refundedAmount,
      customerName: customerName,
      customerPhone: customerPhone,
      loyaltyPointsEarned: loyaltyPointsEarned,
      items: items,
      payments: payments,
    );
  }

  SaleReceipt toSaleReceipt() {
    return SaleReceipt(
      uuid: uuid,
      invoiceNumber: invoiceNumber,
      storeName: storeName,
      terminalCode: terminalCode,
      cashierName: cashierName,
      soldAt: soldAt,
      items: items.map((i) => i.toCartItem()).toList(),
      subtotal: subtotal,
      discountAmount: discountAmount,
      taxAmount: taxAmount,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      changeAmount: changeAmount,
      payments: payments,
      customerName: customerName,
      customerPhone: customerPhone,
      loyaltyPointsEarned: loyaltyPointsEarned,
      isOffline: isPending,
    );
  }

  static PosPaymentMethod parsePaymentMethod(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'card':
        return PosPaymentMethod.card;
      case 'credit':
      case 'gift_card':
        return PosPaymentMethod.giftCard;
      case 'bank_transfer':
      case 'lankaqr':
      case 'qr':
        return PosPaymentMethod.lankaQr;
      default:
        return PosPaymentMethod.cash;
    }
  }

  factory SaleHistoryEntry.fromReceipt(SaleReceipt receipt, {String syncStatus = 'synced'}) {
    return SaleHistoryEntry(
      uuid: receipt.uuid,
      invoiceNumber: receipt.invoiceNumber,
      storeName: receipt.storeName,
      terminalCode: receipt.terminalCode,
      cashierName: receipt.cashierName,
      soldAt: receipt.soldAt,
      subtotal: receipt.subtotal,
      discountAmount: receipt.discountAmount,
      taxAmount: receipt.taxAmount,
      totalAmount: receipt.totalAmount,
      paidAmount: receipt.paidAmount,
      changeAmount: receipt.changeAmount,
      syncStatus: receipt.isOffline ? 'pending' : syncStatus,
      customerName: receipt.customerName,
      customerPhone: receipt.customerPhone,
      loyaltyPointsEarned: receipt.loyaltyPointsEarned,
      items: receipt.items
          .map(
            (i) => SaleHistoryItem(
              uuid: i.id,
              productId: i.product.id,
              productName: i.product.name,
              sku: i.product.sku,
              barcode: i.product.barcode,
              quantity: i.quantity,
              unitPrice: i.unitPrice,
              discount: i.discount,
              total: i.total,
              selectedVariant: i.selectedVariant,
              serialNumber: i.serialNumber,
            ),
          )
          .toList(),
      payments: List.from(receipt.payments),
    );
  }

  factory SaleHistoryEntry.fromApiJson(Map<String, dynamic> json, {String defaultStore = 'OmniLuxe Flagship'}) {
    final cashier = json['cashier'] is Map ? Map<String, dynamic>.from(json['cashier']) : null;
    final customer = json['customer'] is Map ? Map<String, dynamic>.from(json['customer']) : null;
    final store = json['store'] is Map ? Map<String, dynamic>.from(json['store']) : null;

    final rawItems = (json['items'] as List?) ?? [];
    final items = rawItems.map((i) => SaleHistoryItem.fromJson(Map<String, dynamic>.from(i))).toList();

    final rawPayments = (json['payments'] as List?) ?? [];
    final payments = rawPayments.map((p) {
      final map = Map<String, dynamic>.from(p);
      return PaymentTender(
        method: parsePaymentMethod(map['payment_method']?.toString() ?? map['method']?.toString()),
        amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
        reference: map['reference']?.toString(),
      );
    }).toList();

    final statusRaw = (json['payment_status'] ?? json['status'] ?? 'synced').toString().toLowerCase();
    final syncStatus = statusRaw == 'refunded'
        ? 'refunded'
        : (statusRaw == 'pending' ? 'pending' : 'synced');

    return SaleHistoryEntry(
      uuid: json['uuid']?.toString() ?? json['transaction_uuid']?.toString() ?? 'sale-0',
      invoiceNumber: json['invoice_number']?.toString() ?? 'INV-UNKNOWN',
      storeName: store?['name']?.toString() ?? json['store_name']?.toString() ?? defaultStore,
      terminalCode: json['device_code']?.toString() ?? 'ROAMING-01',
      cashierName: cashier?['name']?.toString() ?? json['cashier_name']?.toString() ?? 'Cashier 01',
      soldAt: json['sold_at'] != null ? (DateTime.tryParse(json['sold_at'].toString()) ?? DateTime.now()) : DateTime.now(),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      changeAmount: (json['change_amount'] as num?)?.toDouble() ?? 0.0,
      syncStatus: syncStatus,
      refundNumber: json['refund_number']?.toString(),
      refundedAmount: (json['refunded_amount'] as num?)?.toDouble() ?? 0.0,
      customerName: customer?['name']?.toString() ?? json['customer_name']?.toString(),
      customerPhone: customer?['phone']?.toString() ?? json['customer_phone']?.toString(),
      loyaltyPointsEarned: (json['loyalty_points_earned'] as num?)?.toInt() ?? 0,
      items: items,
      payments: payments,
    );
  }
}

class RefundItemLine {
  final int? saleItemId;
  final String saleItemUuid;
  final String productName;
  final int quantity;
  final double unitPrice;

  const RefundItemLine({
    this.saleItemId,
    required this.saleItemUuid,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  double get lineTotal => quantity * unitPrice;

  Map<String, dynamic> toApiJson() => {
    if (saleItemId != null) 'sale_item_id': saleItemId,
    'sale_item_uuid': saleItemUuid,
    'quantity': quantity,
  };
}

class RefundRecord {
  final String uuid;
  final String refundNumber;
  final String saleUuid;
  final String invoiceNumber;
  final String storeName;
  final String terminalCode;
  final String cashierName;
  final String reason;
  final bool restocked;
  final double totalRefunded;
  final DateTime refundedAt;
  final List<RefundItemLine> items;
  final bool isOffline;

  const RefundRecord({
    required this.uuid,
    required this.refundNumber,
    required this.saleUuid,
    required this.invoiceNumber,
    required this.storeName,
    required this.terminalCode,
    required this.cashierName,
    required this.reason,
    this.restocked = true,
    required this.totalRefunded,
    required this.refundedAt,
    required this.items,
    this.isOffline = false,
  });
}
