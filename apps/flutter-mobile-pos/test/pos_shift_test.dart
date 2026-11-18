import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_mobile_pos/models/shift_session_report.dart';
import 'package:flutter_mobile_pos/providers/pos_shift_provider.dart';
import 'package:flutter_mobile_pos/providers/pos_auth_provider.dart';
import 'package:flutter_mobile_pos/screens/shift_close_dialog.dart';
import 'package:flutter_mobile_pos/services/esc_pos_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Milestone 27: ShiftSessionReport Model Tests', () {
    test('Calculates balance status correctly (balanced, over, short)', () {
      final balanced = ShiftSessionReport(
        sessionUuid: 'sess-1',
        storeName: 'OmniLuxe Flagship',
        terminalCode: 'ROAMING-01',
        cashierName: 'John Doe',
        openedAt: DateTime.now(),
        openingFloat: 15000.0,
        expectedCash: 35000.0,
        actualClosingCash: 35000.0,
        discrepancy: 0.0,
        isZReport: true,
      );
      expect(balanced.isBalanced, isTrue);
      expect(balanced.isOver, isFalse);
      expect(balanced.isShort, isFalse);

      final over = ShiftSessionReport(
        sessionUuid: 'sess-2',
        storeName: 'OmniLuxe Flagship',
        terminalCode: 'ROAMING-01',
        cashierName: 'John Doe',
        openedAt: DateTime.now(),
        openingFloat: 15000.0,
        expectedCash: 35000.0,
        actualClosingCash: 35500.0,
        discrepancy: 500.0,
        isZReport: true,
      );
      expect(over.isBalanced, isFalse);
      expect(over.isOver, isTrue);
      expect(over.isShort, isFalse);

      final short = ShiftSessionReport(
        sessionUuid: 'sess-3',
        storeName: 'OmniLuxe Flagship',
        terminalCode: 'ROAMING-01',
        cashierName: 'John Doe',
        openedAt: DateTime.now(),
        openingFloat: 15000.0,
        expectedCash: 35000.0,
        actualClosingCash: 34200.0,
        discrepancy: -800.0,
        isZReport: true,
      );
      expect(short.isBalanced, isFalse);
      expect(short.isOver, isFalse);
      expect(short.isShort, isTrue);
    });

    test('Parses from JSON correctly for X-Report and Z-Report', () {
      final json = {
        'session_uuid': 'sess-100',
        'store_name': 'OmniLuxe Colombo City Centre',
        'terminal_code': 'MOBILE-01',
        'cashier_name': 'Nadeeka Perera',
        'opened_at': '2026-11-18T08:00:00.000Z',
        'opening_float': 20000.0,
        'cash_sales': 45000.0,
        'card_sales': 85000.0,
        'gross_sales': 130000.0,
        'transactions_count': 12,
        'expected_cash': 65000.0,
        'actual_closing_cash': 65000.0,
        'discrepancy': 0.0,
      };

      final report = ShiftSessionReport.fromJson(json, isZ: true);
      expect(report.sessionUuid, equals('sess-100'));
      expect(report.storeName, equals('OmniLuxe Colombo City Centre'));
      expect(report.terminalCode, equals('MOBILE-01'));
      expect(report.cashierName, equals('Nadeeka Perera'));
      expect(report.openingFloat, equals(20000.0));
      expect(report.cashSales, equals(45000.0));
      expect(report.grossSales, equals(130000.0));
      expect(report.expectedCash, equals(65000.0));
      expect(report.isZReport, isTrue);
    });
  });

  group('Milestone 27: EscPosService Shift Report Binary Printing Tests', () {
    test('Generates binary ESC/POS bytes for 58mm X-Report', () {
      final xReport = ShiftSessionReport(
        sessionUuid: 'sess-audit-1',
        storeName: 'OmniLuxe Flagship',
        terminalCode: 'ROAMING-01',
        cashierName: 'Staff 01',
        openedAt: DateTime(2026, 11, 18, 9, 0),
        openingFloat: 15000.0,
        cashSales: 12500.0,
        cardSales: 28000.0,
        grossSales: 40500.0,
        transactionsCount: 5,
        expectedCash: 27500.0,
        isZReport: false,
      );

      final bytes = EscPosService.buildShiftReportBytes(xReport, width: PrinterPaperWidth.mm58);
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(100));

      final lastLog = EscPosService.printAuditLog.last;
      expect(lastLog.toUpperCase(), contains('X-REPORT'));
      expect(lastLog, contains('ROAMING-01'));
    });

    test('Generates binary ESC/POS bytes for 80mm Z-Report with discrepancy', () {
      final zReport = ShiftSessionReport(
        sessionUuid: 'sess-close-1',
        storeName: 'OmniLuxe Flagship',
        terminalCode: 'ROAMING-01',
        cashierName: 'Staff 01',
        openedAt: DateTime(2026, 11, 18, 9, 0),
        closedAt: DateTime(2026, 11, 18, 21, 0),
        openingFloat: 15000.0,
        cashSales: 25000.0,
        cardSales: 45000.0,
        grossSales: 70000.0,
        transactionsCount: 18,
        expectedCash: 40000.0,
        actualClosingCash: 39500.0,
        discrepancy: -500.0,
        notes: 'Small coin shortage during peak rush',
        isZReport: true,
      );

      final bytes = EscPosService.buildShiftReportBytes(zReport, width: PrinterPaperWidth.mm80);
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(120));

      final lastLog = EscPosService.printAuditLog.last;
      expect(lastLog.toUpperCase(), contains('Z-REPORT'));
    });
  });

  group('Milestone 27: PosShiftNotifier Shift Workflow Tests', () {
    test('generateXReport loads active summary and prints receipt', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final shiftNotifier = container.read(posShiftProvider.notifier);
      final report = await shiftNotifier.generateXReport(printReceipt: true);

      expect(report, isNotNull);
      expect(report.isZReport, isFalse);
      expect(container.read(posShiftProvider).activeSummary, isNotNull);
    });

    test('closeShift calculates discrepancy, locks terminal and stores lastZReport', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Verify cashier session is open first
      final authNotifier = container.read(posAuthProvider.notifier);
      await authNotifier.openShift(openingFloat: 15000.0);
      expect(container.read(posAuthProvider).session.hasActiveShift, isTrue);

      final shiftNotifier = container.read(posShiftProvider.notifier);
      final zReport = await shiftNotifier.closeShift(
        closingCountedCash: 14800.0, // Expected is 15000, so short 200
        notes: 'End of evening shift',
        printReceipt: true,
      );

      expect(zReport, isNotNull);
      expect(zReport!.isZReport, isTrue);
      expect(zReport.actualClosingCash, equals(14800.0));
      expect(zReport.discrepancy, equals(-200.0));
      expect(zReport.isShort, isTrue);
      expect(container.read(posShiftProvider).lastZReport, equals(zReport));

      // Terminal should be locked following shift closeout
      expect(container.read(posAuthProvider).isLocked, isTrue);
    });
  });

  group('Milestone 27: ShiftCloseDialog Widget Tests', () {
    testWidgets('Renders ShiftCloseDialog and shows calculated discrepancy on cash count input', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: ShiftCloseDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('CLOSE REGISTER SHIFT (Z-REPORT)'), findsOneWidget);
      expect(find.text('EXPECTED DRAWER CASH'), findsOneWidget);
      expect(find.text('CONFIRM COUNT & CLOSE REGISTER'), findsOneWidget);

      // Enter physical cash count into TextField
      final cashField = find.byType(TextField).first;
      await tester.enterText(cashField, '16000');
      await tester.pumpAndSettle();

      // Discrepancy indicator should update to OVER
      expect(find.textContaining('OVER'), findsWidgets);
    });
  });
}
