export interface Product {
  id: number;
  uuid: string;
  name: string;
  sinhala_name?: string | null;
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
  warranty_period?: string | null;
  requires_serial?: boolean;
  has_variants: boolean;
}

export interface Category {
  id: number;
  uuid: string;
  name: string;
  slug: string;
}

export interface Customer {
  id: number;
  uuid: string;
  name: string;
  phone?: string | null;
  email?: string | null;
  address?: string | null;
  loyalty_points: number;
  credit_limit: number;
  balance: number;
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

export interface PosBridgeApi {
  printReceipt: (receiptData: any) => Promise<{ success: boolean; message?: string }>;
  openCashDrawer: () => Promise<{ success: boolean }>;
  getDeviceInfo: () => Promise<{ deviceUuid: string; platform: string; appVersion: string }>;
  onBarcodeScan: (callback: (barcode: string) => void) => () => void;
  saveOfflineSale: (sale: any) => Promise<{ success: boolean; id: string }>;
  getPendingOfflineSales: () => Promise<any[]>;
  getAllOfflineSales: () => Promise<any[]>;
  markSalesSynced: (uuids: string[]) => Promise<boolean>;
}

declare global {
  interface Window {
    posApi?: PosBridgeApi;
  }
}
