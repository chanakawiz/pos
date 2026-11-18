import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../core/theme/pos_theme.dart';
import '../models/pos_cart_item.dart';
import '../providers/pos_auth_provider.dart';
import '../providers/pos_catalog_provider.dart';
import '../providers/pos_cart_provider.dart';

class HeldBillsDialog extends ConsumerStatefulWidget {
  const HeldBillsDialog({super.key});

  @override
  ConsumerState<HeldBillsDialog> createState() => _HeldBillsDialogState();
}

class _HeldBillsDialogState extends ConsumerState<HeldBillsDialog> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _heldBills = [];

  @override
  void initState() {
    super.initState();
    _loadHeldBills();
  }

  Future<void> _loadHeldBills() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final session = ref.read(posAuthProvider).session;
    try {
      final uri = Uri.parse('${session.apiUrl}/api/v1/held-bills');
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'X-Device-UUID': session.deviceUuid,
          if (session.apiToken != null) 'Authorization': 'Bearer ${session.apiToken}',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['data'] ?? [];
        if (list is List) {
          setState(() {
            _heldBills = list.map((item) => Map<String, dynamic>.from(item)).toList();
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {
      // Offline fallback
    }

    // Default simulated held bill if none or offline
    setState(() {
      _heldBills = [
        {
          'uuid': 'held-demo-001',
          'hold_reference': 'HOLD-VIP-88',
          'cashier_name': 'Sarah Connor (Lane 01)',
          'customer_name': 'Alexander Wright',
          'customer_phone': '+94 77 123 4567',
          'items_count': 2,
          'subtotal': 493500.0,
          'held_at': DateTime.now().subtract(const Duration(minutes: 8)).toIso8601String(),
          'cart_items_json': [
            {
              'id': 'item-h1',
              'product_id': 1,
              'product_name': 'Apple iPhone 16 Pro Max 256GB',
              'barcode': '445566',
              'quantity': 1,
              'unit_price': 415000.0,
              'discount': 0.0,
              'total': 415000.0,
            },
            {
              'id': 'item-h2',
              'product_id': 3,
              'product_name': 'Apple AirPods Pro 2',
              'barcode': '667788',
              'quantity': 1,
              'unit_price': 78500.0,
              'discount': 0.0,
              'total': 78500.0,
            },
          ],
        },
      ];
      _isLoading = false;
    });
  }

  Future<void> _recallBill(Map<String, dynamic> bill) async {
    final catalog = ref.read(posCatalogProvider).products;
    final rawItems = bill['cart_items_json'] as List? ?? [];
    final List<PosCartItem> items = [];

    for (final raw in rawItems) {
      final barcode = raw['barcode']?.toString() ?? '';
      final prodId = raw['product_id'];
      final product = catalog.firstWhere(
        (p) => p.barcode == barcode || p.id == prodId,
        orElse: () => ref.read(posCatalogProvider.notifier).lookupByBarcode('445566') ?? catalog.first,
      );

      items.add(PosCartItem(
        id: raw['id'],
        product: product,
        quantity: (raw['quantity'] as num?)?.toInt() ?? 1,
        unitPrice: (raw['unit_price'] as num?)?.toDouble() ?? product.sellingPrice,
        discount: (raw['discount'] as num?)?.toDouble() ?? 0.0,
      ));
    }

    ref.read(posCartProvider.notifier).recallHeldBill(
      items: items,
      customerName: bill['customer_name'],
      customerPhone: bill['customer_phone'],
      vipTier: 'Gold VIP',
    );

    // Call DELETE to release cloud lock
    final session = ref.read(posAuthProvider).session;
    try {
      final uuid = bill['uuid'];
      if (uuid != null) {
        http.delete(
          Uri.parse('${session.apiUrl}/api/v1/held-bills/$uuid'),
          headers: {'X-Device-UUID': session.deviceUuid},
        );
      }
    } catch (_) {}

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: PosTheme.primaryGold,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Recalled ${bill['hold_reference']} (${items.length} items) to Register!',
            style: const TextStyle(color: Color(0xFF111413), fontWeight: FontWeight.w700),
          ),
        ),
      );
    }
  }

  Future<void> _discardBill(String uuid, int index) async {
    final session = ref.read(posAuthProvider).session;
    try {
      http.delete(
        Uri.parse('${session.apiUrl}/api/v1/held-bills/$uuid'),
        headers: {'X-Device-UUID': session.deviceUuid},
      );
    } catch (_) {}

    setState(() {
      _heldBills.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'LKR ', decimalDigits: 0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 650),
        decoration: BoxDecoration(
          color: PosTheme.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: PosTheme.primaryGold.withOpacity(0.35), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: PosTheme.cardDark,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                border: Border(bottom: BorderSide(color: PosTheme.dividerDark)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: PosTheme.statusWarning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.pause_circle_outline, color: PosTheme.statusWarning, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MULTI-LANE HELD BILLS',
                          style: TextStyle(
                            color: PosTheme.textWhite,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          'Line-Busting & Cloud Shared Hold Queue',
                          style: TextStyle(color: PosTheme.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: PosTheme.primaryGold),
                    onPressed: _loadHeldBills,
                    tooltip: 'Refresh Queue',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: PosTheme.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: PosTheme.primaryGold),
                    )
                  : _heldBills.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox, size: 56, color: PosTheme.textMuted.withOpacity(0.4)),
                              const SizedBox(height: 12),
                              const Text(
                                'No Held Bills in Queue',
                                style: TextStyle(
                                  color: PosTheme.textWhite,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Use "Hold Bill" to park active orders for other lanes',
                                style: TextStyle(color: PosTheme.textMuted, fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _heldBills.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final bill = _heldBills[index];
                            final subtotal = (bill['subtotal'] as num?)?.toDouble() ?? 0.0;
                            final itemsCount = bill['items_count'] ?? 0;
                            final ref = bill['hold_reference'] ?? 'HOLD';
                            final cashier = bill['cashier_name'] ?? 'Staff';
                            final customer = bill['customer_name'];

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: PosTheme.cardDark,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: PosTheme.dividerDark),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: PosTheme.primaryGold.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: PosTheme.primaryGold.withOpacity(0.5)),
                                        ),
                                        child: Text(
                                          ref,
                                          style: const TextStyle(
                                            color: PosTheme.primaryGold,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        currency.format(subtotal),
                                        style: const TextStyle(
                                          color: PosTheme.textWhite,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(Icons.person_pin, size: 14, color: PosTheme.textMuted),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Held by: $cashier',
                                        style: TextStyle(color: PosTheme.textMuted, fontSize: 12),
                                      ),
                                      const SizedBox(width: 14),
                                      Icon(Icons.shopping_bag_outlined, size: 14, color: PosTheme.textMuted),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$itemsCount items',
                                        style: TextStyle(color: PosTheme.textMuted, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  if (customer != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, size: 14, color: PosTheme.primaryGold),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Customer: $customer',
                                          style: const TextStyle(
                                            color: PosTheme.primaryGold,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          icon: const Icon(Icons.play_circle_fill, size: 18),
                                          label: const Text('RECALL TO REGISTER'),
                                          onPressed: () => _recallBill(bill),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: PosTheme.primaryGold,
                                            foregroundColor: const Color(0xFF111413),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: PosTheme.statusError),
                                        tooltip: 'Discard',
                                        onPressed: () => _discardBill(bill['uuid'] ?? '', index),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
