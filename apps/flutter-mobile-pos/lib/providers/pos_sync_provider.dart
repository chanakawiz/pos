import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/pos_product.dart';
import '../services/pos_database_service.dart';
import 'pos_auth_provider.dart';

class PosSyncState {
  final bool isOnline;
  final bool isSyncing;
  final int pendingSalesCount;
  final int catalogVersion;
  final DateTime? lastSyncAt;
  final String? syncMessage;
  final String? errorMessage;

  const PosSyncState({
    this.isOnline = true,
    this.isSyncing = false,
    this.pendingSalesCount = 0,
    this.catalogVersion = 1,
    this.lastSyncAt,
    this.syncMessage,
    this.errorMessage,
  });

  PosSyncState copyWith({
    bool? isOnline,
    bool? isSyncing,
    int? pendingSalesCount,
    int? catalogVersion,
    DateTime? lastSyncAt,
    String? syncMessage,
    String? errorMessage,
  }) {
    return PosSyncState(
      isOnline: isOnline ?? this.isOnline,
      isSyncing: isSyncing ?? this.isSyncing,
      pendingSalesCount: pendingSalesCount ?? this.pendingSalesCount,
      catalogVersion: catalogVersion ?? this.catalogVersion,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      syncMessage: syncMessage ?? this.syncMessage,
      errorMessage: errorMessage,
    );
  }
}

class PosSyncNotifier extends StateNotifier<PosSyncState> {
  final Ref ref;

  PosSyncNotifier(this.ref) : super(const PosSyncState()) {
    refreshPendingCount();
  }

  Future<void> refreshPendingCount() async {
    final count = await PosDatabaseService.instance.getPendingSalesCount();
    final v = await PosDatabaseService.instance.getCheckpointVersion('catalog');
    state = state.copyWith(
      pendingSalesCount: count,
      catalogVersion: v > 0 ? v : 1,
    );
  }

  Future<bool> checkConnectivity() async {
    final session = ref.read(posAuthProvider).session;
    try {
      final uri = Uri.parse('${session.apiUrl}/api/v1/health/live');
      final response = await http.get(uri).timeout(const Duration(seconds: 3));
      final online = response.statusCode == 200;
      state = state.copyWith(isOnline: online);
      return online;
    } catch (_) {
      state = state.copyWith(isOnline: false);
      return false;
    }
  }

  /// Push batch of offline queued sales to `/api/v1/sync/push`
  Future<int> pushOfflineSales() async {
    state = state.copyWith(isSyncing: true, syncMessage: 'Pushing offline sales to ERP...', errorMessage: null);
    final session = ref.read(posAuthProvider).session;
    final queueItems = await PosDatabaseService.instance.getPendingSyncQueue();

    if (queueItems.isEmpty) {
      state = state.copyWith(isSyncing: false, syncMessage: 'All transactions synced.');
      return 0;
    }

    int syncedCount = 0;
    final transactions = queueItems.map((item) {
      try {
        return jsonDecode(item['payload_json']);
      } catch (_) {
        return item;
      }
    }).toList();

    try {
      final uri = Uri.parse('${session.apiUrl}/api/v1/sync/push');
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'X-Device-UUID': session.deviceUuid,
              if (session.apiToken != null) 'Authorization': 'Bearer ${session.apiToken}',
            },
            body: jsonEncode({
              'device_uuid': session.deviceUuid,
              'transactions': transactions,
            }),
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Mark items as synced
        for (final item in queueItems) {
          final uuid = item['record_uuid'];
          await PosDatabaseService.instance.markSaleSynced(uuid);
          syncedCount++;
        }
      }
    } catch (_) {
      // Offline fallback: keep in queue for next connectivity window
    }

    final remainingCount = await PosDatabaseService.instance.getPendingSalesCount();
    state = state.copyWith(
      isSyncing: false,
      pendingSalesCount: remainingCount,
      syncMessage: syncedCount > 0 ? 'Pushed $syncedCount sales successfully' : null,
      lastSyncAt: DateTime.now(),
    );

    return syncedCount;
  }

  /// Pull delta catalog updates from `/api/v1/sync/pull`
  Future<int> pullCatalogDelta() async {
    state = state.copyWith(isSyncing: true, syncMessage: 'Checking for catalog updates...');
    final session = ref.read(posAuthProvider).session;
    final currentVersion = state.catalogVersion;
    int updatedCount = 0;

    try {
      final uri = Uri.parse('${session.apiUrl}/api/v1/sync/pull?since_version=$currentVersion');
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'X-Device-UUID': session.deviceUuid,
          if (session.apiToken != null) 'Authorization': 'Bearer ${session.apiToken}',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final productsData = data['products'] ?? data['delta'] ?? [];
        final newVersion = (data['latest_version'] as num?)?.toInt() ?? (currentVersion + 1);

        if (productsData is List && productsData.isNotEmpty) {
          final products = productsData.map((json) => PosProduct.fromJson(json)).toList();
          await PosDatabaseService.instance.bulkUpsertProducts(products);
          updatedCount = products.length;
        }

        await PosDatabaseService.instance.setCheckpointVersion('catalog', newVersion);
        state = state.copyWith(catalogVersion: newVersion);
      }
    } catch (_) {
      // Offline fallback
    }

    state = state.copyWith(
      isSyncing: false,
      syncMessage: updatedCount > 0 ? 'Catalog updated ($updatedCount items)' : 'Catalog is up to date',
      lastSyncAt: DateTime.now(),
    );

    return updatedCount;
  }

  /// Run full bidirectional sync (push sales, then pull catalog)
  Future<void> runFullSync() async {
    await checkConnectivity();
    await pushOfflineSales();
    await pullCatalogDelta();
    await refreshPendingCount();
  }
}

final posSyncProvider = StateNotifierProvider<PosSyncNotifier, PosSyncState>((ref) {
  return PosSyncNotifier(ref);
});
