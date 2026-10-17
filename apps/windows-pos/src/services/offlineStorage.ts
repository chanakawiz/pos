import type { CatalogQuery, StorageScope } from '../../electron/storage-types';
import { useAuthStore } from '../stores/useAuthStore';

export function getStorageScope(): StorageScope {
  const { user, deviceUuid } = useAuthStore.getState();
  if (!user?.store?.uuid) throw new Error('A store must be assigned before using local POS storage');
  return { storeUuid: user.store.uuid, deviceUuid };
}

export async function getCachedCatalog(query?: CatalogQuery) {
  if (!window.posApi) return null;
  return window.posApi.getCatalog(getStorageScope(), query);
}

export async function getCachedProductByBarcode(barcode: string) {
  if (!window.posApi) return null;
  return window.posApi.getCachedProductByBarcode(getStorageScope(), barcode);
}
