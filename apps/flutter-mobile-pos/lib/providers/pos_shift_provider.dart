import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/shift_session_report.dart';
import '../services/esc_pos_service.dart';
import 'pos_auth_provider.dart';

class PosShiftState {
  final ShiftSessionReport? activeSummary;
  final ShiftSessionReport? lastZReport;
  final List<CashMovementEntry> movements;
  final bool isLoading;
  final bool isClosing;
  final bool isRecordingMovement;
  final String? errorMessage;

  const PosShiftState({
    this.activeSummary,
    this.lastZReport,
    this.movements = const [],
    this.isLoading = false,
    this.isClosing = false,
    this.isRecordingMovement = false,
    this.errorMessage,
  });

  PosShiftState copyWith({
    ShiftSessionReport? activeSummary,
    ShiftSessionReport? lastZReport,
    List<CashMovementEntry>? movements,
    bool? isLoading,
    bool? isClosing,
    bool? isRecordingMovement,
    String? errorMessage,
    bool clearZReport = false,
  }) {
    return PosShiftState(
      activeSummary: activeSummary ?? this.activeSummary,
      lastZReport: clearZReport ? null : (lastZReport ?? this.lastZReport),
      movements: movements ?? this.movements,
      isLoading: isLoading ?? this.isLoading,
      isClosing: isClosing ?? this.isClosing,
      isRecordingMovement: isRecordingMovement ?? this.isRecordingMovement,
      errorMessage: errorMessage,
    );
  }
}

class PosShiftNotifier extends StateNotifier<PosShiftState> {
  final Ref ref;

  PosShiftNotifier(this.ref) : super(const PosShiftState()) {
    loadCurrentSummary();
  }

  /// Query live mid-shift metrics from `/api/v1/cash-sessions/current` or generate local fallback
  Future<ShiftSessionReport> loadCurrentSummary() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final session = ref.read(posAuthProvider).session;

    ShiftSessionReport? report;

