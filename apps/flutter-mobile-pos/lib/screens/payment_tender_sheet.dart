import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme/pos_theme.dart';
import '../models/payment_tender.dart';
import '../providers/pos_auth_provider.dart';
import '../providers/pos_cart_provider.dart';
import '../providers/pos_payment_provider.dart';
import 'sale_success_dialog.dart';

class PaymentTenderSheet extends ConsumerStatefulWidget {
  const PaymentTenderSheet({super.key});

  @override
  ConsumerState<PaymentTenderSheet> createState() => _PaymentTenderSheetState();
}

class _PaymentTenderSheetState extends ConsumerState<PaymentTenderSheet> {
  final NumberFormat _currency = NumberFormat.currency(symbol: 'LKR ', decimalDigits: 2);
  final TextEditingController _cashInputController = TextEditingController();
  final TextEditingController _cardRefController = TextEditingController();
  final TextEditingController _giftCardController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  bool _sendSmsReceipt = true;
  bool _printThermalReceipt = true;

  @override
  void initState() {
    super.initState();
    final cart = ref.read(posCartProvider);
    if (cart.customerPhone != null) {
      _customerPhoneController.text = cart.customerPhone!;
    }
  }

  @override
  void dispose() {
    _cashInputController.dispose();
    _cardRefController.dispose();
    _giftCardController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }

  void _addCashPayment(double remaining) {
    final entered = double.tryParse(_cashInputController.text.replaceAll(',', '')) ?? remaining;
    if (entered <= 0) return;

    final tenderAmount = entered > remaining ? remaining : entered;
    final change = entered > remaining ? entered - remaining : 0.0;

    ref.read(posPaymentProvider.notifier).addTender(
          PaymentTender(
            method: PosPaymentMethod.cash,
            amount: tenderAmount,
            tenderedAmount: entered,
            changeAmount: change,
          ),
        );
    _cashInputController.clear();
  }

  void _addCardPayment(double remaining) {
    final refCode = _cardRefController.text.trim();
    ref.read(posPaymentProvider.notifier).addTender(
          PaymentTender(
            method: PosPaymentMethod.card,
            amount: remaining,
            reference: refCode.isNotEmpty ? refCode : 'MPOS-AUTH-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
          ),
        );
    _cardRefController.clear();
  }

  Future<void> _applyGiftCard(double remaining) async {
    final code = _giftCardController.text.trim();
    if (code.isEmpty) return;

    final balance = await ref.read(posPaymentProvider.notifier).verifyGiftCard(code, remaining);
    if (balance != null && balance > 0) {
      final applyAmount = balance > remaining ? remaining : balance;
      ref.read(posPaymentProvider.notifier).addTender(
            PaymentTender(
              method: PosPaymentMethod.giftCard,
              amount: applyAmount,
              reference: code,
            ),
          );
      _giftCardController.clear();
    }
  }

  void _addLankaQrPayment(double remaining) {
    ref.read(posPaymentProvider.notifier).addTender(
          PaymentTender(
            method: PosPaymentMethod.lankaQr,
            amount: remaining,
            reference: 'LQR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
          ),
        );
  }

