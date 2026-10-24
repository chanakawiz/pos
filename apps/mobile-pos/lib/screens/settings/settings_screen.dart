import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/sale.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/catalog_provider.dart';
import '../../../providers/sync_provider.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _urlController = TextEditingController();
  List<SaleModel> _pendingSales = [];
  bool _isLoadingSales = false;

  @override
  void initState() {
    super.initState();
    _urlController.text = ApiClient.instance.baseUrl;
    _loadPendingSales();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingSales() async {
    setState(() => _isLoadingSales = true);
    final salesRepo = ref.read(salesRepositoryProvider);
    final sales = await salesRepo.getPendingSales();
    setState(() {
      _pendingSales = sales;
      _isLoadingSales = false;
    });
  }

  Future<void> _saveUrl() async {
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      await ApiClient.instance.setBaseUrl(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Server URL updated')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final syncState = ref.watch(syncProvider);
    final catalogState = ref.watch(catalogProvider);
    final currencySymbol = authState.user?.store?.currencySymbol ?? 'Rs.';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terminal Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section 1: Server Connection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.dns, color: AppColors.secondary),
                      SizedBox(width: 8),
                      Text('Central Backend Server', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _urlController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'API Base URL',
                      hintText: 'http://192.168.1.100:8000',
                      prefixIcon: Icon(Icons.link, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveUrl,
                      child: const Text('Save URL'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Section 2: Sync & Offline Storage
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.sync, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text('Offline Sync Engine', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Chip(
                        label: Text('${syncState.pendingSalesCount} pending'),
                        backgroundColor: syncState.pendingSalesCount > 0
                            ? AppColors.pending.withOpacity(0.2)
                            : AppColors.synced.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: syncState.pendingSalesCount > 0
                              ? AppColors.pending
                              : AppColors.synced,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'SQLite WAL durability active. Sales are committed locally first and automatically flushed to cloud.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary.withOpacity(0.9)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: syncState.isSyncing
                              ? null
                              : () async {
                                  await ref.read(syncProvider.notifier).syncNow();
                                  await _loadPendingSales();
                                },
                          icon: syncState.isSyncing
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.sync),
                          label: Text(syncState.isSyncing ? 'Syncing...' : 'Sync Now'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Section 3: Pending Sales List
          if (_isLoadingSales)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else if (_pendingSales.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Queued Offline Sales', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._pendingSales.map((s) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(s.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${s.items.length} items • ${s.soldAt.toString().substring(11, 16)}'),
                          trailing: Text(
                            CurrencyFormatter.format(s.totalAmount, symbol: currencySymbol),
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Section 4: Language & Terminal Preferences
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Preferences & Device', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Bilingual Sinhala Names (සිංහල)'),
                    subtitle: const Text('Show Sinhala product names on grid & receipts'),
                    value: catalogState.isBilingual,
                    onChanged: (_) => ref.read(catalogProvider.notifier).toggleBilingual(),
                  ),
                  const Divider(color: AppColors.border),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Device UUID'),
                    subtitle: Text(
                      ApiClient.instance.deviceUuid ?? 'None',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(authProvider.notifier).logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (ctx) => const LoginScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout, color: AppColors.danger),
              label: const Text('Log Out / Switch Cashier', style: TextStyle(color: AppColors.danger)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.danger),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
