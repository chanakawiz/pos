import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartshop_mobile_pos/screens/scanner/barcode_scanner_dialog.dart';

void main() {
  testWidgets('BarcodeScannerDialog renders manual input and quick presets without crash', (tester) async {
    String? scannedResult;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => BarcodeScannerDialog(
                    onBarcodeScanned: (code) {
                      scannedResult = code;
                    },
                  ),
                );
              },
              child: const Text('Open Scanner'),
            ),
          ),
        ),
      ),
    );

    // Tap to open scanner dialog
    await tester.tap(find.text('Open Scanner'));
    await tester.pump();

    // Verify dialog header, manual input section, and quick test barcodes are rendered
    expect(find.text('Barcode & IMEI Scanner'), findsOneWidget);
    expect(find.text('MANUAL BARCODE / IMEI INPUT'), findsOneWidget);
    expect(find.text('QUICK TEST BARCODES (SIMULATOR MODE)'), findsOneWidget);
    expect(find.text('123456'), findsOneWidget);

    // Tap quick test barcode
    await tester.tap(find.text('123456'));
    await tester.pumpAndSettle();

    // Verify callback was invoked and dialog closed
    expect(scannedResult, '123456');
    expect(find.text('Barcode & IMEI Scanner'), findsNothing);
  });
}
