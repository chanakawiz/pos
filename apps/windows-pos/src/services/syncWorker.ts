import { api } from './api';
import { usePosStore } from '../stores/usePosStore';

class SyncWorker {
  private timer: ReturnType<typeof setInterval> | null = null;
  private isSyncing = false;
  private intervalMs = 20000; // 20 seconds background heartbeat

  public start() {
    if (this.timer) return;
    console.log('[SyncWorker] Background sync daemon started');

    // Run first sync immediately after startup
    setTimeout(() => this.runSyncCycle(), 1500);

    this.timer = setInterval(() => {
      this.runSyncCycle();
    }, this.intervalMs);
  }

  public stop() {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
      console.log('[SyncWorker] Background sync daemon stopped');
    }
  }

  public async triggerImmediateSync(): Promise<{ success: boolean; syncedCount: number; message: string }> {
    return this.runSyncCycle();
  }

  private async runSyncCycle(): Promise<{ success: boolean; syncedCount: number; message: string }> {
    if (this.isSyncing) {
      return { success: false, syncedCount: 0, message: 'Sync already in progress' };
    }

    this.isSyncing = true;
    const { setOnline, setSyncStatus, setPendingCount } = usePosStore.getState();

    try {
      // 1. Health check
      await api.syncStatus();
      setOnline(true);

      // 2. Fetch pending offline sales
      let pendingSales: any[] = [];
      if (window.posApi?.getPendingOfflineSales) {
        pendingSales = await window.posApi.getPendingOfflineSales();
      } else {
        const stored = localStorage.getItem('smartshop_offline_queue');
        if (stored) {
          try {
            pendingSales = JSON.parse(stored).filter((s: any) => s.sync_status === 'pending');
          } catch {
            pendingSales = [];
          }
        }
      }

      setPendingCount(pendingSales.length);

      let syncedCount = 0;

      // 3. Push pending sales if any
      if (pendingSales.length > 0) {
        setSyncStatus('syncing');

        const deviceUuid = localStorage.getItem('pos_device_uuid') || '550e8400-e29b-41d4-a716-446655440000';
        const batch = pendingSales.slice(0, 50);

        const pushRes = await api.syncPush({
          device_uuid: deviceUuid,
          transactions: batch,
        });

        if (pushRes.synced_uuids && pushRes.synced_uuids.length > 0) {
          syncedCount = pushRes.synced_uuids.length;

          if (window.posApi?.markSalesSynced) {
            await window.posApi.markSalesSynced(pushRes.synced_uuids);
          } else {
            const stored = localStorage.getItem('smartshop_offline_queue');
            if (stored) {
              const all = JSON.parse(stored).map((s: any) =>
                pushRes.synced_uuids.includes(s.transaction_uuid) ? { ...s, sync_status: 'synced' } : s
              );
              localStorage.setItem('smartshop_offline_queue', JSON.stringify(all));
            }
          }

          const remainingCount = Math.max(0, pendingSales.length - syncedCount);
          setPendingCount(remainingCount);
        }
      }

      // 4. Pull catalog deltas
      const lastVersion = parseInt(localStorage.getItem('pos_last_synced_version') || '0', 10);
      const pullRes = await api.syncPull({ since_version: lastVersion });

      if (pullRes && pullRes.current_version) {
        localStorage.setItem('pos_last_synced_version', pullRes.current_version.toString());
      }

      setSyncStatus('synced');
      return {
        success: true,
        syncedCount,
        message: syncedCount > 0 ? `Synced ${syncedCount} offline transactions` : 'All records up to date',
      };
    } catch (err: any) {
      console.warn('[SyncWorker] Sync failed or offline:', err.message);
      setOnline(false);
      setSyncStatus('pending');
      return { success: false, syncedCount: 0, message: 'Server unreachable or offline' };
    } finally {
      this.isSyncing = false;
    }
  }
}

export const syncWorker = new SyncWorker();