  Future<void> _onCompleteSale() async {
    final cart = ref.read(posCartProvider);
    final session = ref.read(posAuthProvider).session;
    final phone = _customerPhoneController.text.trim();

    final receipt = await ref.read(posPaymentProvider.notifier).completeSale(
          cart: cart,
          session: session,
          printReceipt: _printThermalReceipt,
          sendSms: _sendSmsReceipt,
          customerPhone: phone.isNotEmpty ? phone : null,
        );

    if (mounted && receipt != null) {
      Navigator.pop(context); // Close tender sheet
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.8),
        builder: (_) => SaleSuccessDialog(receipt: receipt),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(posCartProvider);
    final paymentState = ref.watch(posPaymentProvider);
    final targetTotal = cart.total;
    final remaining = paymentState.remaining(targetTotal);
    final isFullyPaid = paymentState.isFullyPaid(targetTotal);

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: PosTheme.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle & Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: PosTheme.cardDark,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: PosTheme.dividerDark)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CHECKOUT & PAYMENT TENDER',
                      style: TextStyle(
                        color: PosTheme.textWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'Multi-Tender Split Payment System',
                      style: TextStyle(color: PosTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: PosTheme.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Total & Balance Ribbon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: const Color(0xFF0C100E),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL PAYABLE', style: TextStyle(color: PosTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w700)),
                    Text(
                      _currency.format(targetTotal),
                      style: const TextStyle(color: PosTheme.textWhite, fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isFullyPaid
                        ? PosTheme.statusSuccess.withValues(alpha: 0.15)
                        : PosTheme.primaryGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isFullyPaid ? PosTheme.statusSuccess : PosTheme.primaryGold,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isFullyPaid ? 'STATUS' : 'REMAINING DUE',
                        style: TextStyle(
                          color: isFullyPaid ? PosTheme.statusSuccess : PosTheme.primaryGold,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        isFullyPaid ? 'FULLY TENDERED' : _currency.format(remaining),
                        style: TextStyle(
                          color: isFullyPaid ? PosTheme.statusSuccess : PosTheme.primaryGold,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Scrollable Tender Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Payment Method Selector Tabs
                  Row(
                    children: PosPaymentMethod.values.map((m) {
                      final isSelected = paymentState.activeMethod == m;
                      IconData icon;
                      switch (m) {
                        case PosPaymentMethod.cash:
                          icon = Icons.payments_outlined;
                          break;
                        case PosPaymentMethod.card:
                          icon = Icons.credit_card;
                          break;
                        case PosPaymentMethod.giftCard:
                          icon = Icons.card_giftcard;
                          break;
                        case PosPaymentMethod.lankaQr:
                          icon = Icons.qr_code_2;
                          break;
                      }

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: InkWell(
                            onTap: () => ref.read(posPaymentProvider.notifier).selectMethod(m),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? PosTheme.primaryGold : PosTheme.cardDark,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? PosTheme.primaryGold : PosTheme.dividerDark,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(icon, size: 20, color: isSelected ? const Color(0xFF111413) : PosTheme.textWhite),
                                  const SizedBox(height: 4),
                                  Text(
                                    m.displayName,
                                    style: TextStyle(
                                      color: isSelected ? const Color(0xFF111413) : PosTheme.textMuted,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 18),

                  // Active Method Input Card
                  _buildMethodInputPanel(paymentState, remaining),

                  const SizedBox(height: 16),

                  // Customer VIP Loyalty Points Redemption (If customer attached)
                  if (cart.customerName != null) _buildLoyaltyPointsCard(cart, paymentState, targetTotal),

                  const SizedBox(height: 16),

                  // Active Tenders List (Split Payments)
                  if (paymentState.tenders.isNotEmpty) _buildTendersList(paymentState),

                  const SizedBox(height: 14),

                  // Receipt & SMS Preferences Checkboxes
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: PosTheme.cardDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: PosTheme.dividerDark),
                    ),
                    child: Column(
                      children: [
                        CheckboxListTile(
                          value: _printThermalReceipt,
                          dense: true,
                          activeColor: PosTheme.primaryGold,
                          checkColor: const Color(0xFF111413),
                          title: const Text('Print ESC/POS Thermal Receipt (58mm)', style: TextStyle(color: PosTheme.textWhite, fontSize: 13)),
                          onChanged: (val) => setState(() => _printThermalReceipt = val ?? true),
                        ),
                        CheckboxListTile(
                          value: _sendSmsReceipt,
                          dense: true,
                          activeColor: PosTheme.primaryGold,
                          checkColor: const Color(0xFF111413),
                          title: const Text('Send Digital SMS Receipt to Customer', style: TextStyle(color: PosTheme.textWhite, fontSize: 13)),
                          subtitle: Text(
                            _customerPhoneController.text.isNotEmpty
                                ? 'Destination: ${_customerPhoneController.text}'
                                : 'Customer phone required',
                            style: TextStyle(color: PosTheme.textMuted, fontSize: 11),
                          ),
                          onChanged: (val) => setState(() => _sendSmsReceipt = val ?? true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Bar: Complete Sale Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: PosTheme.cardDark,
              border: Border(top: BorderSide(color: PosTheme.dividerDark)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: paymentState.isProcessing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF111413)))
                    : const Icon(Icons.check_circle, size: 22),
                label: Text(
                  paymentState.isProcessing
                      ? 'PROCESSING TRANSACTION...'
                      : isFullyPaid
                          ? 'COMPLETE SALE & ISSUE RECEIPT'
                          : 'TENDER REMAINING (${_currency.format(remaining)})',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.8),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFullyPaid ? PosTheme.primaryGold : PosTheme.dividerDark,
                  foregroundColor: isFullyPaid ? const Color(0xFF111413) : PosTheme.textMuted,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: (isFullyPaid && !paymentState.isProcessing) ? _onCompleteSale : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodInputPanel(PosPaymentState paymentState, double remaining) {
    switch (paymentState.activeMethod) {
      case PosPaymentMethod.cash:
        return _buildCashPanel(remaining);
      case PosPaymentMethod.card:
        return _buildCardPanel(remaining);
      case PosPaymentMethod.giftCard:
        return _buildGiftCardPanel(paymentState, remaining);
      case PosPaymentMethod.lankaQr:
        return _buildLankaQrPanel(remaining);
    }
  }

  Widget _buildCashPanel(double remaining) {
    final entered = double.tryParse(_cashInputController.text.replaceAll(',', '')) ?? remaining;
    final change = entered > remaining ? entered - remaining : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PosTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PosTheme.dividerDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('CASH TENDER AMOUNT', style: TextStyle(color: PosTheme.textWhite, fontSize: 12, fontWeight: FontWeight.w800)),
              if (change > 0)
                Text(
                  'Change: ${_currency.format(change)}',
                  style: const TextStyle(color: PosTheme.statusSuccess, fontSize: 12, fontWeight: FontWeight.w800),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _cashInputController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: PosTheme.textWhite, fontSize: 18, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              filled: true,
              fillColor: PosTheme.surfaceDark,
              hintText: remaining > 0 ? remaining.toStringAsFixed(0) : '0',
              prefixText: 'LKR ',
              prefixStyle: const TextStyle(color: PosTheme.primaryGold, fontWeight: FontWeight.w700),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          // Quick Cash Bill Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                backgroundColor: PosTheme.surfaceDark,
                side: const BorderSide(color: PosTheme.primaryGold),
                label: Text('Exact (${_currency.format(remaining)})', style: const TextStyle(color: PosTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.w700)),
                onPressed: () {
                  _cashInputController.text = remaining.toStringAsFixed(0);
                  setState(() {});
                },
              ),
              _buildDenominationChip(500),
              _buildDenominationChip(1000),
              _buildDenominationChip(2000),
              _buildDenominationChip(5000),
              _buildDenominationChip(10000),
            ],
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('ADD CASH TENDER'),
            style: ElevatedButton.styleFrom(
              backgroundColor: PosTheme.primaryGold,
              foregroundColor: const Color(0xFF111413),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: remaining > 0 ? () => _addCashPayment(remaining) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDenominationChip(int value) {
    return ActionChip(
      backgroundColor: PosTheme.surfaceDark,
      side: BorderSide(color: PosTheme.dividerDark),
      label: Text('+${_currency.format(value)}', style: const TextStyle(color: PosTheme.textWhite, fontSize: 11)),
      onPressed: () {
        final current = double.tryParse(_cashInputController.text.replaceAll(',', '')) ?? 0.0;
        _cashInputController.text = (current + value).toStringAsFixed(0);
        setState(() {});
      },
    );
  }

  Widget _buildCardPanel(double remaining) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PosTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PosTheme.dividerDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('CREDIT / DEBIT / mPOS TERMINAL', style: TextStyle(color: PosTheme.textWhite, fontSize: 12, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            'Insert / Tap customer card on wireless Bluetooth reader.',
            style: TextStyle(color: PosTheme.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _cardRefController,
            style: const TextStyle(color: PosTheme.textWhite, fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: PosTheme.surfaceDark,
              hintText: 'Terminal Approval Code (e.g. AUTH-48291)',
              hintStyle: TextStyle(color: PosTheme.textMuted, fontSize: 12),
              prefixIcon: const Icon(Icons.pin, color: PosTheme.primaryGold, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            icon: const Icon(Icons.credit_score, size: 18),
            label: Text('CHARGE ${_currency.format(remaining)} TO CARD'),
            style: ElevatedButton.styleFrom(
              backgroundColor: PosTheme.primaryGold,
              foregroundColor: const Color(0xFF111413),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: remaining > 0 ? () => _addCardPayment(remaining) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildGiftCardPanel(PosPaymentState paymentState, double remaining) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PosTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PosTheme.dividerDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('VIP GIFT CARD & STORE CREDIT', style: TextStyle(color: PosTheme.textWhite, fontSize: 12, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _giftCardController,
                  style: const TextStyle(color: PosTheme.textWhite, fontSize: 14, fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: PosTheme.surfaceDark,
                    hintText: 'GC-XXXX-XXXX-XXXX',
                    hintStyle: TextStyle(color: PosTheme.textMuted, fontSize: 12),
                    prefixIcon: const Icon(Icons.card_giftcard, color: PosTheme.primaryGold, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: PosTheme.primaryGold,
                  side: const BorderSide(color: PosTheme.primaryGold),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                ),
                onPressed: () => _applyGiftCard(remaining),
                child: const Text('APPLY'),
              ),
            ],
          ),
          if (paymentState.giftCardBalance != null) ...[
            const SizedBox(height: 8),
            Text(
              'Verified Balance: ${_currency.format(paymentState.giftCardBalance!)}',
              style: const TextStyle(color: PosTheme.statusSuccess, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLankaQrPanel(double remaining) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PosTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PosTheme.dividerDark),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('LANKAQR INSTANT PAY', style: TextStyle(color: PosTheme.textWhite, fontSize: 12, fontWeight: FontWeight.w800)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('LankaPay CBSL Certified', style: TextStyle(color: Color(0xFFEF4444), fontSize: 9, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.qr_code_2, size: 90, color: Colors.black),
          ),
          const SizedBox(height: 10),
          Text('Customer scans via Genie, Flash, FriMi, or iPay', style: TextStyle(color: PosTheme.textMuted, fontSize: 11)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.verified, size: 18),
              label: Text('CONFIRM LANKAQR (${_currency.format(remaining)})'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PosTheme.primaryGold,
                foregroundColor: const Color(0xFF111413),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: remaining > 0 ? () => _addLankaQrPayment(remaining) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoyaltyPointsCard(PosCartState cart, PosPaymentState paymentState, double targetTotal) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PosTheme.primaryGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PosTheme.primaryGold.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'VIP LOYALTY: ${cart.customerName}',
                style: const TextStyle(color: PosTheme.primaryGold, fontSize: 12, fontWeight: FontWeight.w800),
              ),
              const Text('Available: 500 pts', style: TextStyle(color: PosTheme.textWhite, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ActionChip(
                label: const Text('100 Pts (-1,000 LKR)', style: TextStyle(fontSize: 10)),
                backgroundColor: PosTheme.cardDark,
                onPressed: () => ref.read(posPaymentProvider.notifier).applyLoyaltyPoints(100, targetTotal),
              ),
              const SizedBox(width: 6),
              ActionChip(
                label: const Text('250 Pts (-2,500 LKR)', style: TextStyle(fontSize: 10)),
                backgroundColor: PosTheme.cardDark,
                onPressed: () => ref.read(posPaymentProvider.notifier).applyLoyaltyPoints(250, targetTotal),
              ),
              const SizedBox(width: 6),
              ActionChip(
                label: const Text('500 Pts (-5,000 LKR)', style: TextStyle(fontSize: 10)),
                backgroundColor: PosTheme.cardDark,
                onPressed: () => ref.read(posPaymentProvider.notifier).applyLoyaltyPoints(500, targetTotal),
              ),
            ],
          ),
          if (paymentState.loyaltyDiscount > 0) ...[
            const SizedBox(height: 6),
            Text(
              'Applied Loyalty Discount: -${_currency.format(paymentState.loyaltyDiscount)}',
              style: const TextStyle(color: PosTheme.statusSuccess, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTendersList(PosPaymentState paymentState) {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('APPLIED SPLIT PAYMENTS', style: TextStyle(color: PosTheme.textWhite, fontSize: 12, fontWeight: FontWeight.w800)),
              TextButton(
                onPressed: () => ref.read(posPaymentProvider.notifier).clearTenders(),
                child: const Text('CLEAR ALL', style: TextStyle(color: PosTheme.statusError, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...paymentState.tenders.map((t) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 16, color: PosTheme.statusSuccess),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${t.method.displayName} ${t.reference != null ? "(${t.reference})" : ""}',
                      style: const TextStyle(color: PosTheme.textWhite, fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _currency.format(t.amount),
                    style: const TextStyle(color: PosTheme.primaryGold, fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 18, color: PosTheme.statusError),
                    onPressed: () => ref.read(posPaymentProvider.notifier).removeTender(t.id),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
