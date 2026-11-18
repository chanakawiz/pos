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
      transactionsCount: (json['transactions_count'] as num?)?.toInt() ?? 0,
      expectedCash: (json['expected_cash'] as num?)?.toDouble() ?? 0.0,
      actualClosingCash: (json['actual_closing_cash'] as num?)?.toDouble(),
      discrepancy: (json['discrepancy'] as num?)?.toDouble(),
      notes: json['notes'],
      isZReport: isZ,
    );
  }
}
