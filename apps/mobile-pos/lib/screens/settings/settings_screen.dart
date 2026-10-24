import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/printer/printer_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/sale.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/catalog_provider.dart';
import '../../../providers/sync_provider.dart';
import '../auth/login_screen.dart';
import '../auth/pairing_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _printerHostController = TextEditingController();
  final TextEditingController _printerPortController = TextEditingController();

  List<SaleModel> _pendingSales = [];
  bool _isLoadingSales = false;

  // Printer settings local state
  late bool _printerEnabled;
  late String _printerType;
  late int _paperWidth;
  late bool _autoCut;
  late bool _drawerEnabled;
  late int _drawerPin;
  late bool _autoPrint;

  @override
  void initState() {
    super.initState();
    _urlController.text = ApiClient.instance.baseUrl;

    final printer = PrinterService.instance;
    _printerEnabled = printer.isEnabled;
    _printerType = printer.type;
    _printerHostController.text = printer.host;
    _printerPortController.text = printer.port.toString();
    _paperWidth = printer.paperWidth;
    _autoCut = printer.autoCut;
    _drawerEnabled = printer.drawerEnabled;
    _drawerPin = printer.drawerPin;
    _autoPrint = printer.autoPrintOnCheckout;

    _loadPendingSales();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _printerHostController.dispose();
    _printerPortController.dispose();
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

  Future<void> _savePrinterSettings() async {
    final host = _printerHostController.text.trim();
    final port = int.tryParse(_printerPortController.text.trim()) ?? 9100;

    await PrinterService.instance.saveSettings(
      isEnabled: _printerEnabled,
      type: _printerType,
      host: host.isNotEmpty ? host : '192.168.1.100',
      port: port,
      paperWidth: _paperWidth,
      autoCut: _autoCut,
      drawerEnabled: _drawerEnabled,
      drawerPin: _drawerPin,
      autoPrintOnCheckout: _autoPrint,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Printer settings saved')),
      );
    }
  }

  Future<void> _testPrint() async {
    final authState = ref.read(authProvider);
    final success = await PrinterService.instance.testPrint(authState.user?.store);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Test print dispatched (${_printerType.toUpperCase()})'
                : 'Test print failed (Printer unreachable)',
          ),
          backgroundColor: success ? AppColors.primary : AppColors.danger,
        ),
      );
    }
  }

  Future<void> _testDrawer() async {
    final success = await PrinterService.instance.kickCashDrawer();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Cash drawer kick pulse sent (Pin $_drawerPin)'
                : 'Cash drawer trigger failed',
          ),
          backgroundColor: success ? AppColors.primary : AppColors.danger,
        ),
      );
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

          // Section 4: ESC/POS Thermal Receipt Printer & Cash Drawer
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.print, color: AppColors.secondary),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text('ESC/POS Thermal Printer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _printerEnabled,
                        onChanged: (val) {
                          setState(() => _printerEnabled = val);
                          _savePrinterSettings();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Connection Mode
                  DropdownButtonFormField<String>(
                    value: _printerType,
                    decoration: const InputDecoration(labelText: 'Printer Connection'),
                    items: const [
                      DropdownMenuItem(value: 'mock', child: Text('Mock / In-App Simulation')),
                      DropdownMenuItem(value: 'tcp', child: Text('Network / WiFi (Raw TCP Port 9100)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _printerType = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Network Host & Port (if TCP)
                  if (_printerType == 'tcp') ...[
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _printerHostController,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'Printer IP Address',
                              hintText: '192.168.1.50',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: _printerPortController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'Port',
                              hintText: '9100',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Paper Width Selector
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Paper Roll Width:', style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('80mm (48 cols)')),
                              selected: _paperWidth == 80,
                              onSelected: (sel) {
                                if (sel) setState(() => _paperWidth = 80);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Center(child: Text('58mm (32 cols)')),
                              selected: _paperWidth == 58,
                              onSelected: (sel) {
                                if (sel) setState(() => _paperWidth = 58);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Auto-Cut & Auto-Print
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Auto-Cut Paper'),
                    subtitle: const Text('Issue partial cutter command at receipt end'),
                    value: _autoCut,
                    onChanged: (val) => setState(() => _autoCut = val),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Auto-Print on Checkout'),
                    subtitle: const Text('Print receipt immediately when payment succeeds'),
                    value: _autoPrint,
                    onChanged: (val) => setState(() => _autoPrint = val),
                  ),

                  const Divider(color: AppColors.border),

                  // Cash Drawer Settings
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('RJ11 Cash Drawer Kick'),
                    subtitle: const Text('Pulse drawer kick on cash sale finalization'),
                    value: _drawerEnabled,
                    onChanged: (val) => setState(() => _drawerEnabled = val),
                  ),
                  if (_drawerEnabled)
                    Row(
                      children: [
                        const Text('Drawer Pin:', style: TextStyle(color: AppColors.textSecondary)),
                        const Spacer(),
                        ChoiceChip(
                          label: const Text('Pin 2 (Standard)'),
                          selected: _drawerPin == 2,
                          onSelected: (sel) {
                            if (sel) setState(() => _drawerPin = 2);
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Pin 5'),
                          selected: _drawerPin == 5,
                          onSelected: (sel) {
                            if (sel) setState(() => _drawerPin = 5);
                          },
                        ),
                      ],
                    ),

                  const SizedBox(height: 14),

                  // Actions: Save & Test
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _savePrinterSettings,
                          child: const Text('Save Printer Config'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.outlined(
                        tooltip: 'Test Drawer Kick',
                        icon: const Icon(Icons.point_of_sale, color: AppColors.secondary),
                        onPressed: _testDrawer,
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: 'Test Print Receipt',
                        icon: const Icon(Icons.print, color: Colors.white),
                        onPressed: _testPrint,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Section 5: Preferences & Device Info
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
                    title: const Text('Secondary Model Subtitles'),
                    subtitle: const Text('Show detailed product subtitles on catalog & receipts'),
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
                    trailing: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (ctx) => const PairingScreen()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: const Text('Pair / Re-pair', style: TextStyle(fontSize: 12)),
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
