import Database from 'better-sqlite3';
import { isValidQuantity } from './quantity';
import fs from 'node:fs';
import { isDeepStrictEqual } from 'node:util';
import type {
  CatalogDelta, CatalogQuery, CatalogSnapshot, Category, Customer,
  OfflineSale, Product, StorageScope,
} from './storage-types';

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function assertUuid(value: unknown): asserts value is string {
  if (typeof value !== 'string' || !UUID.test(value)) throw new Error('Invalid UUID');
}

function scopeKey(scope: StorageScope): string {
  assertUuid(scope?.storeUuid);
  assertUuid(scope?.deviceUuid);
  return `${scope.storeUuid}:${scope.deviceUuid}`;
}

function assertSale(sale: OfflineSale): void {
  assertUuid(sale?.transaction_uuid);
  if (!Array.isArray(sale.items) || sale.items.length === 0 ||
      !Array.isArray(sale.payments) || sale.payments.length === 0) {
    throw new Error('A sale must include items and payments');
  }
  for (const item of sale.items) {
    if (item.product_uuid) assertUuid(item.product_uuid);
    if ((!item.product_uuid && (!Number.isSafeInteger(item.product_id) || item.product_id! <= 0)) ||
        !isValidQuantity(item.quantity) ||
        !Number.isFinite(item.unit_price) || item.unit_price < 0 ||
        (item.tax_rate !== undefined && (!Number.isFinite(item.tax_rate) || item.tax_rate < 0 || item.tax_rate > 100))) {
      throw new Error('Invalid sale item');
    }
  }
  for (const payment of sale.payments) {
    if (!['cash', 'card', 'bank_transfer', 'credit'].includes(payment.payment_method) ||
        !Number.isFinite(payment.amount) || payment.amount < 0) {
      throw new Error('Invalid sale payment');
    }
  }
  for (const value of [sale.subtotal, sale.discount_amount, sale.tax_amount, sale.total_amount,
    sale.paid_amount, sale.change_amount]) {
    if (value !== undefined && (!Number.isFinite(value) || value < 0)) {
      throw new Error('Invalid sale total');
    }
  }
}

function salePayload(sale: OfflineSale): Omit<OfflineSale, 'sync_status' | 'created_at' | 'local_id'> {
  const { sync_status: _status, created_at: _created, local_id: _id, ...payload } = sale;
  return payload;
}

interface SaleRow {
  payload: string;
  sync_status: 'pending' | 'synced';
  created_at: string;
}

/** Only the Electron main process owns this connection. All writes are synchronous commits. */
export class OfflineStore {
  private readonly db: Database.Database;

  constructor(filename: string, private readonly legacyFilename?: string) {
    this.db = new Database(filename);
    try {
      this.db.pragma('journal_mode = WAL');
      this.db.pragma('synchronous = FULL');
      this.db.pragma('foreign_keys = ON');
      this.db.pragma('busy_timeout = 5000');
      const schemaVersion = this.db.pragma('user_version', { simple: true }) as number;
      if (schemaVersion > 1) throw new Error('Local database was created by a newer POS version');
      if (schemaVersion === 0) {
        this.db.transaction(() => {
          this.db.exec(`
            CREATE TABLE metadata (key TEXT PRIMARY KEY, value TEXT NOT NULL);
            CREATE TABLE sales (
              transaction_uuid TEXT PRIMARY KEY,
              scope TEXT NOT NULL,
              payload TEXT NOT NULL CHECK(json_valid(payload)),
              sync_status TEXT NOT NULL CHECK(sync_status IN ('pending', 'synced')),
              created_at TEXT NOT NULL
            );
            CREATE INDEX sales_pending ON sales(scope, sync_status, created_at);
            CREATE TABLE sale_items (
              transaction_uuid TEXT NOT NULL REFERENCES sales(transaction_uuid),
              line_number INTEGER NOT NULL,
              payload TEXT NOT NULL CHECK(json_valid(payload)),
              PRIMARY KEY (transaction_uuid, line_number)
            );
            CREATE TABLE payments (
              transaction_uuid TEXT NOT NULL REFERENCES sales(transaction_uuid),
              line_number INTEGER NOT NULL,
              payload TEXT NOT NULL CHECK(json_valid(payload)),
              PRIMARY KEY (transaction_uuid, line_number)
            );
            CREATE TABLE catalog (
              scope TEXT NOT NULL,
              kind TEXT NOT NULL CHECK(kind IN ('product', 'category', 'customer')),
              uuid TEXT NOT NULL,
              barcode TEXT,
              sku TEXT,
              payload TEXT NOT NULL CHECK(json_valid(payload)),
              PRIMARY KEY (scope, kind, uuid)
            );
            CREATE INDEX catalog_barcode ON catalog(scope, kind, barcode);
            CREATE INDEX catalog_sku ON catalog(scope, kind, sku COLLATE NOCASE);
            PRAGMA user_version = 1;
          `);
        })();
      }
    } catch (error) {
      this.db.close();
      throw error;
    }
  }

