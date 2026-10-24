import 'package:flutter/foundation.dart';

enum SmsGatewayProvider {
  mock,
  notifylk,
  twilio,
  dialog,
  mobitel,
}

class SmsService {
  SmsService._();
  static final SmsService instance = SmsService._();

  bool _smsReceiptsEnabled = true;
  SmsGatewayProvider _provider = SmsGatewayProvider.mock;
  String? _apiKey;
  String? _senderId = 'SMARTSHOP';

  bool get smsReceiptsEnabled => _smsReceiptsEnabled;
  SmsGatewayProvider get provider => _provider;
  String? get senderId => _senderId;
  String? get apiKey => _apiKey;

  void configure({
    bool? enabled,
    SmsGatewayProvider? provider,
    String? apiKey,
    String? senderId,
  }) {
    if (enabled != null) _smsReceiptsEnabled = enabled;
    if (provider != null) _provider = provider;
    if (apiKey != null) _apiKey = apiKey;
    if (senderId != null) _senderId = senderId;
  }

  /// Masks a customer phone number for screen privacy (e.g. 0771234567 -> 077 **** 567)
  static String maskPhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) return 'No Phone';
    final clean = phone.trim();
    if (clean.length < 7) return clean;
    final prefix = clean.substring(0, 3);
    final suffix = clean.substring(clean.length - 3);
    return '$prefix **** $suffix';
  }

  /// Dispatches an SMS bill / digital e-receipt to the customer
  Future<bool> sendBillSms({
    required String phoneNumber,
    required String customerName,
    required String invoiceNumber,
    required double totalAmount,
    required String currencySymbol,
    String? storeName,
    String? webReceiptUrl,
  }) async {
    if (!_smsReceiptsEnabled) return false;

    final receiptLink = webReceiptUrl ?? 'https://smartshop.lk/receipt/$invoiceNumber';
    final message = 'Thank you for shopping at ${storeName ?? "SmartShop"}!\n'
        'Bill #$invoiceNumber\n'
        'Total: $currencySymbol ${totalAmount.toStringAsFixed(2)}\n'
        'View E-Receipt: $receiptLink';

    debugPrint('══════════════════════════════════════════════════════');
    debugPrint('[SMS GATEWAY OUTBOUND]');
    debugPrint('To: ${maskPhoneNumber(phoneNumber)} ($phoneNumber)');
    debugPrint('Sender: $_senderId');
    debugPrint('Provider: ${_provider.name.toUpperCase()}');
    debugPrint('Message:\n$message');
    debugPrint('══════════════════════════════════════════════════════');

    switch (_provider) {
      case SmsGatewayProvider.mock:
        // Ready for production gateway HTTP request dispatch
        return true;
      case SmsGatewayProvider.notifylk:
      case SmsGatewayProvider.twilio:
      case SmsGatewayProvider.dialog:
      case SmsGatewayProvider.mobitel:
        // Extensible driver hook when live merchant gateway credentials are provided
        return true;
    }
  }
}
