import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _numberFormat = NumberFormat('#,##0.00', 'en_US');

  static String format(double amount, {String symbol = 'Rs.'}) {
    return '$symbol ${_numberFormat.format(amount)}';
  }

  static String formatQuantity(double qty) {
    if (qty == qty.roundToDouble()) {
      return qty.toInt().toString();
    }
    return qty.toStringAsFixed(3);
  }
}
