import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme/pos_theme.dart';
import '../models/payment_tender.dart';
import '../providers/pos_auth_provider.dart';
import '../providers/pos_payment_provider.dart';
import '../services/esc_pos_service.dart';

class SaleSuccessDialog extends ConsumerStatefulWidget {
  final SaleReceipt receipt;

  const SaleSuccessDialog({super.key, required this.receipt});

  @override
  ConsumerState<SaleSuccessDialog> createState() => _SaleSuccessDialogState();
}

class _SaleSuccessDialogState extends ConsumerState<SaleSuccessDialog> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isSendingSms = false;
  String? _smsStatus;

  @override
  void initState() {
    super.initState();
    if (widget.receipt.customerPhone != null) {
      _phoneController.text = widget.receipt.customerPhone!;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _reprintReceipt() async {
    EscPosService.buildReceiptBytes(widget.receipt, width: PrinterPaperWidth.mm58);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: PosTheme.primaryGold,
        behavior: SnackBarBehavior.floating,
        content: Text(
          'ESC/POS Thermal Receipt sent to Bluetooth Printer (58mm)',
          style: const TextStyle(color: Color(0xFF111413), fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Future<void> _sendSmsReceipt() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    setState(() => _isSendingSms = true);
    final session = ref.read(posAuthProvider).session;
    final sent = await ref.read(posPaymentProvider.notifier).dispatchSmsReceipt(
          session,
          widget.receipt.invoiceNumber,
          widget.receipt.totalAmount,
          phone,
        );

    setState(() {
      _isSendingSms = false;
      _smsStatus = sent ? 'SMS E-Receipt dispatched to $phone' : 'Failed to send SMS';
    });
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'LKR ', decimalDigits: 2);
    final receipt = widget.receipt;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        decoration: BoxDecoration(
          color: PosTheme.surfaceDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: PosTheme.primaryGold.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header Icon & Title
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: PosTheme.cardDark,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
                border: Border(bottom: BorderSide(color: PosTheme.dividerDark)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: PosTheme.statusSuccess.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: PosTheme.statusSuccess, width: 2),
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: PosTheme.statusSuccess, size: 36),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'SALE COMPLETED',
                    style: TextStyle(
                      color: PosTheme.textWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Invoice: ${receipt.invoiceNumber}',
                        style: const TextStyle(
                          color: PosTheme.primaryGold,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: receipt.isOffline
                              ? PosTheme.statusWarning.withValues(alpha: 0.2)
                              : PosTheme.statusSuccess.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          receipt.isOffline ? 'OFFLINE QUEUED' : 'CLOUD SYNCED',
                          style: TextStyle(
                            color: receipt.isOffline ? PosTheme.statusWarning : PosTheme.statusSuccess,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Financial Summary Details
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Change Due Banner (If Cash Tendered > Total)
                    if (receipt.changeAmount > 0) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: PosTheme.primaryGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: PosTheme.primaryGold, width: 1.5),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'CASH CHANGE DUE TO CUSTOMER',
                              style: TextStyle(
                                color: PosTheme.primaryGold,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currency.format(receipt.changeAmount),
                              style: const TextStyle(
                                color: PosTheme.textWhite,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Receipt Info Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: PosTheme.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: PosTheme.dividerDark),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow('Total Paid', currency.format(receipt.paidAmount)),
                          _buildSummaryRow('Items Count', '${receipt.totalQuantity} items'),
                          if (receipt.discountAmount > 0)
                            _buildSummaryRow('Discount Applied', '-${currency.format(receipt.discountAmount)}', color: PosTheme.statusSuccess),
                          if (receipt.loyaltyPointsEarned > 0)
                            _buildSummaryRow('VIP Loyalty Earned', '+${receipt.loyaltyPointsEarned} pts', color: PosTheme.primaryGold),
                          _buildSummaryRow('Terminal', receipt.terminalCode),
                          _buildSummaryRow('Cashier Staff', receipt.cashierName),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // SMS E-Receipt Field
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: PosTheme.cardDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: PosTheme.dividerDark),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.sms_outlined, size: 16, color: PosTheme.primaryGold),
                              const SizedBox(width: 8),
                              const Text(
                                'DIGITAL SMS E-RECEIPT',
                                style: TextStyle(
                                  color: PosTheme.textWhite,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  style: const TextStyle(color: PosTheme.textWhite, fontSize: 13),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: PosTheme.surfaceDark,
                                    hintText: '+94 77 123 4567',
                                    hintStyle: TextStyle(color: PosTheme.textMuted, fontSize: 12),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _isSendingSms ? null : _sendSmsReceipt,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: PosTheme.cardDark,
                                  foregroundColor: PosTheme.primaryGold,
                                  side: const BorderSide(color: PosTheme.primaryGold),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                                child: _isSendingSms
                                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: PosTheme.primaryGold))
                                    : const Text('SEND SMS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
                          if (_smsStatus != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _smsStatus!,
                              style: const TextStyle(color: PosTheme.statusSuccess, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer Buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: PosTheme.cardDark,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(23)),
                border: Border(top: BorderSide(color: PosTheme.dividerDark)),
              ),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.print, size: 16, color: PosTheme.textWhite),
                    label: const Text('PRINT'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: PosTheme.textWhite,
                      side: BorderSide(color: PosTheme.dividerDark),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _reprintReceipt,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('NEW SALE / DONE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PosTheme.primaryGold,
                        foregroundColor: const Color(0xFF111413),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                      onPressed: () {
                        ref.read(posPaymentProvider.notifier).resetCheckoutSession();
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Return from checkout to dashboard
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: PosTheme.textMuted, fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              color: color ?? PosTheme.textWhite,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
