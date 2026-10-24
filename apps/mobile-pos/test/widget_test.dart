import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartshop_mobile_pos/main.dart';
import 'package:smartshop_mobile_pos/screens/store/store_main_screen.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('SmartShop consumer store app launches into StoreMainScreen', (WidgetTester tester) async {
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
    expect(find.text('SMARTSHOP'), findsWidgets);

    // Advance timer past splash animation and fade transition
    await tester.pump(const Duration(milliseconds: 2400));
    await tester.pump(const Duration(milliseconds: 700));

    // Verify flagship boutique main screen is loaded
    expect(find.byType(StoreMainScreen), findsOneWidget);
  });
}
