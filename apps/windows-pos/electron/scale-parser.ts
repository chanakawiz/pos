import type { ScaleProfile, ScaleStatus } from './scale-types';

export type ParsedWeight = { state: 'stable'; value: number; unit: 'kg' | 'g' } |
  { state: Extract<ScaleStatus['state'], 'unstable' | 'overload' | 'invalid'> };

/** Deliberately accepts only the configured A&D format, never a guessed number from a line. */
export function parseWeight(line: string, profile: ScaleProfile): ParsedWeight {
  const pattern = profile.protocol === 'and-balance'
    ? /^(ST|US|OL),([+-][ 0-9.]{1,12})[ ]{0,2}(kg|g)$/
    : /^(ST|US|OL|HD),(GS|NT|TR),([+-][ 0-9.]{1,12})[ ]{0,2}(kg|g)$/;
  const match = pattern.exec(line);
  if (!match) return { state: line.startsWith('OL,') ? 'overload' : 'invalid' };
  if (match[1] === 'OL') return { state: 'overload' };
  if (match[1] !== 'ST') return { state: 'unstable' };
  if (profile.protocol === 'and-indicator' && match[2] !== (profile.weightType === 'net' ? 'NT' : 'GS')) return { state: 'invalid' };
  const data = match[profile.protocol === 'and-balance' ? 2 : 3].trimEnd();
  if (!/^[+-] *\d+(?:\.\d+)?$/.test(data)) return { state: 'invalid' };
  const value = Number(data.replaceAll(' ', ''));
  if (!Number.isFinite(value) || value <= 0 || value > 1e9) return { state: 'invalid' };
  return { state: 'stable', value, unit: match[profile.protocol === 'and-balance' ? 3 : 4] as 'kg' | 'g' };
}

/** CRLF frames, bounded memory, resynchronization only after a complete delimiter. */
export class ScaleFramer {
  private buffer = '';
  private dropping = false;
  constructor(private readonly onLine: (line: string) => void, private readonly onInvalid: () => void) {}
  push(chunk: Buffer): void {
    for (const byte of chunk) {
      if (byte === 10) {
        if (!this.dropping && this.buffer.endsWith('\r')) this.onLine(this.buffer.slice(0, -1));
        else if (!this.dropping) this.onInvalid();
        this.buffer = ''; this.dropping = false;
      } else if (!this.dropping) {
        if ((byte !== 13 && (byte < 32 || byte > 126)) || this.buffer.length >= 96) {
          this.buffer = ''; this.dropping = true; this.onInvalid();
        } else this.buffer += String.fromCharCode(byte);
      }
    }
  }
  get hasPartialFrame(): boolean { return this.dropping || this.buffer.length > 0; }
}
