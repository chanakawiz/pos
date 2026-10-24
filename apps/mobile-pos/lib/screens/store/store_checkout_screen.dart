import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/database_helper.dart';
import '../../data/models/sale.dart';
import '../../providers/cart_provider.dart';
import 'order_confirmation_screen.dart';

class StoreCheckoutScreen extends ConsumerStatefulWidget {
  const StoreCheckoutScreen({super.key});

  @override
  ConsumerState<StoreCheckoutScreen> createState() => _StoreCheckoutScreenState();
}

class _StoreCheckoutScreenState extends ConsumerState<StoreCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController(text: 'Dulantha Perera');
  final _phoneController = TextEditingController(text: '077 123 4567');
  final _emailController = TextEditingController(text: 'dulantha@lifestyle.test');
  final _addressController = TextEditingController(text: '48 Horton Place, Colombo 07');

  String _fulfillmentType = 'delivery'; // 'delivery' or 'pickup'
  String _paymentMethod = 'card'; // 'card' or 'cod'
  bool _isSubmitting = false;

  final currencyFormatter = NumberFormat.currency(
    locale: 'en_LK',
    symbol: 'Rs. ',
    decimalDigits: 2,
  );

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _processCheckout() async {
    if (!_formKey.currentState!.validate()) return;

    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    setState(() => _isSubmitting = true);

    final orderSuffix = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    final orderNumber = 'ORD-2026-$orderSuffix';
    final nowIso = DateTime.now().toIso8601String();

    final itemsSnapshot = List.of(cart.items);
    final totalSnapshot = cart.grandTotal;

    try {
      final sale = SaleModel(
        transactionUuid: 'trx-$orderSuffix',
        invoiceNumber: orderNumber,
        cashierUuid: 'online-customer',
        cashierName: 'Customer Online Checkout',
        customerUuid: 'cust-online',
        customerName: _nameController.text.trim(),
        storeUuid: 'store-colombo-flagship',
        deviceUuid: 'mobile-app-client',
        subtotal: cart.subtotal,
        discountAmount: cart.billDiscount,
        taxAmount: cart.taxTotal,
        totalAmount: totalSnapshot,
        paidAmount: totalSnapshot,
        changeAmount: 0.0,
        soldAt: DateTime.now(),
        items: itemsSnapshot,
        payments: [
          PaymentModel(
            method: _paymentMethod == 'card' ? PaymentMethod.card : PaymentMethod.cash,
            amount: totalSnapshot,
            referenceNumber: 'ONLINE-PAY-$orderSuffix',
          ),
        ],
        syncStatus: 'pending',
      );

      await DatabaseHelper.instance.insertSale(sale);

      // 2. Clear Cart Bag
      ref.read(cartProvider.notifier).clearCart();

      // 3. Navigate to Order Confirmation Screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderConfirmationScreen(
              orderNumber: orderNumber,
              customerName: _nameController.text.trim(),
              customerPhone: _phoneController.text.trim(),
              fulfillmentType: _fulfillmentType == 'delivery'
                  ? 'Express Courier Delivery'
                  : 'Click & Collect at Colombo Flagship',
              paymentMethod: _paymentMethod == 'card'
                  ? 'Credit / Debit Card (Visa/Mastercard)'
                  : 'Cash on Delivery / In-Store Tender',
              totalAmount: totalSnapshot,
              items: itemsSnapshot,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('Checkout encountered an error: $e'),
          ),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'SECURE CHECKOUT',
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contact & Recipient Details
              Text(
                '1. RECIPIENT INFORMATION (FOR VERIFIED SMS RECEIPT)',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Recipient Name',
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Phone (for SMS E-Receipt)',
                        prefixIcon: Icon(Icons.phone_iphone, size: 20),
                        hintText: '077 123 4567',
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Required for SMS' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.mail_outline, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Fulfillment Method
              Text(
                '2. FULFILLMENT METHOD',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildChoiceCard(
                      title: 'Express Delivery',
                      subtitle: 'Island-wide courier',
                      icon: Icons.local_shipping_outlined,
                      isSelected: _fulfillmentType == 'delivery',
                      onTap: () => setState(() => _fulfillmentType = 'delivery'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildChoiceCard(
                      title: 'Flagship Pickup',
                      subtitle: 'Colombo 03 boutique',
                      icon: Icons.storefront_outlined,
                      isSelected: _fulfillmentType == 'pickup',
                      onTap: () => setState(() => _fulfillmentType = 'pickup'),
                    ),
                  ),
                ],
              ),

              if (_fulfillmentType == 'delivery') ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Delivery Street Address',
                      prefixIcon: Icon(Icons.home_outlined, size: 20),
                    ),
                    validator: (val) {
                      if (_fulfillmentType == 'delivery' && (val == null || val.trim().isEmpty)) {
                        return 'Delivery address is required';
                      }
                      return null;
                    },
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Payment Method
              Text(
                '3. PAYMENT METHOD',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              _buildPaymentOption(
                id: 'card',
                title: 'Credit / Debit Card (PayHere / Stripe)',
                subtitle: 'Instant authorization with Visa & Mastercard',
                icon: Icons.credit_card,
              ),
              const SizedBox(height: 10),
              _buildPaymentOption(
                id: 'cod',
                title: _fulfillmentType == 'delivery'
                    ? 'Cash On Delivery (COD)'
                    : 'Pay at Boutique Counter on Collection',
                subtitle: 'Verify goods before settling payment',
                icon: Icons.payments_outlined,
              ),

              const SizedBox(height: 28),

              // Order Summary Breakdown
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildSummaryLine('Subtotal', currencyFormatter.format(cart.subtotal)),
                    const SizedBox(height: 10),
                    _buildSummaryLine('Fulfillment & White-Glove Packaging', 'COMPLIMENTARY'),
                    const SizedBox(height: 10),
                    _buildSummaryLine('Taxes & Levies', 'Included (0%)'),
                    const Divider(color: AppColors.border, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TOTAL AMOUNT DUE',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          currencyFormatter.format(cart.grandTotal),
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _processCheckout,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : Text(
                          'CONFIRM & PLACE ORDER',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold.withOpacity(0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? AppColors.gold : AppColors.textSecondary,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.gold : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _paymentMethod == id;
    return InkWell(
      onTap: () => setState(() => _paymentMethod = id),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold.withOpacity(0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? AppColors.gold : AppColors.textSecondary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.gold : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: id,
              groupValue: _paymentMethod,
              activeColor: AppColors.gold,
              onChanged: (val) {
                if (val != null) setState(() => _paymentMethod = val);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryLine(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
