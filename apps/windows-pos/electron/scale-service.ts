import type { EventEmitter } from 'node:events';
import { quantityFromWeight } from './quantity';
import { parseWeight, ScaleFramer } from './scale-parser';
import type { ScaleProfile, ScaleStatus } from './scale-types';

export interface ScalePort extends EventEmitter {
  readonly isOpen: boolean;
  open: (callback: (error: Error | null) => void) => void;
  close: (callback: (error: Error | null) => void) => void;
}
const messages = {
  waiting: 'Waiting for scale data.', unstable: 'Weight is moving or held. Wait for a stable reading.',
  overload: 'Scale overload. Remove the load.', invalid: 'Invalid, zero, negative, unsupported-unit or wrong weight-type output.',
};

export class ScaleService {
  private port: ScalePort | null = null;
  private profile: ScaleProfile | null = null;
  private current: ScaleStatus = { state: 'disabled', message: 'Scale is disconnected. Configure scale.json, then connect.', reading: null };
  private revision = 0;
  private opening: Promise<ScaleStatus> | null = null;
  private closing: Promise<void> | null = null;
  private framer: ScaleFramer | null = null;
  private disposed = false;

  constructor(private readonly readProfile: () => ScaleProfile | null,
    private readonly createPort: (profile: ScaleProfile) => ScalePort,
    private readonly now: () => number = Date.now, private readonly openTimeoutMs = 3000) {}

  status(): ScaleStatus {
    if (this.current.reading && this.profile && this.now() - this.current.reading.receivedAt > this.profile.staleAfterMs) {
      return { state: 'stale', message: 'Scale reading expired. Wait for fresh data.', reading: null };
    }
    if (this.current.reading && this.framer?.hasPartialFrame) return { state: 'waiting', message: 'Receiving a new scale frame.', reading: null };
    return { ...this.current, reading: this.current.reading ? { ...this.current.reading } : null };
  }

  connect(): Promise<ScaleStatus> {
    if (this.disposed) return Promise.resolve(this.status());
    if (this.closing) return this.closing.then(() => this.connect());
    if (this.opening) return this.opening;
    if (this.disposed || this.port) return Promise.resolve(this.status());
    this.opening = this.open().finally(() => { this.opening = null; });
    return this.opening;
  }

  private async open(): Promise<ScaleStatus> {
    try {
      const profile = this.readProfile();
      if (!profile) { this.current = { state: 'disabled', message: 'Configure this terminal’s scale.json before weighing.', reading: null }; return this.status(); }
      this.profile = profile;
      const port = this.createPort(profile);
      this.port = port;
      this.current = { state: 'connecting', message: 'Connecting to scale…', reading: null };
      const invalid = () => { this.current = { state: 'invalid', message: messages.invalid, reading: null }; };
      const framer = new ScaleFramer((line) => {
        if (this.port !== port || this.disposed) return;
        const parsed = parseWeight(line, profile);
        if (parsed.state === 'stable') {
          const last = this.current.reading;
          // Identical streaming frames refresh freshness without invalidating a cashier's selected value.
          const revision = last?.value === parsed.value && last.unit === parsed.unit ? last.revision : ++this.revision;
          this.current = { state: 'stable', message: 'Stable weight. Check the scale and capture.',
            reading: { revision, value: parsed.value, unit: parsed.unit, receivedAt: this.now() } };
        } else this.current = { state: parsed.state, message: messages[parsed.state], reading: null };
      }, invalid);
      this.framer = framer;
      let faulted = false;
      port.on('data', (chunk: Buffer) => {
        if (this.port === port && this.framer === framer && !this.disposed && !faulted) framer.push(chunk);
      });
      port.on('error', (error: Error) => {
        faulted = true;
        if (this.port === port) this.current = { state: 'error', message: `Scale connection error: ${error.message}`, reading: null };
      });
      port.on('close', () => {
        if (this.port === port) {
          this.port = null; this.framer = null;
          this.current = { state: 'error', message: 'Scale disconnected. Reconnect the cable, then connect again.', reading: null };
        }
      });
      await new Promise<void>((resolve, reject) => {
        let settled = false;
        const timer = setTimeout(() => { settled = true; reject(new Error('Scale connection timed out. Check the port and reconnect.')); }, this.openTimeoutMs);
        const ready = (error: Error | null) => {
          if (settled) { if (port.isOpen) port.close(() => {}); return; }
          settled = true; clearTimeout(timer);
          if (error) reject(error); else resolve();
        };
        try { port.open(ready); }
        catch (error) { settled = true; clearTimeout(timer); reject(error); }
      });
      if (this.disposed || this.port !== port) {
        if (port.isOpen) await this.closePort(port);
        return this.status();
      }
      if (this.current.state === 'connecting') this.current = { state: 'waiting', message: messages.waiting, reading: null };
    } catch (error) {
      this.current = { state: 'error', message: error instanceof Error ? error.message : 'Unable to connect scale.', reading: null };
      if (!this.port?.isOpen) this.port = null;
    }
    return this.status();
  }

  capture(revision: unknown, unit: unknown): number {
    const state = this.status();
    if (this.disposed || !this.port?.isOpen || state.state !== 'stable' || !state.reading || state.reading.revision !== revision) {
      throw new Error('Scale weight changed, is unstable, or expired. Wait for a fresh stable reading.');
    }
    if (unit !== 'kg' && unit !== 'g') throw new Error('Only kg and g products can use the scale.');
    return quantityFromWeight(state.reading.value, state.reading.unit, unit);
  }

  private closePort(port: ScalePort): Promise<void> {
    return new Promise((resolve) => {
      let settled = false;
      const finish = (error: Error | null) => {
        if (settled) return;
        settled = true; clearTimeout(timer);
        if (error && !this.disposed) {
          // Retain an unclosed handle so a deliberate reconnect retries closing it first.
          if (!this.port && port.isOpen) this.port = port;
          this.current = { state: 'error', message: `Unable to close scale port: ${error.message}`, reading: null };
        }
        resolve();
      };
      const timer = setTimeout(() => finish(new Error('Close timed out. Check the adapter and reconnect.')), this.openTimeoutMs);
      try { port.close(finish); }
      catch (error) { finish(error instanceof Error ? error : new Error('Close failed.')); }
    });
  }

  disconnect(): Promise<void> {
    if (this.closing) return this.closing;
    // Invalidate immediately, including a capture racing with an outstanding open.
    const port = this.port;
    this.port = null; this.framer = null;
    this.current = { state: 'disabled', message: 'Scale disconnected.', reading: null };
    this.closing = (async () => {
      if (port?.isOpen) await this.closePort(port);
      await this.opening;
    })().finally(() => { this.closing = null; });
    return this.closing;
  }

  dispose(): void { this.disposed = true; void this.disconnect(); }
}
