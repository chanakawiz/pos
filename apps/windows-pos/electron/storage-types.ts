export interface StorageScope {
  storeUuid: string;
  deviceUuid: string;
}

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
  category?: { uuid: string; name: string } | null;
  warranty_period?: string | null;
  requires_serial?: boolean;
  has_variants: boolean;
  is_active?: boolean;
  deleted_at?: string | null;
  version?: number;
}

export interface Category {
  id: number;
  uuid: string;
  name: string;
  slug: string;
  display_order?: number;
  is_active?: boolean;
  deleted_at?: string | null;
  version?: number;
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
  deleted_at?: string | null;
  version?: number;
}

export interface OfflineSaleItem {
  product_uuid?: string;
  product_id?: number;
  product_name?: string;
  sinhala_name?: string | null;
  quantity: number;
  unit_price: number;
  discount_amount?: number;
  tax_amount?: number;
  tax_rate?: number;
  subtotal?: number;
  total?: number;
  serial_number?: string | null;
  warranty_notes?: string | null;
}

export interface OfflineSale {
  transaction_uuid: string;
  invoice_number?: string;
  cashier_uuid?: string;
  customer_uuid?: string;
  store_uuid?: string;
  device_uuid?: string;
  subtotal?: number;
  discount_amount?: number;
  tax_amount?: number;
  total_amount?: number;
  paid_amount?: number;
  change_amount?: number;
  sold_at?: string;
  items: OfflineSaleItem[];
  payments: {
    payment_method: 'cash' | 'card' | 'bank_transfer' | 'credit';
    amount: number;
    reference_number?: string | null;
  }[];
  sync_status?: 'pending' | 'synced';
  created_at?: string;
  local_id?: string;
}

export interface CatalogDelta {
  current_version: number;
  products: Product[];
  categories: Category[];
  customers: Customer[];
}

export interface CatalogQuery {
  search?: string;
  category_uuid?: string;
  limit?: number;
}

export type CatalogSnapshot = CatalogDelta;

export interface StorageBridge {
  saveOfflineSale: (scope: StorageScope, sale: OfflineSale) => Promise<{ success: boolean; id: string }>;
  getPendingOfflineSales: (scope: StorageScope) => Promise<OfflineSale[]>;
  getAllOfflineSales: (scope: StorageScope) => Promise<OfflineSale[]>;
  markSalesSynced: (scope: StorageScope, uuids: string[]) => Promise<boolean>;
  getCatalog: (scope: StorageScope, query?: CatalogQuery) => Promise<CatalogSnapshot>;
  getCachedProductByBarcode: (scope: StorageScope, barcode: string) => Promise<Product | null>;
  applyCatalogDelta: (scope: StorageScope, delta: CatalogDelta) => Promise<void>;
}
