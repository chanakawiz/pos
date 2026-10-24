import 'dart:convert';
import 'dart:typed_data';
import '../../data/models/sale.dart';
import '../../data/models/user.dart';
import '../utils/currency_formatter.dart';

class EscPosBuilder {
  final int paperWidth; // 80 or 58
  final int columns;
  final bool autoCut;
  final int drawerPin;

  EscPosBuilder({
    this.paperWidth = 80,
    this.autoCut = true,
    this.drawerPin = 2,
  }) : columns = (paperWidth == 58) ? 32 : 48;

  // ESC/POS Command Constants
  static const List<int> cmdInit = [0x1B, 0x40]; // ESC @
  static const List<int> cmdAlignLeft = [0x1B, 0x61, 0x00]; // ESC a 0
  static const List<int> cmdAlignCenter = [0x1B, 0x61, 0x01]; // ESC a 1
  static const List<int> cmdAlignRight = [0x1B, 0x61, 0x02]; // ESC a 2
  static const List<int> cmdBoldOn = [0x1B, 0x45, 0x01]; // ESC E 1
  static const List<int> cmdBoldOff = [0x1B, 0x45, 0x00]; // ESC E 0
  static const List<int> cmdDoubleHeightOn = [0x1B, 0x21, 0x10]; // ESC ! 16
  static const List<int> cmdNormal = [0x1B, 0x21, 0x00]; // ESC ! 0
  static const List<int> cmdCutPartial = [0x1D, 0x56, 0x42, 0x00]; // GS V 'B' 0

  /// Generate Cash Drawer kickout pulse for pin 2 or pin 5
  List<int> buildDrawerPulse() {
    final pin = (drawerPin == 5) ? 1 : 0;
    return [0x1B, 0x70, pin, 25, 250]; // ESC p pin 50ms 500ms
  }

  /// Build ESC/POS bytes for a completed sale receipt
  Uint8List buildReceipt(SaleModel sale, StoreModel? store) {
    final buffer = BytesBuilder();
    final currencySymbol = store?.currencySymbol ?? 'Rs.';

    void raw(List<int> bytes) => buffer.add(bytes);
    void line(String str) {
      buffer.add(latin1.encode(str));
      buffer.addByte(0x0A); // LF
    }

    // 1. Initialize Printer
    raw(cmdInit);

    // 2. Header (Centered)
    raw(cmdAlignCenter);
    raw(cmdDoubleHeightOn);
    raw(cmdBoldOn);
    line(store?.receiptHeader ?? 'SMARTSHOP POS');
    raw(cmdNormal);
    raw(cmdBoldOff);

    if (store?.name != null) {
      line(store!.name);
    }
    if (store?.address != null) {
      line(store!.address!);
    }
    if (store?.phone != null) {
      line('Tel: ${store!.phone!}');
    }

    raw(cmdAlignLeft);
    line('-' * columns);

    // 3. Invoice Metadata
    line(_twoColumns('Invoice:', sale.invoiceNumber));
    line(_twoColumns('Date:', sale.soldAt.toString().substring(0, 16)));
    line(_twoColumns('Cashier:', sale.cashierName));
    if (sale.customerName != null) {
      line(_twoColumns('Customer:', sale.customerName!));
    }

    line('-' * columns);

    // 4. Item Table Headers
    raw(cmdBoldOn);
    if (paperWidth == 58) {
      line(_twoColumns('ITEM', 'QTY/TOTAL'));
    } else {
      line(_threeColumns('ITEM', 'QTY', 'TOTAL'));
    }
    raw(cmdBoldOff);
    line('-' * columns);

    // 5. Items Lines
    for (final item in sale.items) {
      final name = item.product.name;
      final qtyStr = CurrencyFormatter.formatQuantity(item.quantity);
      final totalStr = CurrencyFormatter.format(item.total, symbol: currencySymbol);

      if (paperWidth == 58) {
        line(name);
        line(_twoColumns('  x$qtyStr', totalStr));
      } else {
        line(_threeColumns(name, qtyStr, totalStr));
      }

      // Serial / IMEI line
      if (item.serialNumber != null && item.serialNumber!.isNotEmpty) {
        line('  SN: ${item.serialNumber}');
      }

      // Warranty line
      if (item.warrantyNotes != null && item.warrantyNotes!.isNotEmpty) {
        line('  Warranty: ${item.warrantyNotes}');
      }
    }

    line('-' * columns);

    // 6. Totals
    line(_twoColumns('Subtotal:', CurrencyFormatter.format(sale.subtotal, symbol: currencySymbol)));
    if (sale.discountAmount > 0) {
      line(_twoColumns('Discount:', '- ${CurrencyFormatter.format(sale.discountAmount, symbol: currencySymbol)}'));
    }
    if (sale.taxAmount > 0) {
      line(_twoColumns('Tax:', CurrencyFormatter.format(sale.taxAmount, symbol: currencySymbol)));
    }

    raw(cmdBoldOn);
    line(_twoColumns('TOTAL:', CurrencyFormatter.format(sale.totalAmount, symbol: currencySymbol)));
    raw(cmdBoldOff);

    line(_twoColumns('Paid:', CurrencyFormatter.format(sale.paidAmount, symbol: currencySymbol)));
    if (sale.changeAmount > 0) {
      line(_twoColumns('Change:', CurrencyFormatter.format(sale.changeAmount, symbol: currencySymbol)));
    }

    line('=' * columns);

    // 7. Footer Blessings
    raw(cmdAlignCenter);
    line(store?.receiptFooter ?? 'Thank you! Please visit again.');
    buffer.add([0x0A, 0x0A, 0x0A]); // 3 feed lines

    // 8. Cut paper if enabled
    if (autoCut) {
      raw(cmdCutPartial);
    }

    return buffer.toBytes();
  }

  String _twoColumns(String left, String right) {
    final available = columns - left.length - right.length;
    if (available <= 0) {
      return '$left $right';
    }
    return '$left${' ' * available}$right';
  }

  String _threeColumns(String col1, String col2, String col3) {
    const col2Width = 8;
    const col3Width = 14;
    final col1Width = columns - col2Width - col3Width;

    final c1 = col1.length > col1Width ? col1.substring(0, col1Width - 1) : col1.padRight(col1Width);
    final c2 = col2.padLeft(col2Width);
    final c3 = col3.padLeft(col3Width);

    return '$c1$c2$c3';
  }
}
