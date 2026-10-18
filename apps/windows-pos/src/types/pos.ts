import type { PrinterBridge } from '../../electron/printer-types';
import type { Product } from '../../electron/storage-types';
import type { StorageBridge } from '../../electron/storage-types';
import type { CustomerDisplayBridge } from '../../electron/customer-display-types';
import type { ScaleBridge } from '../../electron/scale-types';
export type { Product, Category, Customer } from '../../electron/storage-types';

export interface CartItem {
  product: Product;
  quantity: number;
  unitPrice: number;
  discountAmount: number;
  taxRate: number;
  taxAmount: number;
  subtotal: number;
  total: number;
  serial_number?: string | null;
  warranty_notes?: string | null;
}

export type PaymentType = 'cash' | 'card' | 'bank_transfer' | 'credit';

export interface PaymentItem {
  payment_method: PaymentType;
  amount: number;
  reference_number?: string;
}

export interface User {
  uuid: string;
  name: string;
  email: string;
  role: 'super_admin' | 'admin' | 'manager' | 'cashier';
  store?: {
    uuid: string;
    code: string;
    name: string;
    currency_code: string;
    currency_symbol: string;
    tax_number?: string;
    receipt_header?: string;
    receipt_footer?: string;
  } | null;
}

export interface SaleReceipt {
  store_name: string;
  store_phone?: string;
  store_address?: string;
  tax_number?: string;
  currency_symbol: string;
  invoice_number: string;
  cashier_name: string;
  sold_at: string;
  receipt_header?: string;
  receipt_footer?: string;
}

export interface RefundReceipt {
  refund_number: string;
  invoice_number: string;
  store_name: string;
  cashier_name: string;
  total_refunded: number;
  reason: string;
  refunded_at: string;
}

export interface PosBridgeApi extends StorageBridge, PrinterBridge, CustomerDisplayBridge, ScaleBridge {
  getDeviceInfo: () => Promise<{ deviceUuid: string; platform: string; appVersion: string }>;
  onBarcodeScan: (callback: (barcode: string) => void) => () => void;

}

declare global {
  interface Window {
    posApi?: PosBridgeApi;
  }
}
