export type ReceiptLanguage = 'en' | 'si' | 'bilingual';

export interface ReceiptSale {
  invoice_number: string;
  sold_at: string;
  items: {
    product_name: string;
    sinhala_name?: string | null;
    quantity: number;
    total: number;
    serial_number?: string | null;
    warranty_notes?: string | null;
  }[];
  subtotal: number;
  tax_amount: number;
  discount_amount: number;
  total_amount: number;
  paid_amount: number;
  change_amount: number;
  paymentMethod?: string;
  receipt?: {
    store_name?: string;
    store_address?: string;
    store_phone?: string;
    cashier_name?: string;
    currency_symbol?: string;
    tax_number?: string;
    receipt_header?: string;
    receipt_footer?: string;
  };
}

export interface ShiftPrintReport {
  session_uuid: string;
  store_name: string;
  cashier_name: string;
  opened_at: string;
  closed_at?: string;
  report_generated_at?: string;
  opening_float: number;
  cash_sales: number;
  card_sales: number;
  gross_sales: number;
  discount_total: number;
  refund_total: number;
  transactions_count: number;
  expected_cash_in_drawer?: number;
  expected_cash?: number;
  actual_closing_cash?: number;
  discrepancy?: number;
  notes?: string | null;
}

export interface RefundPrintReceipt {
  refund_number: string;
  invoice_number: string;
  store_name: string;
  cashier_name: string;
  total_refunded: number;
  reason: string;
  refunded_at: string;
}

export type PrintRequest =
  | { kind: 'sale'; sale: ReceiptSale; language: ReceiptLanguage; storeNameSi?: string }
  | { kind: 'shift'; report: ShiftPrintReport; reportType: 'X' | 'Z' }
  | { kind: 'refund'; receipt: RefundPrintReceipt };

export interface HardwareResult {
  success: boolean;
  message: string;
  /** Some data may have reached the device. The caller must never automatically retry. */
  uncertain?: boolean;
  skipped?: boolean;
  bytes?: number;
}

export interface PrinterBridge {
  printReceipt: (request: PrintRequest) => Promise<HardwareResult>;
  openCashDrawer: () => Promise<HardwareResult>;
}

export interface PrinterProfile {
  transport: { type: 'tcp'; host: string; port: number } | { type: 'windows'; printerName: string };
  paperWidth: 58 | 80;
  printableDots: number;
  rasterMode: 'graphics' | 'legacy';
  cut: 'full' | 'partial' | 'none';
  drawerPin: 2 | 5;
  drawerEnabled: boolean;
  timeoutMs: number;
}