  private prepareScope(scope: StorageScope): string {
    const key = scopeKey(scope);
    this.importLegacySales(scope);
    return key;
  }

  /** Import exactly once; never remove or rewrite the original JSON recovery file. */
  private importLegacySales(scope: StorageScope): void {
    if (!this.legacyFilename ||
        this.db.prepare('SELECT value FROM metadata WHERE key = ?').get('legacy_sales_imported')) return;
    if (!fs.existsSync(this.legacyFilename)) return;

    const legacy: unknown = JSON.parse(fs.readFileSync(this.legacyFilename, 'utf8'));
    if (!Array.isArray(legacy)) throw new Error('Legacy offline queue must be an array');
    this.db.transaction(() => {
      for (const sale of legacy as OfflineSale[]) {
        this.insertSale(scope, sale, sale.sync_status === 'synced' ? 'synced' : 'pending');
      }
      this.db.prepare('INSERT INTO metadata(key, value) VALUES (?, ?)')
        .run('legacy_sales_imported', new Date().toISOString());
    })();
  }

  private insertSale(scope: StorageScope, sale: OfflineSale, status: 'pending' | 'synced'): void {
    const key = scopeKey(scope);
    assertSale(sale);
    if ((sale.store_uuid && sale.store_uuid !== scope.storeUuid) ||
        (sale.device_uuid && sale.device_uuid !== scope.deviceUuid)) {
      throw new Error('Sale belongs to another store or device');
    }
    const payload = { ...salePayload(sale), store_uuid: scope.storeUuid, device_uuid: scope.deviceUuid };
    const existing = this.db.prepare('SELECT scope, payload FROM sales WHERE transaction_uuid = ?')
      .get(sale.transaction_uuid) as { scope: string; payload: string } | undefined;
    if (existing) {
      if (existing.scope !== key || !isDeepStrictEqual(JSON.parse(existing.payload), payload)) {
        throw new Error('Transaction UUID already exists with different sale data');
      }
      return; // A retry must never overwrite a sale or reset its acknowledged status.
    }
    this.db.prepare('INSERT INTO sales VALUES (?, ?, ?, ?, ?)')
      .run(sale.transaction_uuid, key, JSON.stringify(payload), status, sale.created_at ?? new Date().toISOString());
    const insertItem = this.db.prepare('INSERT INTO sale_items VALUES (?, ?, ?)');
    sale.items.forEach((item, i) => insertItem.run(sale.transaction_uuid, i, JSON.stringify(item)));
    const insertPayment = this.db.prepare('INSERT INTO payments VALUES (?, ?, ?)');
    sale.payments.forEach((payment, i) => insertPayment.run(sale.transaction_uuid, i, JSON.stringify(payment)));
  }

  saveSale(scope: StorageScope, sale: OfflineSale): { success: boolean; id: string } {
    this.prepareScope(scope);
    this.db.transaction(() => this.insertSale(scope, sale, 'pending'))();
    return { success: true, id: sale.transaction_uuid };
  }

  getSales(scope: StorageScope, pendingOnly = false): OfflineSale[] {
    const key = this.prepareScope(scope);
    const rows = this.db.prepare(`SELECT payload, sync_status, created_at FROM sales
      WHERE scope = ? ${pendingOnly ? "AND sync_status = 'pending'" : ''} ORDER BY created_at, rowid`).all(key) as SaleRow[];
    return rows.map((row) => ({
      ...JSON.parse(row.payload), sync_status: row.sync_status, created_at: row.created_at,
    }));
  }

  markSynced(scope: StorageScope, uuids: string[]): boolean {
    const key = this.prepareScope(scope);
    if (!Array.isArray(uuids)) throw new Error('Expected an array of UUIDs');
    uuids.forEach(assertUuid);
    this.db.transaction(() => {
      const update = this.db.prepare("UPDATE sales SET sync_status = 'synced' WHERE scope = ? AND transaction_uuid = ?");
      uuids.forEach((uuid) => update.run(key, uuid));
    })();
    return true;
  }

