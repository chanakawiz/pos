import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import '../models/payment_tender.dart';

enum PrinterPaperWidth {
  mm58(32),
  mm80(48);

  final int maxChars;
  const PrinterPaperWidth(this.maxChars);
}

class EscPosService {
  static const List<int> cmdInit = [0x1B, 0x40]; // ESC @
  static const List<int> cmdAlignCenter = [0x1B, 0x61, 0x01]; // ESC a 1
  static const List<int> cmdAlignLeft = [0x1B, 0x61, 0x00]; // ESC a 0
  static const List<int> cmdAlignRight = [0x1B, 0x61, 0x02]; // ESC a 2
  static const List<int> cmdBoldOn = [0x1B, 0x45, 0x01]; // ESC E 1
  static const List<int> cmdBoldOff = [0x1B, 0x45, 0x00]; // ESC E 0
  static const List<int> cmdDoubleSize = [0x1D, 0x21, 0x11]; // GS ! 0x11
  static const List<int> cmdNormalSize = [0x1D, 0x21, 0x00]; // GS ! 0x00
  static const List<int> cmdCut = [0x1D, 0x56, 0x00]; // GS V 0
  static const List<int> cmdLineFeed = [0x0A]; // LF

  // Logging buffer for test assertions and debug auditing
  static final List<String> printAuditLog = [];

  static Uint8List buildReceiptBytes(
    SaleReceipt receipt, {
    PrinterPaperWidth width = PrinterPaperWidth.mm58,
  }) {
    final currency = NumberFormat('#,##0.00');
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm');
    final bytes = BytesBuilder();
    final max = width.maxChars;

    void addRaw(List<int> cmd) => bytes.add(cmd);
    void addText(String text) => bytes.add(latin1.encode(text));
    void addLine(String text) {
      bytes.add(latin1.encode(text));
      bytes.add(cmdLineFeed);
    }

    String padRow(String left, String right) {
      final totalSpace = max - left.length - right.length;
      if (totalSpace < 1) {
        return '$left $right';
      }
      return left + (' ' * totalSpace) + right;
    }

    String divider([String char = '-']) => char * max;

    // 1. Initialize
    addRaw(cmdInit);

    // 2. Header
    addRaw(cmdAlignCenter);
    addRaw(cmdBoldOn);
    addRaw(cmdDoubleSize);
    addLine('OMNILUXE');
    addRaw(cmdNormalSize);
    addLine(receipt.storeName.toUpperCase());
    addRaw(cmdBoldOff);
    addLine('Flagship Multi-Department Boutique');
    addLine('Tel: +94 11 234 5678');
    addLine(divider('='));

    // 3. Receipt Telemetry
    addRaw(cmdAlignLeft);
    addLine(padRow('Invoice:', receipt.invoiceNumber));
    addLine(padRow('Date:', dateFmt.format(receipt.soldAt)));
    addLine(padRow('Terminal:', receipt.terminalCode));
    addLine(padRow('Cashier:', receipt.cashierName));
    if (receipt.customerName != null) {
      addLine(padRow('VIP Member:', receipt.customerName!));
    }
    addLine(divider('-'));

    // 4. Line Items Table Header
    addRaw(cmdBoldOn);
    addLine(padRow('Item Description', 'Total (LKR)'));
    addRaw(cmdBoldOff);
    addLine(divider('-'));

    // 5. Line Items
    for (final item in receipt.items) {
      addLine(item.product.name);
      final qtyStr = '${item.quantity} x ${currency.format(item.unitPrice)}';
      final totalStr = currency.format(item.total);
      addLine(padRow('  $qtyStr', totalStr));
      if (item.selectedVariant != null) {
        addLine('  Opt: ${item.selectedVariant}');
      }
    }
    addLine(divider('-'));

    // 6. Financial Summary
    addLine(padRow('Subtotal:', currency.format(receipt.subtotal)));
    if (receipt.discountAmount > 0) {
      addLine(padRow('VIP Discount:', '-${currency.format(receipt.discountAmount)}'));
    }
    if (receipt.taxAmount > 0) {
      addLine(padRow('VAT / Taxes:', currency.format(receipt.taxAmount)));
    }
    addRaw(cmdBoldOn);
    addLine(padRow('TOTAL PAYABLE:', 'LKR ${currency.format(receipt.totalAmount)}'));
    addRaw(cmdBoldOff);
    addLine(divider('-'));

    // 7. Payment Tender Breakdown
    addRaw(cmdBoldOn);
    addLine('PAYMENTS:');
    addRaw(cmdBoldOff);
    for (final tender in receipt.payments) {
      final methodStr = tender.method.displayName;
      final amtStr = currency.format(tender.amount);
      addLine(padRow('  $methodStr', amtStr));
      if (tender.reference != null && tender.reference!.isNotEmpty) {
        addLine('    Ref: ${tender.reference}');
      }
    }

    if (receipt.changeAmount > 0) {
      addRaw(cmdBoldOn);
      addLine(padRow('CHANGE DUE:', 'LKR ${currency.format(receipt.changeAmount)}'));
      addRaw(cmdBoldOff);
    }
    addLine(divider('='));

    // 8. Loyalty & Footer
    addRaw(cmdAlignCenter);
    if (receipt.loyaltyPointsEarned > 0) {
      addRaw(cmdBoldOn);
      addLine('POINTS EARNED: +${receipt.loyaltyPointsEarned} VIP PTS');
      addRaw(cmdBoldOff);
    }
    addLine('Thank you for shopping with OmniLuxe!');
    addLine('Exchange within 14 days with original receipt.');
    addLine('Track: omniluxe.store/track/${receipt.invoiceNumber}');
    addRaw(cmdLineFeed);
    addRaw(cmdLineFeed);
    addRaw(cmdLineFeed);

    // 9. Cut
    addRaw(cmdCut);

    final resultBytes = bytes.toBytes();

    // Log to audit buffer
    printAuditLog.add(
      'ESC/POS Print [${width.name}] -> Invoice: ${receipt.invoiceNumber}, Bytes: ${resultBytes.length}, Total: LKR ${currency.format(receipt.totalAmount)}',
    );

    return resultBytes;
  }
}
