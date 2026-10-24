import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartshop_mobile_pos/screens/store/store_more_screen.dart';

void main() {
  testWidgets('StoreMoreScreen has zero staff or cashier terminal exposure', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: StoreMoreScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify customer concierge & policies are visible
    expect(find.text('MORE & SERVICES'), findsOneWidget);
    expect(find.text('CUSTOMER SERVICES'), findsOneWidget);
    expect(find.text('PRIVILEGE & POLICIES'), findsOneWidget);
    expect(find.text('Find a Boutique (Store Locator)'), findsOneWidget);
    expect(find.text('Customer Privacy & Data Protection'), findsOneWidget);
    expect(find.text('100% Authenticity Guarantee'), findsOneWidget);

    // Strictly ensure zero operational staff terminal leaks
    expect(find.text('STAFF & REGISTER TERMINAL'), findsNothing);
    expect(find.text('Cashier POS Counter Access'), findsNothing);
    expect(find.text('Hardware & ESC/POS Pairing'), findsNothing);
    expect(find.textContaining('ERP Engine'), findsNothing);
  });
}
