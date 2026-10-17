import type { CatalogDelta, OfflineSale, StorageBridge, StorageScope } from './storage-types';

export interface SyncTransport {
  push: (payload: { device_uuid: string; transactions: OfflineSale[] }) => Promise<{
    synced_uuids: string[];
    failed_uuids?: { uuid: string; error: string }[];
  }>;
  pull: (params: { since_version: number; device_uuid: string }) => Promise<CatalogDelta>;
}

export async function synchronizeOfflineData(
  storage: StorageBridge,
  scope: StorageScope,
  transport: SyncTransport,
): Promise<{ syncedCount: number; pendingCount: number; hasFailures: boolean }> {
  const pending = await storage.getPendingOfflineSales(scope);
  const batch = pending.slice(0, 50);
  let syncedCount = 0;
  let hasFailures = false;
  if (batch.length > 0) {
    const response = await transport.push({ device_uuid: scope.deviceUuid, transactions: batch });
    if (!Array.isArray(response.synced_uuids)) throw new Error('Invalid sync acknowledgement');
    const submitted = new Set(batch.map((sale) => sale.transaction_uuid));
    const acknowledged = [...new Set(response.synced_uuids)].filter((uuid) => submitted.has(uuid));
    if (acknowledged.length > 0) {
      if (!await storage.markSalesSynced(scope, acknowledged)) throw new Error('Could not persist sync acknowledgement');
      syncedCount = acknowledged.length;
    }
    hasFailures = acknowledged.length !== batch.length || (response.failed_uuids?.length ?? 0) > 0;
  }

  const catalog = await storage.getCatalog(scope, { limit: 1 });
  const delta = await transport.pull({ since_version: catalog.current_version, device_uuid: scope.deviceUuid });
  await storage.applyCatalogDelta(scope, delta);
  // Re-read after network calls: a cashier may have saved another sale during the push.
  const remaining = await storage.getPendingOfflineSales(scope);
  return { syncedCount, pendingCount: remaining.length, hasFailures };
}
