import axios from 'axios';
import { api } from './api';
import { getStorageScope } from './offlineStorage';
import { synchronizeOfflineData } from '../../electron/sync-engine';
import { usePosStore } from '../stores/usePosStore';

class SyncWorker {
  private timer: ReturnType<typeof setInterval> | null = null;
  private startupTimer: ReturnType<typeof setTimeout> | null = null;
  private isSyncing = false;

  public start() {
    if (this.timer) return;
    this.startupTimer = setTimeout(() => { void this.runSyncCycle(); }, 1500);
    this.timer = setInterval(() => { void this.runSyncCycle(); }, 20000);
  }

  public stop() {
    if (this.timer) clearInterval(this.timer);
    if (this.startupTimer) clearTimeout(this.startupTimer);
    this.timer = null;
    this.startupTimer = null;
  }

  public async triggerImmediateSync(): Promise<{ success: boolean; syncedCount: number; message: string }> {
    return this.runSyncCycle();
  }

  private async runSyncCycle(): Promise<{ success: boolean; syncedCount: number; message: string }> {
    if (this.isSyncing) return { success: false, syncedCount: 0, message: 'Sync already in progress' };
    this.isSyncing = true;
    const { setOnline, setSyncStatus, setPendingCount } = usePosStore.getState();
    let scope: ReturnType<typeof getStorageScope> | undefined;
    try {
      // Show recovered queue totals even when the server is offline.
      if (window.posApi) {
        scope = getStorageScope();
        setPendingCount((await window.posApi.getPendingOfflineSales(scope)).length);
      }
      await api.syncStatus();
      setOnline(true);
      setSyncStatus('syncing');

      if (!window.posApi || !scope) {
        setSyncStatus('synced');
        return { success: true, syncedCount: 0, message: 'Connected. Offline storage requires the desktop app.' };
      }
      const result = await synchronizeOfflineData(window.posApi, scope, {
        push: api.syncPush,
        pull: api.syncPull,
      });
      setPendingCount(result.pendingCount);
      setSyncStatus(result.hasFailures ? 'error' : result.pendingCount > 0 ? 'pending' : 'synced');
      window.dispatchEvent(new Event('pos:catalog-updated'));
      return {
        success: !result.hasFailures,
        syncedCount: result.syncedCount,
        message: result.pendingCount > 0
          ? `${result.syncedCount} synced; ${result.pendingCount} transactions still pending`
          : result.syncedCount > 0 ? `Synced ${result.syncedCount} offline transactions` : 'All records up to date',
      };
    } catch (error: unknown) {
      const networkError = axios.isAxiosError(error) && !error.response;
      if (networkError) setOnline(false);
      setSyncStatus(networkError ? 'pending' : 'error');
      // A completed push remains acknowledged even when a later pull fails.
      if (scope && window.posApi) {
        try { setPendingCount((await window.posApi.getPendingOfflineSales(scope)).length); } catch { /* Retain last known count. */ }
      }
      return {
        success: false, syncedCount: 0,
        message: networkError ? 'Server unreachable. Local sales remain queued.' : 'Sync failed. Check connectivity and local storage before retrying.',
      };
    } finally {
      this.isSyncing = false;
    }
  }
}

export const syncWorker = new SyncWorker();
