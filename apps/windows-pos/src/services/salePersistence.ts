import type { OfflineSale, StorageBridge, StorageScope } from '../../electron/storage-types';

/** A completed desktop sale is durable before any network request can be attempted. */
export async function persistSale(
  storage: StorageBridge,
  scope: StorageScope,
  sale: OfflineSale,
): Promise<void> {
  let result;
  try {
    result = await storage.saveOfflineSale(scope, sale);
  } catch (error: unknown) {
    throw new Error('Unable to save this sale locally. Check available disk space or contact support, then retry. Your cart has been kept.', { cause: error });
  }
  if (!result.success || result.id !== sale.transaction_uuid) {
    throw new Error('Sale could not be saved to local storage. Please retry.');
  }
}
