import 'package:uuid/uuid.dart';
import 'pos_cart_item.dart';

enum PosPaymentMethod {
  cash,
  card,
  giftCard,
  lankaQr;

  String get displayName {
    switch (this) {
      case PosPaymentMethod.cash:
        return 'Cash';
      case PosPaymentMethod.card:
        return 'Card / mPOS';
      case PosPaymentMethod.giftCard:
        return 'VIP Gift Card';
      case PosPaymentMethod.lankaQr:
        return 'LankaQR';
    }
  }

  String get apiValue {
    switch (this) {
      case PosPaymentMethod.cash:
        return 'cash';
      case PosPaymentMethod.card:
        return 'card';
      case PosPaymentMethod.giftCard:
        return 'credit';
      case PosPaymentMethod.lankaQr:
        return 'bank_transfer';
    }
  }
}

class PaymentTender {
  final String id;
  final PosPaymentMethod method;
  final double amount;
  final double? tenderedAmount;
  final double? changeAmount;
  final String? reference;

  PaymentTender({
    String? id,
    required this.method,
    required this.amount,
    this.tenderedAmount,
    this.changeAmount,
    this.reference,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
    'id': id,
    'payment_method': method.apiValue,
    'amount': amount,
    'tendered_amount': tenderedAmount ?? amount,
    'change_amount': changeAmount ?? 0.0,
    'reference': reference,
  };
}

class SaleReceipt {
  final String uuid;
  final String invoiceNumber;
  final String storeName;
  final String terminalCode;
  final String cashierName;
  final DateTime soldAt;
  final List<PosCartItem> items;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;
  final double paidAmount;
  final double changeAmount;
  final List<PaymentTender> payments;
  final String? customerName;
  final String? customerPhone;
  final int loyaltyPointsEarned;
  final bool isOffline;

  SaleReceipt({
    required this.uuid,
    required this.invoiceNumber,
    required this.storeName,
    required this.terminalCode,
    required this.cashierName,
    required this.soldAt,
    required this.items,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.paidAmount,
    required this.changeAmount,
    required this.payments,
    this.customerName,
    this.customerPhone,
    this.loyaltyPointsEarned = 0,
    this.isOffline = false,
  });

  int get totalQuantity => items.fold(0, (sum, i) => sum + i.quantity);
}
