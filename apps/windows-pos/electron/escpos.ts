import type { PrinterProfile } from './printer-types';

export function drawerPulse(pin: 2 | 5): Buffer {
  if (pin !== 2 && pin !== 5) throw new Error('Invalid drawer pin');
  return Buffer.from([0x1b, 0x70, pin === 2 ? 0 : 1, 25, 250]);
}

export const initializePrinter = (): Buffer => Buffer.from([0x1b, 0x40, 0x1b, 0x61, 0]);

export function finishReceipt(cut: PrinterProfile['cut']): Buffer {
  const feed = Buffer.from([0x1b, 0x64, 3]);
  return cut === 'none' ? feed : Buffer.concat([feed, Buffer.from([0x1d, 0x56, cut === 'full' ? 0 : 1])]);
}

/** Convert RGBA pixels to 1-bit, MSB-first printer rows; alpha is flattened onto white paper. */
export function encodeRaster(image: { width: number; height: number; data: Uint8Array }, mode: PrinterProfile['rasterMode']): Buffer {
  const { width, height, data } = image;
  if (!Number.isInteger(width) || width < 1 || width > 832 || !Number.isInteger(height) || height < 1 || height > 2048 ||
      data.length !== width * height * 4) throw new Error('Invalid receipt raster');
  const rowBytes = Math.ceil(width / 8);
  const chunks: Buffer[] = [];
  // Small bands fit the print-buffer limits of both older and newer ESC/POS models.
  for (let start = 0; start < height; start += 128) {
    const rows = Math.min(128, height - start);
    const pixels = Buffer.alloc(rowBytes * rows);
    for (let y = 0; y < rows; y++) {
      for (let x = 0; x < width; x++) {
        const offset = ((start + y) * width + x) * 4;
        const alpha = data[offset + 3] / 255;
        const luminance = (data[offset] * 299 + data[offset + 1] * 587 + data[offset + 2] * 114) / 1000;
        if (luminance * alpha + 255 * (1 - alpha) < 160) pixels[y * rowBytes + (x >> 3)] |= 0x80 >> (x % 8);
      }
    }
    if (mode === 'legacy') {
      chunks.push(Buffer.from([0x1d, 0x76, 0x30, 0, rowBytes & 255, rowBytes >> 8, rows & 255, rows >> 8]), pixels);
    } else {
      const length = pixels.length + 10;
      chunks.push(Buffer.from([0x1d, 0x28, 0x4c, length & 255, length >> 8, 48, 112, 48, 1, 1, 49,
        width & 255, width >> 8, rows & 255, rows >> 8]), pixels,
      Buffer.from([0x1d, 0x28, 0x4c, 2, 0, 48, 50]));
    }
  }
  return Buffer.concat(chunks);
}
