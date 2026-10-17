import React, { useState, useEffect } from 'react';
import { usePosStore } from '../stores/usePosStore';
import { syncWorker } from '../services/syncWorker';
import { getStorageScope } from '../services/offlineStorage';
import type { OfflineSale } from '../../electron/storage-types';
import { useAuthStore } from '../stores/useAuthStore';
import {
  X,
  RefreshCw,
  Wifi,
  WifiOff,
  CheckCircle2,
  Clock,
  HardDrive,
  Database,
  ShieldCheck,
} from 'lucide-react';

export const SyncStatusModal: React.FC = () => {
  const { isOnline, pendingCount, closeModal } = usePosStore();

  const [offlineSales, setOfflineSales] = useState<OfflineSale[]>([]);
  const [deviceInfo, setDeviceInfo] = useState<any>({
    deviceUuid: useAuthStore.getState().deviceUuid || 'Unconfigured',
    platform: 'win32',
    appVersion: '1.0.0',
  });
  const [catalogVersion, setCatalogVersion] = useState<string>('0');
  const [isSyncing, setIsSyncing] = useState<boolean>(false);
  const [syncFeedback, setSyncFeedback] = useState<string | null>(null);

  const loadOfflineData = async () => {
    if (window.posApi?.getAllOfflineSales) {
      try {
        const scope = getStorageScope();
        const sales = await window.posApi.getAllOfflineSales(scope);
        setOfflineSales(sales || []);
        const catalog = await window.posApi.getCatalog(scope, { limit: 1 });
        setCatalogVersion(String(catalog.current_version));
        usePosStore.getState().setPendingCount(sales.filter((sale) => sale.sync_status === 'pending').length);
      } catch {
        setSyncFeedback('Unable to read local storage. Pending sales may require recovery.');
      }
    }

    if (window.posApi?.getDeviceInfo) {
      try {
        const info = await window.posApi.getDeviceInfo();
        setDeviceInfo({ ...info, deviceUuid: useAuthStore.getState().deviceUuid || 'Unconfigured' });
      } catch {
        // Fallback
      }
    }

  };

  useEffect(() => {
    loadOfflineData();
  }, []);

  const handleManualSync = async () => {
    setIsSyncing(true);
    setSyncFeedback(null);
    try {
      const res = await syncWorker.triggerImmediateSync();
      setSyncFeedback(res.message);
      await loadOfflineData();
    } catch {
      setSyncFeedback('Manual sync encountered network timeout');
    } finally {
      setIsSyncing(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 bg-slate-950/80 backdrop-blur-sm flex items-center justify-center p-4">
      <div className="bg-slate-900 border border-slate-800 rounded-3xl w-full max-w-2xl shadow-2xl overflow-hidden flex flex-col animate-in fade-in zoom-in-95 duration-150">
        {/* Header */}
        <div className="p-5 border-b border-slate-800 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-xl bg-indigo-600/20 text-indigo-400 flex items-center justify-center border border-indigo-500/30">
              <RefreshCw className={`w-5 h-5 ${isSyncing ? 'animate-spin' : ''}`} />
            </div>
            <div>
              <h3 className="text-base font-bold text-white">Offline Engine & Sync Diagnostics</h3>
              <p className="text-xs text-slate-400 mt-0.5">Zero-downtime offline queue and bidirectional sync</p>
            </div>
          </div>
          <button
            onClick={closeModal}
            className="p-1.5 text-slate-400 hover:text-white hover:bg-slate-800 rounded-lg transition-colors cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content Area */}
        <div className="p-6 space-y-5 flex-1 max-h-[75vh] overflow-y-auto">
          {/* Status Banner */}
          <div
            className={`p-4 rounded-2xl border flex items-center justify-between ${
              isOnline
                ? 'bg-emerald-950/30 border-emerald-900/50 text-emerald-300'
                : 'bg-rose-950/30 border-rose-900/50 text-rose-300'
            }`}
          >
            <div className="flex items-center gap-3">
              {isOnline ? (
                <div className="w-10 h-10 rounded-xl bg-emerald-500/20 flex items-center justify-center border border-emerald-500/30">
                  <Wifi className="w-5 h-5 text-emerald-400" />
                </div>
              ) : (
                <div className="w-10 h-10 rounded-xl bg-rose-500/20 flex items-center justify-center border border-rose-500/30">
                  <WifiOff className="w-5 h-5 text-rose-400" />
                </div>
              )}
              <div>
                <h4 className="text-sm font-bold text-white">
                  {isOnline ? 'Cloud Backend Connected' : 'Station Operating in Offline Mode'}
                </h4>
                <p className="text-xs text-slate-400 mt-0.5">
                  {isOnline
                    ? 'Automatic background sync daemon active (every 20s)'
                    : window.posApi ? 'Sales stored locally; pending sales retry when connected' : 'Offline checkout requires the desktop app'}
                </p>
              </div>
            </div>

            <button
              onClick={handleManualSync}
              disabled={isSyncing}
              className="px-4 py-2 bg-indigo-600 hover:bg-indigo-500 disabled:opacity-50 text-white text-xs font-bold rounded-xl shadow-md flex items-center gap-1.5 transition-all cursor-pointer"
            >
              <RefreshCw className={`w-3.5 h-3.5 ${isSyncing ? 'animate-spin' : ''}`} />
              <span>{isSyncing ? 'Syncing...' : 'Sync Now'}</span>
            </button>
          </div>

          {syncFeedback && (
            <div className="p-3 rounded-xl bg-indigo-950/40 border border-indigo-900/50 text-indigo-300 text-xs flex items-center gap-2">
              <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />
              <span>{syncFeedback}</span>
            </div>
          )}

          {/* Metrics Grid */}
          <div className="grid grid-cols-3 gap-3">
            <div className="bg-slate-950/60 border border-slate-800 rounded-2xl p-4">
              <div className="flex items-center gap-1.5 text-xs text-amber-400 mb-1">
                <Clock className="w-3.5 h-3.5" />
                <span>Pending Sync</span>
              </div>
              <div className="text-2xl font-black font-mono text-white">{pendingCount}</div>
              <span className="text-[10px] text-slate-500">bills queued for push</span>
            </div>

            <div className="bg-slate-950/60 border border-slate-800 rounded-2xl p-4">
              <div className="flex items-center gap-1.5 text-xs text-emerald-400 mb-1">
                <Database className="w-3.5 h-3.5" />
                <span>Catalog Version</span>
              </div>
              <div className="text-2xl font-black font-mono text-white">v{catalogVersion}</div>
              <span className="text-[10px] text-slate-500">delta pull revision</span>
            </div>

            <div className="bg-slate-950/60 border border-slate-800 rounded-2xl p-4">
              <div className="flex items-center gap-1.5 text-xs text-indigo-400 mb-1">
                <HardDrive className="w-3.5 h-3.5" />
                <span>Local Engine</span>
              </div>
              <div className="text-sm font-bold text-white mt-1">{window.posApi ? 'SQLite (WAL)' : 'Online browser'}</div>
              <span className="text-[10px] text-slate-500">idempotent store</span>
            </div>
          </div>

          {/* Device Hardware Spec */}
          <div className="bg-slate-950/40 border border-slate-800 rounded-2xl p-3.5 text-xs space-y-1.5 text-slate-400">
            <div className="flex justify-between items-center">
              <span className="flex items-center gap-1.5">
                <ShieldCheck className="w-3.5 h-3.5 text-emerald-400" />
                Hardware Terminal UUID:
              </span>
              <span className="font-mono text-white">{deviceInfo.deviceUuid}</span>
            </div>
            <div className="flex justify-between items-center text-[11px]">
              <span>Station Platform:</span>
              <span className="text-slate-300 capitalize">{deviceInfo.platform} (v{deviceInfo.appVersion})</span>
            </div>
          </div>

          {/* Offline Sales Queue List */}
          <div>
            <div className="flex items-center justify-between mb-2.5">
              <h4 className="text-xs font-semibold text-slate-300">Recent Offline Transactions Log</h4>
              <span className="text-[10px] text-slate-500">Total logged: {offlineSales.length}</span>
            </div>

            {offlineSales.length === 0 ? (
              <div className="py-10 text-center text-slate-500 bg-slate-950/30 rounded-2xl border border-slate-800">
                <CheckCircle2 className="w-8 h-8 mx-auto mb-2 text-emerald-500/50" />
                <p className="text-xs">No pending or offline sales recorded on this lane.</p>
                <p className="text-[10px] text-slate-600 mt-0.5">All transactions synced in real-time.</p>
              </div>
            ) : (
              <div className="space-y-2 max-h-[220px] overflow-y-auto">
                {offlineSales.slice(-10).reverse().map((sale: any, idx: number) => {
                  const isPending = sale.sync_status === 'pending';
                  return (
                    <div
                      key={sale.local_id || sale.transaction_uuid || idx}
                      className="bg-slate-950/60 border border-slate-800 rounded-xl p-3 flex items-center justify-between text-xs"
                    >
                      <div>
                        <div className="flex items-center gap-2">
                          <span className="font-mono font-bold text-white">
                            {sale.invoice_number || sale.local_id}
                          </span>
                          <span
                            className={`text-[10px] font-bold px-2 py-0.2 rounded-full border ${
                              isPending
                                ? 'bg-amber-500/10 text-amber-400 border-amber-500/20'
                                : 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20'
                            }`}
                          >
                            {sale.sync_status?.toUpperCase() || 'SYNCED'}
                          </span>
                        </div>
                        <p className="text-[10px] text-slate-400 mt-0.5">
                          {sale.created_at ? new Date(sale.created_at).toLocaleString() : 'Offline transaction'} •{' '}
                          {sale.items?.length || 1} items
                        </p>
                      </div>

                      <div className="text-right">
                        <div className="font-mono font-bold text-emerald-400">
                          ${Number(sale.total_amount || 0).toFixed(2)}
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};
