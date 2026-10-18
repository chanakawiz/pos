import fs from 'node:fs';
import type { ScaleProfile } from './scale-types';

export function parseScaleProfile(value: unknown): ScaleProfile {
  if (!value || typeof value !== 'object' || Array.isArray(value)) throw new Error('Invalid scale profile.');
  const c = value as Record<string, unknown>;
  if (typeof c.path !== 'string' || !/^(COM[1-9]\d*|\/dev\/[A-Za-z0-9._/-]+)$/.test(c.path) || c.path.includes('..')) throw new Error('Configure an explicit COM or /dev serial port.');
  if (!['and-balance', 'and-indicator'].includes(String(c.protocol))) throw new Error('Select a supported scale protocol.');
  if (!['net', 'gross'].includes(String(c.weightType))) throw new Error('Select the intended net or gross weight output.');
  if (![300, 600, 1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200].includes(Number(c.baudRate)) || typeof c.baudRate !== 'number') throw new Error('Invalid scale baud rate.');
  if (![7, 8].includes(Number(c.dataBits)) || typeof c.dataBits !== 'number' || ![1, 2].includes(Number(c.stopBits)) || typeof c.stopBits !== 'number' || !['none', 'even', 'odd'].includes(String(c.parity))) throw new Error('Configure data bits, stop bits and parity explicitly.');
  const staleAfterMs = c.staleAfterMs ?? 1500;
  if (!Number.isInteger(staleAfterMs) || Number(staleAfterMs) < 500 || Number(staleAfterMs) > 5000) throw new Error('Scale freshness must be between 500 and 5000ms.');
  return { path: c.path, baudRate: c.baudRate, dataBits: c.dataBits as 7 | 8, stopBits: c.stopBits as 1 | 2,
    parity: c.parity as ScaleProfile['parity'], protocol: c.protocol as ScaleProfile['protocol'],
    weightType: c.weightType as ScaleProfile['weightType'], staleAfterMs: Number(staleAfterMs) };
}

export function readScaleProfile(filename: string): ScaleProfile | null {
  try { return parseScaleProfile(JSON.parse(fs.readFileSync(filename, 'utf8'))); }
  catch (error) {
    if ((error as NodeJS.ErrnoException).code === 'ENOENT') return null;
    throw error;
  }
}
