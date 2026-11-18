import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/pos_theme.dart';
import '../providers/pos_sync_provider.dart';

class SyncStatusRibbon extends ConsumerWidget {
  const SyncStatusRibbon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(posSyncProvider);

    if (syncState.pendingSalesCount == 0 && syncState.isOnline && !syncState.isSyncing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        color: const Color(0xFF0D1210),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: PosTheme.statusSuccess,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'CLOUD SYNC ACTIVE',
              style: TextStyle(
                color: PosTheme.statusSuccess,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const Spacer(),
            Text(
              'SQLite WAL Engine Ready',
              style: TextStyle(color: PosTheme.textMuted, fontSize: 10),
            ),
          ],
        ),
      );
    }

    // Pending sales or offline alert ribbon
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: syncState.pendingSalesCount > 0
          ? PosTheme.statusWarning.withValues(alpha: 0.2)
          : PosTheme.cardDark,
      child: Row(
        children: [
          Icon(
            syncState.isSyncing
                ? Icons.sync
                : (syncState.pendingSalesCount > 0 ? Icons.cloud_upload_outlined : Icons.cloud_off_outlined),
            size: 16,
            color: syncState.pendingSalesCount > 0 ? PosTheme.statusWarning : PosTheme.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              syncState.isSyncing
                  ? (syncState.syncMessage ?? 'Syncing with Central ERP...')
                  : (syncState.pendingSalesCount > 0
                      ? '${syncState.pendingSalesCount} Offline Sales Awaiting Cloud Push'
                      : 'Offline Mode (Transactions queued locally)'),
              style: TextStyle(
                color: syncState.pendingSalesCount > 0 ? PosTheme.statusWarning : PosTheme.textWhite,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (syncState.isSyncing)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: PosTheme.primaryGold),
            )
          else
            TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                backgroundColor: PosTheme.primaryGold,
                foregroundColor: const Color(0xFF111413),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.sync, size: 12),
              label: const Text('SYNC NOW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
              onPressed: () => ref.read(posSyncProvider.notifier).runFullSync(),
            ),
        ],
      ),
    );
  }
}
