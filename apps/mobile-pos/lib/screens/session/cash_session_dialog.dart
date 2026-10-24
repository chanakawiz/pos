import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/printer/printer_service.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';

class CashSessionDialog extends ConsumerStatefulWidget {
  const CashSessionDialog({super.key});

  @override
  ConsumerState<CashSessionDialog> createState() => _CashSessionDialogState();
}

class _CashSessionDialogState extends ConsumerState<CashSessionDialog> {
  Map<String, dynamic>? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShiftSummary();
  }

  Future<void> _loadShiftSummary() async {
    final salesRepo = ref.read(salesRepositoryProvider);
    final data = await salesRepo.getShiftSummary();
    if (mounted) {
      setState(() {
        _summary = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePrintXReport() async {
    if (_summary == null) return;
    final authState = ref.read(authProvider);

    final success = await PrinterService.instance.printXReport(
      summary: _summary!,
      cashierName: authState.user?.name ?? 'Cashier',
      deviceUuid: authState.deviceUuid ?? 'mobile-terminal',
      store: authState.user?.store,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'X-Report printed successfully (${PrinterService.instance.type.toUpperCase()})'
                : 'Printer unreachable (${PrinterService.instance.host}:${PrinterService.instance.port})',
          ),
          backgroundColor: success ? AppColors.primary : AppColors.danger,
        ),
      );
    }
  }

  Future<void> _handleKickDrawer() async {
    final success = await PrinterService.instance.kickCashDrawer();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Cash drawer pulse sent (Pin ${PrinterService.instance.drawerPin})'
                : 'Cash drawer trigger failed',
          ),
          backgroundColor: success ? AppColors.primary : AppColors.danger,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final store = authState.user?.store;
    final currencySymbol = store?.currencySymbol ?? 'Rs.';

    return AlertDialog(
      backgroundColor: AppColors.surface,
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.point_of_sale, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Register Cash Shift (X-Report)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Text(
                          'Cashier: ${authState.user?.name ?? "Cashier"}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Summary Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: _isLoading
                  ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Cash in Drawer Primary Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cash in Register',
                                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Expected Cash Total',
                                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                              Text(
                                CurrencyFormatter.format(
                                  (_summary?['cashTotal'] as num?)?.toDouble() ?? 0.0,
                                  symbol: currencySymbol,
                                ),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Metrics Grid
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricTile(
                                label: 'Gross Revenue',
                                value: CurrencyFormatter.format(
                                  (_summary?['grossTotal'] as num?)?.toDouble() ?? 0.0,
                                  symbol: currencySymbol,
                                ),
                                icon: Icons.trending_up,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildMetricTile(
                                label: 'Transactions',
                                value: '${_summary?['totalSalesCount'] ?? 0} bills',
                                icon: Icons.receipt_long,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricTile(
                                label: 'Card Payments',
                                value: CurrencyFormatter.format(
                                  (_summary?['cardTotal'] as num?)?.toDouble() ?? 0.0,
                                  symbol: currencySymbol,
                                ),
                                icon: Icons.credit_card,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildMetricTile(
                                label: 'Bank Transfers',
                                value: CurrencyFormatter.format(
                                  (_summary?['bankTotal'] as num?)?.toDouble() ?? 0.0,
                                  symbol: currencySymbol,
                                ),
                                icon: Icons.account_balance,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Kick Drawer Button
                        OutlinedButton.icon(
                          onPressed: _handleKickDrawer,
                          icon: const Icon(Icons.meeting_room_outlined, size: 18),
                          label: const Text('Open Cash Drawer (Kickout)'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
                    ),
            ),

            // Dialog Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _handlePrintXReport,
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text('Print X-Report'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
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

  Widget _buildMetricTile({required String label, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
