import type { PrinterBridge } from './printer-types';
import { contextBridge, ipcRenderer } from 'electron';
import type { StorageBridge } from './storage-types';
import type { CustomerDisplayBridge } from './customer-display-types';

export interface PosBridgeApi extends StorageBridge, PrinterBridge, CustomerDisplayBridge {
  getDeviceInfo: () => Promise<{ deviceUuid: string; platform: string; appVersion: string }>;
  onBarcodeScan: (callback: (barcode: string) => void) => () => void;
}

const posApi: PosBridgeApi = {
  publishCustomerDisplay: (state) => ipcRenderer.invoke('customer-display:publish', state),
  getCustomerDisplayStatus: () => ipcRenderer.invoke('customer-display:status'),
  setCustomerDisplayEnabled: (enabled) => ipcRenderer.invoke('customer-display:enable', enabled),
  printReceipt: (request) => ipcRenderer.invoke('printer:print-receipt', request),
  openCashDrawer: () => ipcRenderer.invoke('hardware:open-drawer'),
  getDeviceInfo: () => ipcRenderer.invoke('device:get-info'),
  onBarcodeScan: (callback: (barcode: string) => void) => {
    const handler = (_event: any, barcode: string) => callback(barcode);
    ipcRenderer.on('scanner:barcode', handler);
    return () => ipcRenderer.removeListener('scanner:barcode', handler);
  },
  saveOfflineSale: (scope, sale) => ipcRenderer.invoke('storage:save-offline-sale', scope, sale),
  getPendingOfflineSales: (scope) => ipcRenderer.invoke('storage:get-offline-sales', scope),
  getAllOfflineSales: (scope) => ipcRenderer.invoke('storage:get-all-offline-sales', scope),
  markSalesSynced: (scope, uuids) => ipcRenderer.invoke('storage:mark-synced', scope, uuids),
  getCatalog: (scope, query) => ipcRenderer.invoke('storage:get-catalog', scope, query),
  getCachedProductByBarcode: (scope, barcode) => ipcRenderer.invoke('storage:get-product-by-barcode', scope, barcode),
  applyCatalogDelta: (scope, delta) => ipcRenderer.invoke('storage:apply-catalog-delta', scope, delta),
};

contextBridge.exposeInMainWorld('posApi', posApi);
