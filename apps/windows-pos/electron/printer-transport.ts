import { createConnection } from 'node:net';
import { execFile } from 'node:child_process';
import type { PrinterProfile } from './printer-types';
import { WINDOWS_RAW_SCRIPT } from './windows-raw';

export class PrinterDeliveryError extends Error {
  constructor(message: string, public readonly uncertain = false) { super(message); }
}

const MAX_JOB_BYTES = 8 * 1024 * 1024;

export function sendTcp(host: string, port: number, data: Buffer, timeoutMs: number): Promise<void> {
  return new Promise((resolve, reject) => {
    let attempted = false;
    let settled = false;
    const socket = createConnection({ host, port });
    const complete = (error?: PrinterDeliveryError) => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      socket.destroy();
      if (error) reject(error); else resolve();
    };
    const timer = setTimeout(() => complete(new PrinterDeliveryError('The receipt printer timed out. Check its power and connection.', attempted)), timeoutMs);
    socket.on('error', () => complete(new PrinterDeliveryError('Could not send the job to the receipt printer. Check its power and connection.', attempted)));
    socket.on('close', () => { if (!settled) complete(new PrinterDeliveryError('The printer connection closed before the job completed.', attempted)); });
    socket.once('connect', () => {
      attempted = true;
      socket.setNoDelay(true);
      // Completion means the transport accepted the bytes, not that paper was physically printed.
      socket.end(data, () => complete());
    });
  });
}

export function sendWindows(printerName: string, data: Buffer, timeoutMs: number): Promise<void> {
  if (process.platform !== 'win32') return Promise.reject(new PrinterDeliveryError('Windows printer queues are supported only on Windows. Use a network printer on this platform.'));
  return new Promise((resolve, reject) => {
    const encoded = Buffer.from(WINDOWS_RAW_SCRIPT, 'utf16le').toString('base64');
    const child = execFile('powershell.exe', ['-NoProfile', '-NonInteractive', '-EncodedCommand', encoded],
      { timeout: timeoutMs, windowsHide: true, maxBuffer: 64 * 1024 }, (error, stdout) => {
        if (error) { reject(new PrinterDeliveryError('The Windows printer queue did not confirm this job. Check the queue before retrying.', true)); return; }
        try {
          const result: unknown = JSON.parse(stdout.trim());
          if (!result || typeof result !== 'object' || !('jobId' in result) || !Number.isInteger(result.jobId) || Number(result.jobId) <= 0) throw new Error('Missing job ID');
          resolve();
        } catch { reject(new PrinterDeliveryError('The Windows printer queue did not confirm this job. Check the queue before retrying.', true)); }
      });
    child.stdin?.on('error', () => { /* Process completion reports the failed delivery. */ });
    child.stdin?.end(JSON.stringify({ printerName, data: data.toString('base64') }));
  });
}

export async function sendPrinterJob(profile: PrinterProfile, data: Buffer): Promise<void> {
  if (!Buffer.isBuffer(data) || data.length === 0 || data.length > MAX_JOB_BYTES) throw new PrinterDeliveryError('The receipt job is empty or too large to send.');
  const target = profile.transport;
  if (target.type === 'tcp') await sendTcp(target.host, target.port, data, profile.timeoutMs);
  else await sendWindows(target.printerName, data, profile.timeoutMs);
}
