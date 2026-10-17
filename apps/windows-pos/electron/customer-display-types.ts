/** Public, deliberately small projection. Never send customers, payments, credentials, or full products. */
export interface CustomerDisplayState {
  storeName: string;
  currencySymbol: string;
  language: 'en' | 'si' | 'bilingual';
  items: { name: string; sinhalaName: string; quantity: number; unitPrice: number; total: number }[];
  subtotal: number;
  tax: number;
  billDiscount: number;
  total: number;
}

export interface CustomerDisplayStatus {
  enabled: boolean;
  state: 'active' | 'waiting' | 'disabled' | 'error';
  message: string;
}

export interface CustomerDisplayBridge {
  publishCustomerDisplay: (state: CustomerDisplayState) => Promise<void>;
  getCustomerDisplayStatus: () => Promise<CustomerDisplayStatus>;
  setCustomerDisplayEnabled: (enabled: boolean) => Promise<CustomerDisplayStatus>;
}

export const idleCustomerDisplay = (): CustomerDisplayState => ({
  storeName: 'SmartShop POS', currencySymbol: '', language: 'bilingual',
  items: [], subtotal: 0, tax: 0, billDiscount: 0, total: 0,
});

/** Validate the IPC boundary and rebuild each field to discard private/unknown properties. */
export function validateCustomerDisplay(value: unknown): CustomerDisplayState {
  const record = (input: unknown): Record<string, unknown> => {
    if (!input || typeof input !== 'object' || Array.isArray(input)) throw new Error('Invalid display state');
    return input as Record<string, unknown>;
  };
  const text = (input: unknown, max: number): string => {
    if (typeof input !== 'string' || input.length > max) throw new Error('Invalid display text');
    return input;
  };
  const number = (input: unknown): number => {
    if (typeof input !== 'number' || !Number.isFinite(input) || input < 0 || input > 1e12) throw new Error('Invalid display amount');
    return input;
  };
  const state = record(value);
  if (!['en', 'si', 'bilingual'].includes(String(state.language))) throw new Error('Invalid display language');
  if (!Array.isArray(state.items) || state.items.length > 5000) throw new Error('Invalid display items');
  return {
    storeName: text(state.storeName, 300), currencySymbol: text(state.currencySymbol, 20),
    language: state.language as CustomerDisplayState['language'],
    items: state.items.map((value) => {
      const item = record(value);
      return { name: text(item.name, 1000), sinhalaName: text(item.sinhalaName, 1000),
        quantity: number(item.quantity), unitPrice: number(item.unitPrice), total: number(item.total) };
    }),
    subtotal: number(state.subtotal), tax: number(state.tax), billDiscount: number(state.billDiscount), total: number(state.total),
  };
}

export interface DisplayRectangle { x: number; y: number; width: number; height: number }
export interface CustomerMonitor { id: number; bounds: DisplayRectangle }

/** Only use a monitor with no cashier-window overlap; also excludes mirrored desktops. */
export function selectCustomerMonitor(displays: CustomerMonitor[], cashier: DisplayRectangle, currentId?: number): CustomerMonitor | undefined {
  const candidates = displays.filter(({ bounds: b }) => b.width > 0 && b.height > 0 &&
    !(b.x < cashier.x + cashier.width && b.x + b.width > cashier.x && b.y < cashier.y + cashier.height && b.y + b.height > cashier.y));
  return candidates.find((display) => display.id === currentId) || candidates.sort((a, b) => a.id - b.id)[0];
}
