export interface ScaleProfile {
  path: string;
  baudRate: number;
  dataBits: 7 | 8;
  stopBits: 1 | 2;
  parity: 'none' | 'even' | 'odd';
  protocol: 'and-balance' | 'and-indicator';
  weightType: 'net' | 'gross';
  staleAfterMs: number;
}

export interface ScaleReading {
  revision: number;
  value: number;
  unit: 'kg' | 'g';
  receivedAt: number;
}

export interface ScaleStatus {
  state: 'disabled' | 'connecting' | 'waiting' | 'stable' | 'unstable' | 'overload' | 'invalid' | 'stale' | 'error';
  message: string;
  reading: ScaleReading | null;
}

export interface ScaleBridge {
  connectScale: () => Promise<ScaleStatus>;
  getScaleStatus: () => Promise<ScaleStatus>;
  disconnectScale: () => Promise<void>;
  captureScaleWeight: (revision: number, productUnit: 'kg' | 'g') => Promise<number>;
}
