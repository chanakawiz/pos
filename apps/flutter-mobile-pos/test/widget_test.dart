import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_mobile_pos/main.dart';
import 'package:flutter_mobile_pos/providers/pos_auth_provider.dart';

void main() {
  testWidgets('OmniLuxe Handheld Staff POS launches into StaffPinScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: OmniLuxeMobilePosApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Staff PIN Access Header
    expect(find.text('STAFF REGISTER ACCESS'), findsOneWidget);
    expect(find.text('Enter 4-Digit Staff PIN'), findsOneWidget);

    // Verify Cashier Choice Chips
    expect(find.text('Cashier 01'), findsOneWidget);
    expect(find.text('Cashier 02'), findsOneWidget);
    expect(find.text('Store Manager'), findsOneWidget);

    // Verify Keypad Digits
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('Keypad input accepts numeric digits', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: OmniLuxeMobilePosApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap '1', '2', '3'
    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('2'));
    await tester.pump();
    await tester.tap(find.text('3'));
    await tester.pump();

    // Tap Clear 'C'
    await tester.tap(find.text('C'), warnIfMissed: false);
    await tester.pump();
  });
}