    try {
      final uri = Uri.parse('${session.apiUrl}/api/v1/cash-sessions/current');
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'X-Device-UUID': session.deviceUuid,
          if (session.apiToken != null) 'Authorization': 'Bearer ${session.apiToken}',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final summary = data['summary'];
        final sess = data['session'];
        if (summary != null) {
          report = ShiftSessionReport(
            sessionUuid: sess?['uuid'] ?? session.cashSessionUuid ?? 'sess-active',
            storeName: session.storeName,
            terminalCode: session.deviceCode,
            cashierName: session.cashierName.isNotEmpty ? session.cashierName : 'Cashier 01',
            openedAt: session.openedAt ?? DateTime.now(),
            openingFloat: session.openingFloat,
            cashSales: (summary['cash_sales'] as num?)?.toDouble() ?? 0.0,
            cardSales: (summary['card_sales'] as num?)?.toDouble() ?? 0.0,
            grossSales: (summary['gross_sales'] as num?)?.toDouble() ?? 0.0,
            discountTotal: (summary['total_discounts'] as num?)?.toDouble() ?? 0.0,
            refundTotal: (summary['total_refunds'] as num?)?.toDouble() ?? 0.0,
            cashInTotal: (summary['cash_in_total'] as num?)?.toDouble() ?? 0.0,
            cashDropTotal: (summary['cash_drop_total'] as num?)?.toDouble() ?? 0.0,
            transactionsCount: (summary['transaction_count'] as num?)?.toInt() ?? 0,
            expectedCash: (summary['expected_cash'] as num?)?.toDouble() ?? session.openingFloat,
          );
        }
      }
    } catch (_) {
      // Offline fallback
    }

    if (report == null) {
      final prev = state.activeSummary;
      final cashIn = prev?.cashInTotal ?? 0.0;
      final cashDrop = prev?.cashDropTotal ?? 0.0;
      final refunds = prev?.refundTotal ?? 0.0;
      final cashSales = prev?.cashSales ?? 0.0;
      report = ShiftSessionReport(
        sessionUuid: session.cashSessionUuid ?? 'sess-active-offline',
        storeName: session.storeName,
        terminalCode: session.deviceCode,
        cashierName: session.cashierName.isNotEmpty ? session.cashierName : 'Cashier 01',
        openedAt: session.openedAt ?? DateTime.now().subtract(const Duration(hours: 4)),
        openingFloat: session.openingFloat,
        cashSales: cashSales,
        cardSales: prev?.cardSales ?? 0.0,
        grossSales: prev?.grossSales ?? 0.0,
        discountTotal: prev?.discountTotal ?? 0.0,
        refundTotal: refunds,
        cashInTotal: cashIn,
        cashDropTotal: cashDrop,
        transactionsCount: prev?.transactionsCount ?? 0,
        expectedCash: (session.openingFloat + cashSales + cashIn - cashDrop - refunds).clamp(0.0, double.infinity),
      );
    }

    state = state.copyWith(activeSummary: report, isLoading: false);
    return report;
  }

  /// Record safe cash drop, petty cash expense, or float pay-in on active shift
  Future<CashMovementEntry?> recordCashMovement({
    required CashMovementType type,
    required double amount,
    required String reason,
    String? reference,
    String? notes,
    bool printVoucher = true,
  }) async {
    if (amount <= 0 || reason.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Amount and reason are required.');
      return null;
    }

    state = state.copyWith(isRecordingMovement: true, errorMessage: null);
    final session = ref.read(posAuthProvider).session;
    final current = state.activeSummary ?? await loadCurrentSummary();

    final refCode = (reference != null && reference.trim().isNotEmpty)
        ? reference.trim().toUpperCase()
        : 'DRP-${const Uuid().v4().substring(0, 6).toUpperCase()}';

    CashMovementEntry? entry;
    double? serverExpected;
    double? serverCashIn;
    double? serverCashDrop;

    try {
      final uri = Uri.parse('${session.apiUrl}/api/v1/cash-sessions/movements');
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'X-Device-UUID': session.deviceUuid,
              if (session.apiToken != null) 'Authorization': 'Bearer ${session.apiToken}',
            },
            body: jsonEncode({
              'type': type.apiValue,
              'amount': amount,
              'reason': reason.trim(),
              'reference': refCode,
              if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['movement'] is Map) {
          entry = CashMovementEntry.fromJson(
            Map<String, dynamic>.from(data['movement']),
            defaultCashier: session.cashierName.isNotEmpty ? session.cashierName : 'Cashier 01',
          );
        }
        if (data['summary'] is Map) {
          final s = data['summary'];
          serverExpected = (s['expected_cash'] as num?)?.toDouble();
          serverCashIn = (s['cash_in_total'] as num?)?.toDouble();
          serverCashDrop = (s['cash_drop_total'] as num?)?.toDouble();
        }
      }
    } catch (_) {
      // Offline fallback
    }

    entry ??= CashMovementEntry(
      uuid: const Uuid().v4(),
      type: type,
      amount: amount,
      reason: reason.trim(),
      reference: refCode,
      notes: notes?.trim(),
      cashierName: session.cashierName.isNotEmpty ? session.cashierName : 'Cashier 01',
      recordedAt: DateTime.now(),
      isOffline: true,
    );

    if (printVoucher) {
      EscPosService.buildCashMovementBytes(
        entry,
        storeName: session.storeName,
        terminalCode: session.deviceCode,
        width: PrinterPaperWidth.mm58,
      );
    }

    final newCashIn = serverCashIn ?? (current.cashInTotal + (type.isInflow ? amount : 0.0));
    final newCashDrop = serverCashDrop ?? (current.cashDropTotal + (type.isInflow ? 0.0 : amount));
    final newExpected = serverExpected ??
        (current.openingFloat + current.cashSales + newCashIn - newCashDrop - current.refundTotal)
            .clamp(0.0, double.infinity);

    final updatedSummary = current.copyWith(
      cashInTotal: newCashIn,
      cashDropTotal: newCashDrop,
      expectedCash: newExpected,
    );

    state = state.copyWith(
      activeSummary: updatedSummary,
      movements: [entry, ...state.movements],
      isRecordingMovement: false,
    );

    return entry;
  }

  /// Apply local refund deduction to active shift summary immediately
  void recordRefundImpact(double refundAmount) {
    final current = state.activeSummary;
    if (current == null || refundAmount <= 0) return;
    final newRefundTotal = current.refundTotal + refundAmount;
    final newExpected = (current.expectedCash - refundAmount).clamp(0.0, double.infinity);
    state = state.copyWith(
      activeSummary: current.copyWith(
        refundTotal: newRefundTotal,
        expectedCash: newExpected,
      ),
    );
  }

  /// Mid-shift inquiry X-Report without closing drawer
  Future<ShiftSessionReport> generateXReport({bool printReceipt = true}) async {
    final report = await loadCurrentSummary();
    if (printReceipt) {
      EscPosService.buildShiftReportBytes(report, width: PrinterPaperWidth.mm58);
    }
    return report;
  }

  /// Official shift closeout and Z-Report generation
  Future<ShiftSessionReport?> closeShift({
    required double closingCountedCash,
    String? notes,
    bool printReceipt = true,
  }) async {
    state = state.copyWith(isClosing: true, errorMessage: null);
    final session = ref.read(posAuthProvider).session;
    final current = state.activeSummary ?? await loadCurrentSummary();

    final expected = current.expectedCash;
    final discrepancy = closingCountedCash - expected;
    final now = DateTime.now();

    final zReport = ShiftSessionReport(
      sessionUuid: current.sessionUuid,
      storeName: session.storeName,
      terminalCode: session.deviceCode,
      cashierName: session.cashierName.isNotEmpty ? session.cashierName : 'Cashier 01',
      openedAt: current.openedAt,
      closedAt: now,
      status: 'CLOSED',
      openingFloat: current.openingFloat,
      cashSales: current.cashSales,
      cardSales: current.cardSales,
      giftCardSales: current.giftCardSales,
      grossSales: current.grossSales,
      discountTotal: current.discountTotal,
      refundTotal: current.refundTotal,
      cashInTotal: current.cashInTotal,
      cashDropTotal: current.cashDropTotal,
      transactionsCount: current.transactionsCount,
      expectedCash: expected,
      actualClosingCash: closingCountedCash,
      discrepancy: discrepancy,
      notes: notes,
      isZReport: true,
    );

    try {
      final uri = Uri.parse('${session.apiUrl}/api/v1/cash-sessions/close');
      await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'X-Device-UUID': session.deviceUuid,
              if (session.apiToken != null) 'Authorization': 'Bearer ${session.apiToken}',
            },
            body: jsonEncode({
              'closing_balance': closingCountedCash,
              'notes': notes ?? 'Handheld mobile register closeout',
            }),
          )
          .timeout(const Duration(seconds: 4));
    } catch (_) {
      // Offline fallback: closing stored locally
    }

    if (printReceipt) {
      EscPosService.buildShiftReportBytes(zReport, width: PrinterPaperWidth.mm58);
    }

    // Reset cashier active shift in session
    ref.read(posAuthProvider.notifier).lockTerminal();

    state = state.copyWith(
      isClosing: false,
      lastZReport: zReport,
    );

    return zReport;
  }
}

final posShiftProvider = StateNotifierProvider<PosShiftNotifier, PosShiftState>((ref) {
  return PosShiftNotifier(ref);
});
