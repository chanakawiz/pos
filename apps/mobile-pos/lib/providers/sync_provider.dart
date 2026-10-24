import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/sales_repository.dart';
import '../data/repositories/sync_repository.dart';

class SyncState {
  final bool isSyncing;
  final int pendingSalesCount;
  final DateTime? lastSyncTime;
  final String? statusMessage;

  const SyncState({
    this.isSyncing = false,
    this.pendingSalesCount = 0,
    this.lastSyncTime,
    this.statusMessage,
  });

  SyncState copyWith({
    bool? isSyncing,
    int? pendingSalesCount,
    DateTime? lastSyncTime,
    String? statusMessage,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      pendingSalesCount: pendingSalesCount ?? this.pendingSalesCount,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

class SyncNotifier extends StateNotifier<SyncState> {
  final SyncRepository _syncRepo;
  final SalesRepository _salesRepo;

  SyncNotifier(this._syncRepo, this._salesRepo) : super(const SyncState()) {
    refreshPendingCount();
  }

  Future<void> refreshPendingCount() async {
    final pending = await _salesRepo.getPendingSales();
    state = state.copyWith(pendingSalesCount: pending.length);
  }

  Future<void> syncNow() async {
    if (state.isSyncing) return;
    state = state.copyWith(isSyncing: true, statusMessage: 'Syncing sales & catalog...');

    try {
      final pushedCount = await _syncRepo.pushPendingSales();
      final updatedCatalog = await _syncRepo.pullCatalogDelta();
      final remainingPending = await _salesRepo.getPendingSales();

      state = state.copyWith(
        isSyncing: false,
        pendingSalesCount: remainingPending.length,
        lastSyncTime: DateTime.now(),
        statusMessage: 'Synced $pushedCount sales, updated $updatedCatalog items',
      );
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        statusMessage: 'Sync failed: network offline',
      );
    }
  }
}

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepository();
});

final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  return SalesRepository();
});

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  final syncRepo = ref.watch(syncRepositoryProvider);
  final salesRepo = ref.watch(salesRepositoryProvider);
  return SyncNotifier(syncRepo, salesRepo);
});
