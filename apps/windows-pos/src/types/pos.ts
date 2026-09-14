export interface Product {
  id: number;
  uuid: string;
  name: string;
  sku: string;
  barcode: string | null;
  unit: string;
  cost_price: number;
  selling_price: number;
  tax_rate: number;
  min_stock_level: number;
  stock_quantity: number;
  category?: {
    uuid: string;
    name: string;
  } | null;
  has_variants: boolean;
}

export interface Category {
  id: number;
  uuid: string;
  name: string;
  slug: string;
}

export interface CartItem {
  product: Product;
  quantity: number;
  unitPrice: number;
  discountAmount: number;
  taxRate: number;
  taxAmount: number;
  subtotal: number;
  total: number;
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

export interface PosBridgeApi {
  printReceipt: (receiptData: any) => Promise<{ success: boolean; message?: string }>;
  openCashDrawer: () => Promise<{ success: boolean }>;
  getDeviceInfo: () => Promise<{ deviceUuid: string; platform: string; appVersion: string }>;
  onBarcodeScan: (callback: (barcode: string) => void) => () => void;
  saveOfflineSale: (sale: any) => Promise<{ success: boolean; id: string }>;
  getPendingOfflineSales: () => Promise<any[]>;
  markSalesSynced: (uuids: string[]) => Promise<boolean>;
}

declare global {
  interface Window {
    posApi?: PosBridgeApi;
  }
}
