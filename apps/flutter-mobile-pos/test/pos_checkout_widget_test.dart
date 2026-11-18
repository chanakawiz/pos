import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_mobile_pos/screens/pos_checkout_screen.dart';

void main() {
  testWidgets('PosCheckoutScreen renders catalog header, search bar, and category chips', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: PosCheckoutScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify cashier header and search bar
    expect(find.text('ROAMING-01'), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
    expect(find.text('All'), findsOneWidget);

    // Verify barcode scanner icon button
    expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);
  });
}
