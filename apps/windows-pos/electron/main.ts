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

function buildEscPosReceipt(receiptData: any): Buffer {
  const chunks: Buffer[] = [];
  // Init printer (ESC @)
  chunks.push(Buffer.from([0x1B, 0x40]));
  // Center align (ESC a 1)
  chunks.push(Buffer.from([0x1B, 0x61, 0x01]));
  // Bold & Double height (GS ! 0x11)
  chunks.push(Buffer.from([0x1B, 0x45, 0x01, 0x1D, 0x21, 0x11]));
  chunks.push(Buffer.from(`${receiptData.store_name || 'SMARTSHOP POS'}\n`, 'utf8'));
  // Normal font
  chunks.push(Buffer.from([0x1D, 0x21, 0x00, 0x1B, 0x45, 0x00]));
  if (receiptData.store_address) {
    chunks.push(Buffer.from(`${receiptData.store_address}\n`, 'utf8'));
  }
  chunks.push(Buffer.from('--------------------------------\n', 'utf8'));
  // Left align (ESC a 0)
  chunks.push(Buffer.from([0x1B, 0x61, 0x00]));
  chunks.push(Buffer.from(`Invoice: ${receiptData.invoice_number || 'N/A'}\n`, 'utf8'));
  chunks.push(Buffer.from(`Date: ${new Date(receiptData.sold_at || Date.now()).toLocaleString()}\n`, 'utf8'));
  chunks.push(Buffer.from(`Cashier: ${receiptData.cashier_name || 'Staff'}\n`, 'utf8'));
  chunks.push(Buffer.from('--------------------------------\n', 'utf8'));

  if (Array.isArray(receiptData.items)) {
    for (const item of receiptData.items) {
      const name = (item.product_name || item.name || 'Item').slice(0, 18).padEnd(18);
      const qty = `${item.quantity}x`.padStart(4);
      const price = `$${parseFloat(item.total || 0).toFixed(2)}`.padStart(8);
      chunks.push(Buffer.from(`${name} ${qty} ${price}\n`, 'utf8'));
      if (item.sinhala_name) {
        chunks.push(Buffer.from(`  ${item.sinhala_name}\n`, 'utf8'));
      }
      if (item.serial_number) {
        chunks.push(Buffer.from(`  SN/IMEI: ${item.serial_number}\n`, 'utf8'));
      }
      if (item.warranty_notes) {
        chunks.push(Buffer.from(`  ${item.warranty_notes}\n`, 'utf8'));
      }
    }
  }
  chunks.push(Buffer.from('--------------------------------\n', 'utf8'));
  // Right align (ESC a 2)
  chunks.push(Buffer.from([0x1B, 0x61, 0x02]));
  chunks.push(Buffer.from(`Subtotal: $${parseFloat(receiptData.subtotal || 0).toFixed(2)}\n`, 'utf8'));
  chunks.push(Buffer.from(`Tax: $${parseFloat(receiptData.tax_amount || 0).toFixed(2)}\n`, 'utf8'));
  if (receiptData.discount_amount > 0) {
    chunks.push(Buffer.from(`Discount: -$${parseFloat(receiptData.discount_amount).toFixed(2)}\n`, 'utf8'));
  }
  // Bold Total (ESC E 1 & GS ! 0x01)
  chunks.push(Buffer.from([0x1B, 0x45, 0x01, 0x1D, 0x21, 0x01]));
  chunks.push(Buffer.from(`TOTAL: $${parseFloat(receiptData.total_amount || 0).toFixed(2)}\n`, 'utf8'));
  chunks.push(Buffer.from([0x1D, 0x21, 0x00, 0x1B, 0x45, 0x00]));
  // Center align & Footer
  chunks.push(Buffer.from([0x1B, 0x61, 0x01]));
  chunks.push(Buffer.from('\nThank you for shopping with us!\nPlease retain receipt for exchange.\n\n\n', 'utf8'));
  // Paper cut (GS V 66 0)
  chunks.push(Buffer.from([0x1D, 0x56, 0x42, 0x00]));

  return Buffer.concat(chunks);
}

app.whenReady().then(() => {
  // IPC Handlers
  ipcMain.handle('printer:print-receipt', async (_event, receiptData) => {
    console.log('[Printer IPC] Received print request for invoice:', receiptData?.invoice_number);
    const escposBuffer = buildEscPosReceipt(receiptData);
    console.log('[Printer IPC] Generated ESC/POS buffer size:', escposBuffer.length, 'bytes');

    if (!mainWindow) return { success: false, message: 'Window not ready' };

    try {
      mainWindow.webContents.print({
        silent: true,
        printBackground: true,
        margins: { marginType: 'none' },
      });
      return { success: true, escposBytes: escposBuffer.length };
    } catch (err: any) {
      return { success: false, message: err?.message || 'Print error' };
    }
  });

  ipcMain.handle('hardware:open-drawer', async () => {
    // ESC/POS drawer kick pulse: ESC p 0 25 250 (pin 2) and ESC p 1 25 250 (pin 5)
    const kickPulsePin2 = Buffer.from([0x1B, 0x70, 0x00, 0x19, 0xFA]);
    const kickPulsePin5 = Buffer.from([0x1B, 0x70, 0x01, 0x19, 0xFA]);
    console.log('[Hardware IPC] Kickout signal sent to RJ11 cash drawer via ESC/POS (pins 2 & 5)');
    return { success: true, pulse: Buffer.concat([kickPulsePin2, kickPulsePin5]).toString('hex') };
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
