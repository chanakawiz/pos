import { BrowserWindow } from 'electron';
import fs from 'node:fs';
import path from 'node:path';
import { PNG } from 'pngjs';
import { buildReceiptHtml } from './receipt-document';
import { encodeRaster, finishReceipt, initializePrinter } from './escpos';
import type { PrintRequest, PrinterProfile } from './printer-types';

const VIEWPORT_HEIGHT = 1024;
let font: string | undefined;

/** Render only a trusted, escaped receipt in a sandboxed, network-free, ephemeral window. */
export async function renderReceipt(request: PrintRequest, profile: PrinterProfile): Promise<Buffer> {
  font ??= fs.readFileSync(path.join(__dirname, 'assets/NotoSansSinhala.ttf')).toString('base64');
  const window = new BrowserWindow({ show: false, width: profile.printableDots, height: VIEWPORT_HEIGHT,
    useContentSize: true, backgroundColor: '#ffffff',
    webPreferences: { sandbox: true, contextIsolation: true, nodeIntegration: false, offscreen: true,
      backgroundThrottling: false, partition: 'receipt-renderer' } });
  window.webContents.setWindowOpenHandler(() => ({ action: 'deny' }));
  window.webContents.on('will-navigate', (event) => event.preventDefault());
  const timer = setTimeout(() => { if (!window.isDestroyed()) window.destroy(); }, 30000);
  try {
    const html = buildReceiptHtml(request, profile, font);
    await window.loadURL('about:blank');
    // Embedding the font exceeds Chromium's data-URL limit; keep the receipt in memory instead.
    await window.webContents.executeJavaScript(`document.open(); document.write(${JSON.stringify(html)}); document.close();`);
    window.webContents.setZoomFactor(1);
    const height: unknown = await window.webContents.executeJavaScript(`(async () => {
      await document.fonts.load('22px ReceiptSinhala', 'ස්මාර්ට්ෂොප් කිරි');
      await document.fonts.ready;
      const height = Math.ceil(document.getElementById('receipt').getBoundingClientRect().height);
      document.body.style.paddingBottom = '${VIEWPORT_HEIGHT}px';
      return height;
    })()`);
    if (typeof height !== 'number' || !Number.isInteger(height) || height < 1 || height > 50000) {
      throw new Error('Receipt exceeds the supported printable length');
    }
    const chunks: Buffer[] = [initializePrinter()];
    for (let y = 0; y < height; y += VIEWPORT_HEIGHT) {
      const rows = Math.min(VIEWPORT_HEIGHT, height - y);
      await window.webContents.executeJavaScript(`new Promise(resolve => {
        window.scrollTo(0, ${y});
        requestAnimationFrame(() => requestAnimationFrame(resolve));
      })`);
      const image = await window.webContents.capturePage({ x: 0, y: 0, width: profile.printableDots, height: rows },
        { stayHidden: true, stayAwake: true });
      // PNG normalizes pixel order across OSes and display scale factors.
      const pixels = PNG.sync.read(image.resize({ width: profile.printableDots, height: rows }).toPNG({ scaleFactor: 1 }));
      if (pixels.width !== profile.printableDots || pixels.height !== rows) throw new Error('Unexpected receipt capture dimensions');
      chunks.push(encodeRaster(pixels, profile.rasterMode));
    }
    chunks.push(finishReceipt(profile.cut));
    return Buffer.concat(chunks);
  } finally {
    clearTimeout(timer);
    if (!window.isDestroyed()) window.destroy();
  }
}
