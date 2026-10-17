import fs from 'node:fs';
import type { PrinterProfile } from './printer-types';

export class PrinterConfigurationError extends Error {}
const containsControl = (value: string): boolean => [...value].some((character) =>
  character.charCodeAt(0) < 32 || character.charCodeAt(0) === 127);

export function parsePrinterProfile(input: unknown): PrinterProfile {
  if (!input || typeof input !== 'object' || Array.isArray(input)) {
    throw new PrinterConfigurationError('Configure this terminal’s receipt printer before printing or opening the drawer.');
  }
  const p = input as Record<string, unknown>;
  const fail = (): never => { throw new PrinterConfigurationError('The receipt printer configuration is invalid. Check printer.json.'); };
  const paperWidth = p.paperWidth ?? 80;
  if (paperWidth !== 58 && paperWidth !== 80) return fail();
  const printableDots = p.printableDots ?? (paperWidth === 58 ? 384 : 576);
  if (!Number.isInteger(printableDots) || Number(printableDots) < 256 || Number(printableDots) > 832 || Number(printableDots) % 8 !== 0) return fail();
  const rasterMode = p.rasterMode ?? 'graphics';
  const cut = p.cut ?? 'partial';
  const drawerPin = p.drawerPin ?? 2;
  const drawerEnabled = p.drawerEnabled ?? true;
  const timeoutMs = p.timeoutMs ?? 15000;
  if (!['graphics', 'legacy'].includes(String(rasterMode)) || !['full', 'partial', 'none'].includes(String(cut)) ||
      (drawerPin !== 2 && drawerPin !== 5) || typeof drawerEnabled !== 'boolean' ||
      !Number.isInteger(timeoutMs) || Number(timeoutMs) < 100 || Number(timeoutMs) > 60000) return fail();
  let transport: PrinterProfile['transport'];
  if (p.type === 'tcp') {
    if (typeof p.host !== 'string' || !p.host || p.host.length > 253 || /[\s/\\]/u.test(p.host) || containsControl(p.host)) return fail();
    const port = p.port ?? 9100;
    if (!Number.isInteger(port) || Number(port) < 1 || Number(port) > 65535) return fail();
    transport = { type: 'tcp', host: p.host, port: Number(port) };
  } else if (p.type === 'windows') {
    if (typeof p.printerName !== 'string' || !p.printerName.trim() || p.printerName.length > 256 || containsControl(p.printerName)) return fail();
    transport = { type: 'windows', printerName: p.printerName };
  } else return fail();
  return { transport, paperWidth, printableDots: Number(printableDots), rasterMode: rasterMode as PrinterProfile['rasterMode'],
    cut: cut as PrinterProfile['cut'], drawerPin, drawerEnabled, timeoutMs: Number(timeoutMs) };
}

/** Configuration is owned by the main process, never supplied over the renderer bridge. */
export function readPrinterProfile(filename: string): PrinterProfile {
  if (!fs.existsSync(filename)) return parsePrinterProfile(null);
  try { return parsePrinterProfile(JSON.parse(fs.readFileSync(filename, 'utf8'))); }
  catch (error) {
    if (error instanceof PrinterConfigurationError) throw error;
    throw new PrinterConfigurationError('The receipt printer configuration could not be read. Check printer.json.');
  }
}
