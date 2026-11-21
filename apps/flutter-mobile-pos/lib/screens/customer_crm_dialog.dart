import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/pos_theme.dart';
import '../models/pos_customer.dart';
import '../providers/pos_cart_provider.dart';
import '../providers/pos_customer_provider.dart';

class CustomerCrmDialog extends ConsumerStatefulWidget {
  const CustomerCrmDialog({super.key});

  @override
  ConsumerState<CustomerCrmDialog> createState() => _CustomerCrmDialogState();
}

class _CustomerCrmDialogState extends ConsumerState<CustomerCrmDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _attachCustomer(PosCustomer customer) {
    ref.read(posCartProvider.notifier).attachPosCustomer(customer);
    Navigator.pop(context);
    final discountNote = customer.tierDiscountPercent > 0
        ? ' (${customer.tierDiscountPercent.toStringAsFixed(0)}% VIP Discount Applied)'
        : '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: PosTheme.primaryGold,
        behavior: SnackBarBehavior.floating,
        content: Text(
          'Attached ${customer.name} • ${customer.tierTitle}$discountNote',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Future<void> _registerAndAttach() async {
    final created = await ref.read(posCustomerProvider.notifier).registerCustomer(
          name: _nameCtrl.text,
          phone: _phoneCtrl.text,
          email: _emailCtrl.text,
        );
    if (mounted && created != null) {
      _attachCustomer(created);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerState = ref.watch(posCustomerProvider);
    final customers = customerState.filteredCustomers;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 650),
        decoration: BoxDecoration(
          color: PosTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: PosTheme.primaryGold.withValues(alpha: 0.45), width: 1.5),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: const BoxDecoration(
                color: PosTheme.card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
                border: Border(bottom: BorderSide(color: PosTheme.border)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: PosTheme.primaryGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.workspace_premium_outlined, color: PosTheme.primaryGold, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VIP CUSTOMER CRM & LOYALTY',
                          style: TextStyle(
                            color: PosTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          'Auto-Applies Gold Elite (5%) & Black Diamond (10%) Perks',
                          style: TextStyle(color: PosTheme.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: PosTheme.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            TabBar(
              controller: _tabCtrl,
              indicatorColor: PosTheme.primaryGold,
              labelColor: PosTheme.primaryGold,
              unselectedLabelColor: PosTheme.textSecondary,
              tabs: const [
                Tab(text: 'VIP LOOKUP'),
                Tab(text: 'QUICK REGISTER (+100 PTS)'),
              ],
            ),

            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  // Tab 1: VIP Search & Select
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: TextField(
                          controller: _searchCtrl,
                          style: const TextStyle(color: PosTheme.textPrimary, fontSize: 13),
                          onChanged: (v) => ref.read(posCustomerProvider.notifier).setSearchQuery(v),
                          onSubmitted: (v) => ref.read(posCustomerProvider.notifier).searchCustomers(query: v),
                          decoration: InputDecoration(
                            hintText: 'Search by name, mobile, or tier...',
                            prefixIcon: const Icon(Icons.search, color: PosTheme.primaryGold, size: 18),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.cloud_sync_outlined, color: PosTheme.primaryGold, size: 18),
                              tooltip: 'Search ERP Cloud',
                              onPressed: () => ref
                                  .read(posCustomerProvider.notifier)
                                  .searchCustomers(query: _searchCtrl.text),
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                      Expanded(
                        child: customerState.isLoading
                            ? const Center(child: CircularProgressIndicator(color: PosTheme.primaryGold))
                            : customers.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No customers found. Switch to Quick Register.',
                                      style: TextStyle(color: PosTheme.textSecondary, fontSize: 13),
                                    ),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                                    itemCount: customers.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                                    itemBuilder: (_, idx) => _buildCustomerTile(customers[idx]),
                                  ),
                      ),
                    ],
                  ),

                  // Tab 2: Quick Register New VIP
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _nameCtrl,
                          style: const TextStyle(color: PosTheme.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Full Name *',
                            hintText: 'e.g. Kasun Jayasinghe',
                            prefixIcon: Icon(Icons.person_outline, color: PosTheme.primaryGold),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: PosTheme.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Mobile Number (For SMS E-Receipt) *',
                            hintText: '+94 77 555 8899',
                            prefixIcon: Icon(Icons.phone_outlined, color: PosTheme.primaryGold),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: PosTheme.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Email Address (Optional)',
                            hintText: 'kasun@example.com',
                            prefixIcon: Icon(Icons.email_outlined, color: PosTheme.primaryGold),
                          ),
                        ),
                        if (customerState.errorMessage != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            customerState.errorMessage!,
                            style: const TextStyle(color: PosTheme.accentRed, fontSize: 12),
                          ),
                        ],
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.person_add_alt_1, size: 18),
                          label: Text(
                            customerState.isCreating
                                ? 'ENROLLING VIP MEMBER...'
                                : 'ENROLL VIP & ATTACH TO CART',
                          ),
                          onPressed: customerState.isCreating ? null : _registerAndAttach,
                        ),
                      ],
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

  Widget _buildCustomerTile(PosCustomer customer) {
    final tierColor = customer.normalizedTier == 'black'
        ? const Color(0xFFE5E7EB)
        : (customer.normalizedTier == 'gold' ? PosTheme.primaryGold : PosTheme.textSecondary);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _attachCustomer(customer),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: PosTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: PosTheme.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: PosTheme.forestGreen,
              child: Text(
                customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'V',
                style: const TextStyle(color: PosTheme.primaryGold, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          customer.name,
                          style: const TextStyle(
                            color: PosTheme.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: tierColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: tierColor.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          customer.tierDiscountPercent > 0
                              ? '${customer.tierTitle} • ${customer.tierDiscountPercent.toStringAsFixed(0)}% OFF'
                              : customer.tierTitle,
                          style: TextStyle(color: tierColor, fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${customer.maskedPhone} • ${customer.loyaltyPoints} VIP Pts',
                    style: const TextStyle(color: PosTheme.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.add_circle_outline, color: PosTheme.primaryGold, size: 22),
          ],
        ),
      ),
    );
  }
}
