import { contextBridge, ipcRenderer } from 'electron';

export interface PosBridgeApi {
  printReceipt: (receiptData: any) => Promise<{ success: boolean; message?: string }>;
  openCashDrawer: () => Promise<{ success: boolean }>;
  getDeviceInfo: () => Promise<{ deviceUuid: string; platform: string; appVersion: string }>;
  onBarcodeScan: (callback: (barcode: string) => void) => () => void;
  saveOfflineSale: (sale: any) => Promise<{ success: boolean; id: string }>;
  getPendingOfflineSales: () => Promise<any[]>;
  getAllOfflineSales: () => Promise<any[]>;
  markSalesSynced: (uuids: string[]) => Promise<boolean>;
}

const posApi: PosBridgeApi = {
  printReceipt: (receiptData: any) => ipcRenderer.invoke('printer:print-receipt', receiptData),
  openCashDrawer: () => ipcRenderer.invoke('hardware:open-drawer'),
  getDeviceInfo: () => ipcRenderer.invoke('device:get-info'),
  onBarcodeScan: (callback: (barcode: string) => void) => {
    const handler = (_event: any, barcode: string) => callback(barcode);
    ipcRenderer.on('scanner:barcode', handler);
    return () => ipcRenderer.removeListener('scanner:barcode', handler);
  },
  saveOfflineSale: (sale: any) => ipcRenderer.invoke('storage:save-offline-sale', sale),
  getPendingOfflineSales: () => ipcRenderer.invoke('storage:get-offline-sales'),
  getAllOfflineSales: () => ipcRenderer.invoke('storage:get-all-offline-sales'),
  markSalesSynced: (uuids: string[]) => ipcRenderer.invoke('storage:mark-synced', uuids),
};

contextBridge.exposeInMainWorld('posApi', posApi);
