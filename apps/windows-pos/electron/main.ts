import { app, BrowserWindow, dialog, ipcMain } from 'electron';
import path from 'path';
import { pathToFileURL } from 'node:url';
import { OfflineStore } from './offline-store';
import { PrinterService } from './printer-service';
import { readPrinterProfile } from './printer-config';
import { renderReceipt } from './receipt-renderer';

let mainWindow: BrowserWindow | null = null;

let offlineStore: OfflineStore | null = null;

// A single process owns the local queue, including its one-time legacy import.
if (!app.requestSingleInstanceLock()) app.quit();
app.on('second-instance', () => {
  if (mainWindow?.isMinimized()) mainWindow.restore();
  mainWindow?.focus();
});

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
  const userDataPath = app.getPath('userData');
  const storage = new OfflineStore(
    path.join(userDataPath, 'smartshop_pos.sqlite'),
    path.join(userDataPath, 'smartshop_offline_sales.json'),
  );
  offlineStore = storage;

  // Restrict storage and hardware access to the trusted cashier main frame.
  const trustedHandler = <Args extends unknown[]>(channel: string, handler: (...args: Args) => unknown) => {
    ipcMain.handle(channel, (event, ...args) => {
      if (!mainWindow || event.sender !== mainWindow.webContents ||
          event.senderFrame !== mainWindow.webContents.mainFrame) {
        throw new Error('Untrusted POS request');
      }
      const expectedUrl = app.isPackaged
        ? pathToFileURL(path.join(__dirname, '../dist/index.html')).href
        : (process.env.VITE_DEV_SERVER_URL || 'http://localhost:5173');
      if (new URL(event.senderFrame.url).origin !== new URL(expectedUrl).origin ||
          (app.isPackaged && event.senderFrame.url.split('#')[0] !== expectedUrl)) {
        throw new Error('Untrusted POS origin');
      }
      return handler(...args as Args);
    });
  };
  const printerFilename = path.join(userDataPath, 'printer.json');
  console.info('Receipt printer configuration:', printerFilename);
  const printer = new PrinterService(() => readPrinterProfile(printerFilename), renderReceipt);
  trustedHandler('printer:print-receipt', (request: unknown) => printer.printReceipt(request));
  trustedHandler('hardware:open-drawer', () => printer.openCashDrawer());

  ipcMain.handle('device:get-info', async () => {
    return {
      deviceUuid: '550e8400-e29b-41d4-a716-446655440000',
      platform: process.platform,
      appVersion: app.getVersion(),
    };
  });

  trustedHandler('storage:save-offline-sale', storage.saveSale.bind(storage));
  trustedHandler('storage:get-offline-sales', (scope: Parameters<OfflineStore['getSales']>[0]) => storage.getSales(scope, true));
  trustedHandler('storage:get-all-offline-sales', storage.getSales.bind(storage));
  trustedHandler('storage:mark-synced', storage.markSynced.bind(storage));
  trustedHandler('storage:get-catalog', storage.getCatalog.bind(storage));
  trustedHandler('storage:get-product-by-barcode', storage.getProductByBarcode.bind(storage));
  trustedHandler('storage:apply-catalog-delta', storage.applyDelta.bind(storage));

  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
}).catch((error: unknown) => {
  console.error('Unable to initialize POS storage:', error);
  dialog.showErrorBox('POS storage unavailable', 'The local database could not be opened. Restart the terminal or contact support.');
  app.quit();
});

app.on('will-quit', () => {
  offlineStore?.close();
  offlineStore = null;
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});
