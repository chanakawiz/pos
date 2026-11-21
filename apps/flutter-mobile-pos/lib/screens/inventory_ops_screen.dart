import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme/pos_theme.dart';
import '../models/inventory_ops.dart';
import '../providers/pos_inventory_ops_provider.dart';
import 'sync_status_ribbon.dart';

class InventoryOpsScreen extends ConsumerStatefulWidget {
  final int initialTab;

  const InventoryOpsScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<InventoryOpsScreen> createState() => _InventoryOpsScreenState();
}

class _InventoryOpsScreenState extends ConsumerState<InventoryOpsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final TextEditingController _stocktakeScanCtrl = TextEditingController();
  final TextEditingController _poScanCtrl = TextEditingController();
  final NumberFormat _currency = NumberFormat('#,##0');
  String? _expandedPoUuid;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _stocktakeScanCtrl.dispose();
    _poScanCtrl.dispose();
    super.dispose();
  }

  void _scanForStocktake(String code) {
    final line = ref.read(posInventoryOpsProvider.notifier).scanBarcodeForStocktake(code);
    _stocktakeScanCtrl.clear();
    if (line == null && mounted) {
      final err = ref.read(posInventoryOpsProvider).errorMessage;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: PosTheme.accentRed, content: Text(err)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final opsState = ref.watch(posInventoryOpsProvider);

    return Scaffold(
      backgroundColor: PosTheme.background,
      appBar: AppBar(
        backgroundColor: PosTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: PosTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'INVENTORY STOCKTAKE & PO RECEIVING',
              style: TextStyle(
                color: PosTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
              ),
            ),
            Text(
              'Barcode Cycle Counts • Goods Receipt Verification',
              style: TextStyle(color: PosTheme.textSecondary, fontSize: 11),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: PosTheme.primaryGold,
          labelColor: PosTheme.primaryGold,
          unselectedLabelColor: PosTheme.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.fact_check_outlined, size: 18), text: 'STOCKTAKE AUDIT'),
            Tab(icon: Icon(Icons.local_shipping_outlined, size: 18), text: 'PO RECEIVING'),
          ],
        ),
      ),
      body: Column(
        children: [
          const SyncStatusRibbon(),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildStocktakeTab(opsState),
                _buildPoReceivingTab(opsState),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStocktakeTab(PosInventoryOpsState state) {
    return Column(
      children: [
        // Scan Bar & KPIs
        Container(
          padding: const EdgeInsets.all(14),
          color: PosTheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _stocktakeScanCtrl,
                      style: const TextStyle(color: PosTheme.textPrimary, fontSize: 13),
                      onSubmitted: _scanForStocktake,
                      decoration: const InputDecoration(
                        hintText: 'Scan or enter barcode / SKU (e.g. 445566)...',
                        prefixIcon: Icon(Icons.qr_code_scanner, color: PosTheme.primaryGold, size: 18),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _scanForStocktake(_stocktakeScanCtrl.text),
                    child: const Text('SCAN +1'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: const [
                  ('445566', 'iPhone 16'),
                  ('556677', 'Galaxy S24'),
                  ('667788', 'AirPods Pro'),
                  ('334455', 'Dior Sauvage'),
                ]
                    .map(
                      (pair) => ActionChip(
                        backgroundColor: PosTheme.card,
                        side: const BorderSide(color: PosTheme.border),
                        label: Text(
                          '${pair.$1} • ${pair.$2}',
                          style: const TextStyle(color: PosTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                        onPressed: () => _scanForStocktake(pair.$1),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _kpiChip('Counted SKUs', '${state.totalCountedSkus}', PosTheme.primaryGold),
                  const SizedBox(width: 8),
                  _kpiChip('Discrepancies', '${state.discrepancySkus}', PosTheme.accentAmber),
                  const SizedBox(width: 8),
                  _kpiChip(
                    'Net Var.',
                    '${state.netQtyVariance >= 0 ? "+" : ""}${state.netQtyVariance}',
                    state.netQtyVariance == 0
                        ? PosTheme.accentGreen
                        : (state.netQtyVariance > 0 ? PosTheme.accentAmber : PosTheme.accentRed),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Scanned Items List
        Expanded(
          child: state.stocktakeLines.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 48, color: PosTheme.textMuted),
                      const SizedBox(height: 10),
                      const Text(
                        'Ready to Scan Shelf Stock',
                        style: TextStyle(color: PosTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Scan product barcodes or tap quick test chips above to count units.',
                        style: TextStyle(color: PosTheme.textSecondary, fontSize: 12),
                      ),
                      if (state.lastStocktakeNumber != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: PosTheme.accentGreen.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: PosTheme.accentGreen),
                          ),
                          child: Text(
                            'Last Finalized: ${state.lastStocktakeNumber}',
                            style: const TextStyle(color: PosTheme.accentGreen, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: state.stocktakeLines.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, idx) {
                    final line = state.stocktakeLines[idx];
                    final varColor = line.isMatched
                        ? PosTheme.accentGreen
                        : (line.isOver ? PosTheme.accentAmber : PosTheme.accentRed);
                    final varLabel = line.isMatched
                        ? 'MATCHED'
                        : (line.isOver ? '+${line.varianceQty} OVER' : '${line.varianceQty} SHORT');

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: PosTheme.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: PosTheme.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  line.productName,
                                  style: const TextStyle(
                                    color: PosTheme.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  'Expected: ${line.expectedQty} • SKU: ${line.sku}',
                                  style: const TextStyle(color: PosTheme.textSecondary, fontSize: 11),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: varColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    varLabel,
                                    style: TextStyle(color: varColor, fontSize: 10, fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: PosTheme.textSecondary),
                                onPressed: () => ref
                                    .read(posInventoryOpsProvider.notifier)
                                    .updateStocktakeCount(line.productId, line.countedQty - 1),
                              ),
                              Text(
                                '${line.countedQty}',
                                style: const TextStyle(
                                  color: PosTheme.primaryGold,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: PosTheme.primaryGold),
                                onPressed: () => ref
                                    .read(posInventoryOpsProvider.notifier)
                                    .updateStocktakeCount(line.productId, line.countedQty + 1),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        // Bottom Finalize Bar
        Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            color: PosTheme.surface,
            border: Border(top: BorderSide(color: PosTheme.border)),
          ),
          child: Row(
            children: [
              OutlinedButton(
                onPressed: state.stocktakeLines.isEmpty
                    ? null
                    : () => ref.read(posInventoryOpsProvider.notifier).clearStocktake(),
                child: const Text('CLEAR'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                  label: Text(
                    state.isSubmittingStocktake
                        ? 'FINALIZING AUDIT...'
                        : 'FINALIZE & SYNC ADJUSTMENTS',
                  ),
                  onPressed: state.stocktakeLines.isEmpty || state.isSubmittingStocktake
                      ? null
                      : () async {
                          final refNum = await ref.read(posInventoryOpsProvider.notifier).submitStocktake();
                          if (mounted && refNum != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: PosTheme.accentGreen,
                                content: Text('Stocktake $refNum synced & branch inventory adjusted!'),
                              ),
                            );
                          }
                        },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPoReceivingTab(PosInventoryOpsState state) {
    if (state.isLoadingPos) {
      return const Center(child: CircularProgressIndicator(color: PosTheme.primaryGold));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: state.purchaseOrders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, idx) {
        final po = state.purchaseOrders[idx];
        final isExpanded = _expandedPoUuid == po.uuid || (idx == 0 && _expandedPoUuid == null);

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: PosTheme.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: po.isReceived ? PosTheme.accentGreen.withValues(alpha: 0.45) : PosTheme.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: () => setState(() => _expandedPoUuid = isExpanded ? '' : po.uuid),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            po.purchaseNumber,
                            style: const TextStyle(
                              color: PosTheme.primaryGold,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${po.supplierName} • LKR ${_currency.format(po.totalAmount)}',
                            style: const TextStyle(color: PosTheme.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (po.isReceived ? PosTheme.accentGreen : PosTheme.accentAmber)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        po.isReceived ? 'RECEIVED' : '${po.totalReceivedUnits}/${po.totalOrderedUnits} VERIFIED',
                        style: TextStyle(
                          color: po.isReceived ? PosTheme.accentGreen : PosTheme.accentAmber,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isExpanded) ...[
                const Divider(color: PosTheme.border, height: 20),
                if (!po.isReceived) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _poScanCtrl,
                          style: const TextStyle(color: PosTheme.textPrimary, fontSize: 12),
                          onSubmitted: (code) {
                            ref.read(posInventoryOpsProvider.notifier).scanBarcodeForPo(po.uuid, code);
                            _poScanCtrl.clear();
                          },
                          decoration: const InputDecoration(
                            hintText: 'Scan arriving item barcode to verify...',
                            prefixIcon: Icon(Icons.qr_code_scanner, color: PosTheme.primaryGold, size: 16),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {
                          ref.read(posInventoryOpsProvider.notifier).scanBarcodeForPo(po.uuid, _poScanCtrl.text);
                          _poScanCtrl.clear();
                        },
                        child: const Text('VERIFY'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                ...po.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: const TextStyle(
                                  color: PosTheme.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Ordered: ${item.orderedQty} • Barcode: ${item.barcode}',
                                style: const TextStyle(color: PosTheme.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        if (!po.isReceived) ...[
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 18, color: PosTheme.textSecondary),
                            onPressed: () => ref
                                .read(posInventoryOpsProvider.notifier)
                                .updatePoItemReceivedQty(po.uuid, item.productId, item.receivedQty - 1),
                          ),
                          Text(
                            '${item.receivedQty}/${item.orderedQty}',
                            style: TextStyle(
                              color: item.isComplete ? PosTheme.accentGreen : PosTheme.primaryGold,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 18, color: PosTheme.primaryGold),
                            onPressed: () => ref
                                .read(posInventoryOpsProvider.notifier)
                                .updatePoItemReceivedQty(po.uuid, item.productId, item.receivedQty + 1),
                          ),
                        ] else
                          Text(
                            '${item.receivedQty} received',
                            style: const TextStyle(
                              color: PosTheme.accentGreen,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (!po.isReceived) ...[
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.inventory_outlined, size: 18),
                    label: Text(
                      po.totalReceivedUnits > 0
                          ? 'CONFIRM VERIFIED RECEIPT (${po.totalReceivedUnits} UNITS)'
                          : 'RECEIVE FULL PO TO STOCK',
                    ),
                    onPressed: state.isReceivingPo
                        ? null
                        : () async {
                            final ok = await ref.read(posInventoryOpsProvider.notifier).confirmReceivePo(po.uuid);
                            if (mounted && ok) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: PosTheme.accentGreen,
                                  content: Text('PO ${po.purchaseNumber} received into branch stock!'),
                                ),
                              );
                            }
                          },
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _kpiChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: PosTheme.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: PosTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: PosTheme.textMuted, fontSize: 10)),
            Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}
