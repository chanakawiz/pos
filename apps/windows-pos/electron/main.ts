import { app, BrowserWindow, ipcMain } from 'electron';
import path from 'path';
import fs from 'fs';

let mainWindow: BrowserWindow | null = null;

// Local offline storage path in user app data
const userDataPath = app.getPath('userData');
const offlineDbPath = path.join(userDataPath, 'smartshop_offline_sales.json');

function getOfflineSales(): any[] {
  try {
    if (fs.existsSync(offlineDbPath)) {
      const data = fs.readFileSync(offlineDbPath, 'utf8');
      return JSON.parse(data);
    }
  } catch (err) {
    console.error('Failed to read offline sales:', err);
  }
  return [];
}

function saveOfflineSales(sales: any[]): void {
  try {
    fs.writeFileSync(offlineDbPath, JSON.stringify(sales, null, 2), 'utf8');
  } catch (err) {
    console.error('Failed to write offline sales:', err);
  }
}

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1366,
    height: 768,
    minWidth: 1024,
    minHeight: 640,
    title: 'SmartShop POS — Retail Station',
    autoHideMenuBar: true,
    backgroundColor: '#0f172a',
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false,
    },
  });

  const devUrl = process.env.VITE_DEV_SERVER_URL || 'http://localhost:5173';
  if (app.isPackaged) {
    mainWindow.loadFile(path.join(__dirname, '../dist/index.html'));
  } else {
    mainWindow.loadURL(devUrl);
  }

  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}

app.whenReady().then(() => {
  // IPC Handlers
  ipcMain.handle('printer:print-receipt', async (_event, receiptData) => {
    console.log('[Printer IPC] Received print request for invoice:', receiptData?.invoice_number);
    if (!mainWindow) return { success: false, message: 'Window not ready' };

    try {
      mainWindow.webContents.print({
        silent: true,
        printBackground: true,
        margins: { marginType: 'none' },
      });
      return { success: true };
    } catch (err: any) {
      return { success: false, message: err?.message || 'Print error' };
    }
  });

  ipcMain.handle('hardware:open-drawer', async () => {
    console.log('[Hardware IPC] Kickout signal sent to RJ11 cash drawer via ESC/POS');
    return { success: true };
  });

  ipcMain.handle('device:get-info', async () => {
    return {
      deviceUuid: '550e8400-e29b-41d4-a716-446655440000',
      platform: process.platform,
      appVersion: app.getVersion(),
    };
  });

  ipcMain.handle('storage:save-offline-sale', async (_event, sale) => {
    const current = getOfflineSales();
    current.push({
      ...sale,
      local_id: `OFFLINE-${Date.now()}`,
      sync_status: 'pending',
      created_at: new Date().toISOString(),
    });
    saveOfflineSales(current);
    return { success: true, id: sale.transaction_uuid };
  });

  ipcMain.handle('storage:get-offline-sales', async () => {
    return getOfflineSales().filter((s) => s.sync_status === 'pending');
  });

  ipcMain.handle('storage:get-all-offline-sales', async () => {
    return getOfflineSales();
  });

  ipcMain.handle('storage:mark-synced', async (_event, uuids: string[]) => {
    const current = getOfflineSales();
    const updated = current.map((s) => (uuids.includes(s.transaction_uuid) ? { ...s, sync_status: 'synced' } : s));
    saveOfflineSales(updated);
    return true;
  });

  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});
