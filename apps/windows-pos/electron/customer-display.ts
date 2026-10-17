import { BrowserWindow, ipcMain, screen } from 'electron';
import type { BrowserWindowConstructorOptions, IpcMainEvent, WebContents } from 'electron';
import path from 'node:path';
import fs from 'node:fs';
import { idleCustomerDisplay, selectCustomerMonitor, validateCustomerDisplay } from './customer-display-types';
import type { CustomerDisplayState, CustomerDisplayStatus } from './customer-display-types';
import { isTrustedFrame } from './trusted-ipc';

export function readDisplayEnabled(filename: string): boolean {
  try {
    const config: unknown = JSON.parse(fs.readFileSync(filename, 'utf8'));
    if (!config || typeof config !== 'object' || typeof (config as { enabled?: unknown }).enabled !== 'boolean') throw new Error('Invalid customer display preference');
    return (config as { enabled: boolean }).enabled;
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === 'ENOENT') return true;
    console.error('Customer display disabled: unable to read preference.', error);
    return false;
  }
}

export function saveDisplayEnabled(filename: string, enabled: boolean): void {
  const temporary = `${filename}.tmp`;
  fs.writeFileSync(temporary, JSON.stringify({ enabled }), { mode: 0o600 });
  fs.renameSync(temporary, filename);
}

interface Options {
  url: string;
  enabled: boolean;
  saveEnabled: (enabled: boolean) => void;
  // Dependencies permit hardware-independent tests without displaying windows on the user's desktop.
  screen?: Pick<typeof screen, 'getAllDisplays' | 'on' | 'removeListener'>;
  createWindow?: (options: BrowserWindowConstructorOptions) => BrowserWindow;
}

export class CustomerDisplay {
  private window: BrowserWindow | null = null;
  private cashier: BrowserWindow | null = null;
  private cashierContents: WebContents | null = null;
  private monitorId?: number;
  private snapshot: CustomerDisplayState = idleCustomerDisplay();
  private enabled: boolean;
  private error = false;
  private readonly screens;
  private readonly makeWindow;

  constructor(private readonly options: Options) {
    this.enabled = options.enabled;
    this.screens = options.screen || screen;
    this.makeWindow = options.createWindow || ((options) => new BrowserWindow(options));
    this.screens.on('display-added', this.reconcile);
    this.screens.on('display-removed', this.reconcile);
    this.screens.on('display-metrics-changed', this.reconcile);
    ipcMain.on('customer-display:ready', this.onReady);
  }

  private onReady = (event: IpcMainEvent) => {
    if (isTrustedFrame(event, this.window, this.options.url)) this.send();
  };

  attach(cashier: BrowserWindow): void {
    this.detach();
    this.cashier = cashier;
    this.cashierContents = cashier.webContents;
    cashier.on('move', this.reconcile);
    cashier.on('resize', this.reconcile);
    cashier.on('closed', this.detach);
    cashier.webContents.on('did-start-loading', this.clear);
    cashier.webContents.on('render-process-gone', this.clear);
    this.reconcile();
  }

  private clear = () => { this.snapshot = idleCustomerDisplay(); this.send(); };

  private detach = () => {
    if (this.cashier) {
      this.cashier.removeListener('move', this.reconcile);
      this.cashier.removeListener('resize', this.reconcile);
      this.cashier.removeListener('closed', this.detach);
      if (this.cashierContents && !this.cashierContents.isDestroyed()) {
        this.cashierContents.removeListener('did-start-loading', this.clear);
        this.cashierContents.removeListener('render-process-gone', this.clear);
      }
    }
    this.cashier = null;
    this.cashierContents = null;
    this.clear();
    this.closeWindow();
  };

  private closeWindow(): void {
    const previous = this.window;
    this.window = null;
    this.monitorId = undefined;
    previous?.destroy();
  }

  private send(): void {
    if (this.window && !this.window.isDestroyed()) this.window.webContents.send('customer-display:state', this.snapshot);
  }

  publish(value: unknown): void { this.snapshot = validateCustomerDisplay(value); this.send(); }

  setEnabled(value: unknown): CustomerDisplayStatus {
    if (typeof value !== 'boolean') throw new Error('Invalid display preference');
    this.options.saveEnabled(value);
    this.enabled = value;
    this.error = false;
    this.reconcile();
    return this.status();
  }

  status(): CustomerDisplayStatus {
    if (!this.enabled) return { enabled: false, state: 'disabled', message: 'Customer display is paused.' };
    if (this.error) return { enabled: true, state: 'error', message: 'Customer display failed to load. Pause and enable it to retry.' };
    if (this.window && !this.window.isDestroyed() && this.window.isVisible()) return { enabled: true, state: 'active', message: 'Customer display is active.' };
    return { enabled: true, state: 'waiting', message: 'Waiting for a separate monitor. Use Extend mode and keep the cashier window on one screen.' };
  }

  private reconcile = () => {
    try { this.updateWindow(); }
    catch (error) {
      console.error('Unable to open customer display:', error);
      this.error = true;
      this.closeWindow();
    }
  };

  private updateWindow(): void {
    const cashier = this.cashier;
    const monitor = this.enabled && cashier && !cashier.isDestroyed()
      ? selectCustomerMonitor(this.screens.getAllDisplays(), cashier.getBounds(), this.monitorId) : undefined;
    if (!monitor) { this.closeWindow(); return; }
    if (this.error) return;
    if (this.window) { this.monitorId = monitor.id; this.window.setBounds(monitor.bounds); return; }
    const window = this.makeWindow({
      ...monitor.bounds, show: false, frame: false, focusable: false, skipTaskbar: true,
      resizable: false, movable: false, minimizable: false, maximizable: false,
      title: 'SmartShop — Customer Display', backgroundColor: '#0f172a',
      webPreferences: { preload: path.join(__dirname, 'customer-display-preload.js'),
        contextIsolation: true, nodeIntegration: false, sandbox: true, partition: 'customer-display', devTools: false },
    });
    this.window = window;
    this.monitorId = monitor.id;
    window.setMenu(null);
    window.webContents.setWindowOpenHandler(() => ({ action: 'deny' }));
    window.webContents.on('will-navigate', (event) => event.preventDefault());
    window.webContents.on('will-attach-webview', (event) => event.preventDefault());
    window.webContents.session.setPermissionRequestHandler((_contents, _permission, callback) => callback(false));
    window.webContents.session.setPermissionCheckHandler(() => false);
    window.on('closed', () => { if (this.window === window) { this.window = null; this.monitorId = undefined; } });
    const fail = () => {
      if (this.window !== window) return;
      this.error = true;
      this.closeWindow();
    };
    window.webContents.on('render-process-gone', fail);
    void window.loadURL(this.options.url).then(() => {
      if (this.window !== window) return;
      this.send();
      window.showInactive();
    }).catch(fail);
  }

  dispose(): void {
    this.detach();
    this.screens.removeListener('display-added', this.reconcile);
    this.screens.removeListener('display-removed', this.reconcile);
    this.screens.removeListener('display-metrics-changed', this.reconcile);
    ipcMain.removeListener('customer-display:ready', this.onReady);
  }
}