  applyDelta(scope: StorageScope, delta: CatalogDelta): void {
    const key = this.prepareScope(scope);
    if (!Number.isSafeInteger(delta?.current_version) || delta.current_version < 0 ||
        !Array.isArray(delta.products) || !Array.isArray(delta.categories) || !Array.isArray(delta.customers)) {
      throw new Error('Invalid catalog delta');
    }
    this.db.transaction(() => {
      const previous = this.getVersion(key);
      if (delta.current_version < previous) throw new Error('Catalog version cannot move backwards');
      const upsert = this.db.prepare(`INSERT INTO catalog(scope, kind, uuid, barcode, sku, payload)
        VALUES (?, ?, ?, ?, ?, ?) ON CONFLICT(scope, kind, uuid) DO UPDATE SET
        barcode = excluded.barcode, sku = excluded.sku, payload = excluded.payload`);
      const remove = this.db.prepare('DELETE FROM catalog WHERE scope = ? AND kind = ? AND uuid = ?');
      const groups = [
        ['product', delta.products], ['category', delta.categories], ['customer', delta.customers],
      ] as const;
      for (const [kind, records] of groups) {
        for (const record of records) {
          assertUuid(record?.uuid);
          if (record.deleted_at || ('is_active' in record && record.is_active === false)) {
            remove.run(key, kind, record.uuid);
          } else {
            if (!Number.isSafeInteger(record.id) || record.id <= 0 || typeof record.name !== 'string') {
              throw new Error('Invalid catalog record');
            }
            const product = kind === 'product' ? record as Product : null;
            upsert.run(key, kind, record.uuid, product?.barcode ?? null, product?.sku ?? null, JSON.stringify(record));
          }
        }
      }
      // The checkpoint is committed in the same transaction as every catalog record.
      this.db.prepare('INSERT INTO metadata(key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value')
        .run(`catalog_version:${key}`, String(delta.current_version));
    })();
  }

  private getVersion(key: string): number {
    const row = this.db.prepare('SELECT value FROM metadata WHERE key = ?').get(`catalog_version:${key}`) as
      { value: string } | undefined;
    return Number(row?.value ?? 0);
  }

  getCatalog(scope: StorageScope, query: CatalogQuery = {}): CatalogSnapshot {
    const key = this.prepareScope(scope);
    const read = <T>(kind: string): T[] => (this.db.prepare('SELECT payload FROM catalog WHERE scope = ? AND kind = ?')
      .all(key, kind) as { payload: string }[]).map((row) => JSON.parse(row.payload) as T);
    const term = (query.search ?? '').trim().toLocaleLowerCase();
    const limit = Math.min(1000, Math.max(1, Math.trunc(query.limit ?? 50)));
    // Filter and limit inside SQLite; large catalogs never cross IPC in full for a search.
    const products = (this.db.prepare(`SELECT payload FROM catalog WHERE scope = ? AND kind = 'product'
      AND (? IS NULL OR json_extract(payload, '$.category.uuid') = ?)
      AND (? = '' OR instr(lower(json_extract(payload, '$.name')), ?) > 0
        OR instr(lower(coalesce(json_extract(payload, '$.sinhala_name'), '')), ?) > 0
        OR instr(lower(coalesce(sku, '')), ?) > 0 OR instr(coalesce(barcode, ''), ?) > 0)
      ORDER BY json_extract(payload, '$.name') COLLATE NOCASE LIMIT ?`)
      .all(key, query.category_uuid ?? null, query.category_uuid ?? null, term, term, term, term, term, limit) as
      { payload: string }[]).map((row) => JSON.parse(row.payload) as Product);
    return {
      current_version: this.getVersion(key),
      products,
      categories: read<Category>('category').sort((a, b) =>
        (a.display_order ?? 0) - (b.display_order ?? 0) || a.name.localeCompare(b.name)),
      customers: read<Customer>('customer'),
    };
  }

  getProductByBarcode(scope: StorageScope, barcode: string): Product | null {
    const key = this.prepareScope(scope);
    if (typeof barcode !== 'string' || barcode.length > 256) throw new Error('Invalid barcode');
    const row = this.db.prepare(`SELECT payload FROM catalog WHERE scope = ? AND kind = 'product'
      AND (barcode = ? OR sku = ? COLLATE NOCASE) ORDER BY barcode = ? DESC LIMIT 1`)
      .get(key, barcode, barcode, barcode) as { payload: string } | undefined;
    return row ? JSON.parse(row.payload) as Product : null;
  }

  close(): void {
    if (this.db.open) this.db.close();
  }
}
