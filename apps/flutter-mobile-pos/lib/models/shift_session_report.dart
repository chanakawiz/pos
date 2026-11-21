enum CashMovementType {
  cashIn('cash_in', 'Float Pay-In', '+'),
  cashOut('cash_out', 'Safe Cash Drop', '-'),
  pettyCash('petty_cash', 'Petty Cash Expense', '-');

  final String apiValue;
  final String label;
  final String sign;
  const CashMovementType(this.apiValue, this.label, this.sign);

  bool get isInflow => this == CashMovementType.cashIn;

  static CashMovementType fromApi(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'cash_in':
        return CashMovementType.cashIn;
      case 'petty_cash':
        return CashMovementType.pettyCash;
      default:
        return CashMovementType.cashOut;
    }
  }
}

class CashMovementEntry {
  final String uuid;
  final CashMovementType type;
  final double amount;
  final String reason;
  final String reference;
  final String? notes;
  final String cashierName;
  final DateTime recordedAt;
  final bool isOffline;

  const CashMovementEntry({
    required this.uuid,
    required this.type,
    required this.amount,
    required this.reason,
    required this.reference,
    this.notes,
    required this.cashierName,
    required this.recordedAt,
    this.isOffline = false,
  });

  factory CashMovementEntry.fromJson(Map<String, dynamic> json, {String defaultCashier = 'Cashier 01'}) {
    final user = json['user'] is Map ? Map<String, dynamic>.from(json['user']) : null;
    return CashMovementEntry(
      uuid: json['uuid']?.toString() ?? 'mov-local',
      type: CashMovementType.fromApi(json['type']?.toString()),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      reason: json['reason']?.toString() ?? 'Cash Drawer Movement',
      reference: json['reference']?.toString() ?? 'DRP-000',
      notes: json['notes']?.toString(),
      cashierName: user?['name']?.toString() ?? json['cashier_name']?.toString() ?? defaultCashier,
      recordedAt: json['recorded_at'] != null
          ? (DateTime.tryParse(json['recorded_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      isOffline: json['is_offline'] == true,
    );
  }
}

class ShiftSessionReport {
  final String sessionUuid;
  final String storeName;
  final String terminalCode;
  final String cashierName;
  final DateTime openedAt;
  final DateTime? closedAt;
  final String status;
  final double openingFloat;
  final double cashSales;
  final double cardSales;
  final double giftCardSales;
  final double grossSales;
  final double discountTotal;
  final double refundTotal;
  final double cashInTotal;
  final double cashDropTotal;
  final int transactionsCount;
  final double expectedCash;
  final double? actualClosingCash;
  final double? discrepancy;
  final String? notes;
  final bool isZReport;

  const ShiftSessionReport({
    required this.sessionUuid,
    required this.storeName,
    required this.terminalCode,
    required this.cashierName,
    required this.openedAt,
    this.closedAt,
    this.status = 'OPEN',
    required this.openingFloat,
    this.cashSales = 0.0,
    this.cardSales = 0.0,
    this.giftCardSales = 0.0,
    this.grossSales = 0.0,
    this.discountTotal = 0.0,
    this.refundTotal = 0.0,
    this.cashInTotal = 0.0,
    this.cashDropTotal = 0.0,
    this.transactionsCount = 0,
    required this.expectedCash,
    this.actualClosingCash,
    this.discrepancy,
    this.notes,
    this.isZReport = false,
  });

  bool get isBalanced => (discrepancy ?? 0.0).abs() < 0.01;
  bool get isOver => (discrepancy ?? 0.0) > 0.01;
  bool get isShort => (discrepancy ?? 0.0) < -0.01;

  ShiftSessionReport copyWith({
    double? cashSales,
    double? cardSales,
    double? giftCardSales,
    double? grossSales,
    double? discountTotal,
    double? refundTotal,
    double? cashInTotal,
    double? cashDropTotal,
    int? transactionsCount,
    double? expectedCash,
    double? actualClosingCash,
    double? discrepancy,
    String? notes,
    String? status,
    DateTime? closedAt,
    bool? isZReport,
  }) {
    return ShiftSessionReport(
      sessionUuid: sessionUuid,
      storeName: storeName,
      terminalCode: terminalCode,
      cashierName: cashierName,
      openedAt: openedAt,
      closedAt: closedAt ?? this.closedAt,
      status: status ?? this.status,
      openingFloat: openingFloat,
      cashSales: cashSales ?? this.cashSales,
      cardSales: cardSales ?? this.cardSales,
      giftCardSales: giftCardSales ?? this.giftCardSales,
      grossSales: grossSales ?? this.grossSales,
      discountTotal: discountTotal ?? this.discountTotal,
      refundTotal: refundTotal ?? this.refundTotal,
      cashInTotal: cashInTotal ?? this.cashInTotal,
      cashDropTotal: cashDropTotal ?? this.cashDropTotal,
      transactionsCount: transactionsCount ?? this.transactionsCount,
      expectedCash: expectedCash ?? this.expectedCash,
      actualClosingCash: actualClosingCash ?? this.actualClosingCash,
      discrepancy: discrepancy ?? this.discrepancy,
      notes: notes ?? this.notes,
      isZReport: isZReport ?? this.isZReport,
    );
  }

  factory ShiftSessionReport.fromJson(Map<String, dynamic> json, {bool isZ = false}) {
    return ShiftSessionReport(
      sessionUuid: json['session_uuid'] ?? json['uuid'] ?? 'sess-default',
      storeName: json['store_name'] ?? 'OmniLuxe Flagship',
      terminalCode: json['terminal_code'] ?? 'ROAMING-01',
      cashierName: json['cashier_name'] ?? 'Cashier 01',
      openedAt: json['opened_at'] != null ? DateTime.parse(json['opened_at']) : DateTime.now(),
      closedAt: json['closed_at'] != null ? DateTime.parse(json['closed_at']) : null,
      status: json['status'] ?? (isZ ? 'CLOSED' : 'OPEN'),
      openingFloat: (json['opening_float'] as num?)?.toDouble() ?? 0.0,
      cashSales: (json['cash_sales'] as num?)?.toDouble() ?? 0.0,
      cardSales: (json['card_sales'] as num?)?.toDouble() ?? 0.0,
      giftCardSales: (json['gift_card_sales'] as num?)?.toDouble() ?? 0.0,
      grossSales: (json['gross_sales'] as num?)?.toDouble() ?? 0.0,
      discountTotal: (json['discount_total'] as num?)?.toDouble() ?? 0.0,
      refundTotal: (json['refund_total'] as num?)?.toDouble() ?? 0.0,
      cashInTotal: (json['cash_in_total'] as num?)?.toDouble() ?? 0.0,
      cashDropTotal: (json['cash_drop_total'] as num?)?.toDouble() ?? 0.0,
      transactionsCount: (json['transactions_count'] as num?)?.toInt() ?? 0,
      expectedCash: (json['expected_cash'] as num?)?.toDouble() ?? 0.0,
      actualClosingCash: (json['actual_closing_cash'] as num?)?.toDouble(),
      discrepancy: (json['discrepancy'] as num?)?.toDouble(),
      notes: json['notes'],
      isZReport: isZ,
    );
  }
}
