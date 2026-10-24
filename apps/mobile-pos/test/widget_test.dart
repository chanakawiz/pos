import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartshop_mobile_pos/main.dart';
import 'package:smartshop_mobile_pos/screens/pos/pos_screen.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('SmartShop POS mobile app launches into POS screen', (WidgetTester tester) async {
    // Set a realistic tablet landscape viewport
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: SmartShopMobilePosApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify main screen is loaded
    expect(find.byType(PosScreen), findsOneWidget);
    expect(find.text('All Products'), findsOneWidget);
  });
}
