import test, { type TestContext } from 'node:test';
import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import Database from 'better-sqlite3';
import { OfflineStore } from '../offline-store';
import { synchronizeOfflineData, type SyncTransport } from '../sync-engine';
import type { CatalogDelta, OfflineSale, Product, StorageBridge, StorageScope } from '../storage-types';

function fixture(t: TestContext) {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'smartshop-pos-'));
  const filename = path.join(directory, 'pos.sqlite');
  const legacy = path.join(directory, 'smartshop_offline_sales.json');
  const connections: OfflineStore[] = [];
  const open = () => {
    const store = new OfflineStore(filename, legacy);
    connections.push(store);
    return store;
  };
  t.after(() => {
    for (const connection of connections) connection.close();
    fs.rmSync(directory, { recursive: true, force: true });
  });
  return { open, filename, legacy, scope: { storeUuid: randomUUID(), deviceUuid: randomUUID() } };
}

function sale(): OfflineSale {
  return {
    transaction_uuid: randomUUID(), cashier_uuid: randomUUID(), invoice_number: `POS-${randomUUID()}`,
    total_amount: 23.10, sold_at: new Date().toISOString(),
    items: [{ product_uuid: randomUUID(), product_id: 1, quantity: 2, unit_price: 11, serial_number: 'IMEI-123', warranty_notes: '12 months' }],
    payments: [{ payment_method: 'cash', amount: 25 }],
  };
}

function product(): Product {
  return {
    id: 1, uuid: randomUUID(), name: 'Milk', sinhala_name: 'කිරි', sku: 'MILK-001', barcode: '1234567890', unit: 'pcs',
    cost_price: 8, selling_price: 11, tax_rate: 5, min_stock_level: 2, stock_quantity: 20, has_variants: false,
    category: { uuid: randomUUID(), name: 'Dairy' }, requires_serial: true, warranty_period: '12 months',
  };
}

function delta(products: Product[] = [product()], version = 1): CatalogDelta {
  return { current_version: version, products, categories: [], customers: [] };
}

function bridge(store: OfflineStore): StorageBridge {
  return {
    saveOfflineSale: async (scope, data) => store.saveSale(scope, data),
    getPendingOfflineSales: async (scope) => store.getSales(scope, true),
    getAllOfflineSales: async (scope) => store.getSales(scope),
    markSalesSynced: async (scope, ids) => store.markSynced(scope, ids),
    getCatalog: async (scope, query) => store.getCatalog(scope, query),
    getCachedProductByBarcode: async (scope, code) => store.getProductByBarcode(scope, code),
    applyCatalogDelta: async (scope, data) => store.applyDelta(scope, data),
  };
}

const transport = (overrides: Partial<SyncTransport> = {}): SyncTransport => ({
  push: async ({ transactions }) => ({ synced_uuids: transactions.map((s) => s.transaction_uuid) }),
  pull: async () => delta(),
  ...overrides,
});

test('durably stores complete sales and recovers pending status from a new connection', (t) => {
  const { open, scope, filename } = fixture(t);
  const store = open();
  const data = sale();
  assert.equal(store.saveSale(scope, data).id, data.transaction_uuid);
  store.close();
  const reader = open();
  const saved = reader.getSales(scope, true)[0];
  assert.deepEqual(saved.items, data.items);
  assert.deepEqual(saved.payments, data.payments);
  assert.equal(saved.store_uuid, scope.storeUuid);
  assert.equal(saved.device_uuid, scope.deviceUuid);
  const db = new Database(filename);
  assert.equal(db.pragma('journal_mode', { simple: true }), 'wal');
  assert.equal((db.prepare('SELECT count(*) AS count FROM sale_items').get() as { count: number }).count, 1);
  assert.equal((db.prepare('SELECT count(*) AS count FROM payments').get() as { count: number }).count, 1);
  db.close();
});

test('duplicate retries never create extra rows or reset acknowledged sales', (t) => {
  const { open, scope } = fixture(t);
  const store = open();
  const data = sale();
  store.saveSale(scope, data);
  store.markSynced(scope, [data.transaction_uuid]);
  store.saveSale(scope, data);
  assert.equal(store.getSales(scope).length, 1);
  assert.equal(store.getSales(scope, true).length, 0);
  assert.throws(() => store.saveSale(scope, { ...data, total_amount: 999 }), /different sale data/);
  assert.equal(store.getSales(scope)[0].total_amount, data.total_amount);
});

test('one-gram sale quantities survive reopening and sync without rounding', async (t) => {
  const { open, scope } = fixture(t);
  const store = open();
  const data = sale();
  data.items[0].quantity = 0.001;
  store.saveSale(scope, data);
  store.close();
  const reopened = open();
  assert.equal(reopened.getSales(scope, true)[0].items[0].quantity, 0.001);
  await synchronizeOfflineData(bridge(reopened), scope, transport({ push: async ({ transactions }) => {
    assert.equal(transactions[0].items[0].quantity, 0.001);
    return { synced_uuids: [data.transaction_uuid] };
  } }));
  assert.equal(reopened.getSales(scope)[0].items[0].quantity, 0.001);
  assert.throws(() => reopened.saveSale(scope, { ...sale(), items: [{ ...data.items[0], quantity: 0.0001 }] }));
});

test('a failure after inserting the sale rolls back the sale, items, and payments', (t) => {
  const { open, scope, filename } = fixture(t);
  const store = open();
  const db = new Database(filename);
  db.exec("CREATE TRIGGER fail_payment BEFORE INSERT ON payments BEGIN SELECT RAISE(FAIL, 'simulated disk failure'); END");
  const data = sale();
  assert.throws(() => store.saveSale(scope, data), /simulated disk failure/);
  assert.equal(store.getSales(scope).length, 0);
  assert.equal((db.prepare('SELECT count(*) AS count FROM sale_items').get() as { count: number }).count, 0);
  db.exec('DROP TRIGGER fail_payment');
  db.close();
  store.saveSale(scope, data);
  assert.equal(store.getSales(scope, true).length, 1);
});

test('scopes isolate stores and devices and reject cross-store writes', (t) => {
  const { open, scope } = fixture(t);
  const store = open();
  const other: StorageScope = { ...scope, storeUuid: randomUUID() };
  const data = sale();
  store.saveSale(scope, data);
  assert.equal(store.getSales(other).length, 0);
  store.markSynced(other, [data.transaction_uuid]);
  assert.equal(store.getSales(scope, true).length, 1);
  assert.throws(() => store.saveSale(other, { ...data, store_uuid: scope.storeUuid }), /another store/);
  assert.throws(() => store.getSales({ ...scope, deviceUuid: 'invalid' }), /Invalid UUID/);
});

test('legacy JSON import is atomic, preserves statuses and original file, and runs once', (t) => {
  const { open, scope, legacy } = fixture(t);
  const pending = sale();
  const synced = { ...sale(), sync_status: 'synced' };
  const original = JSON.stringify([pending, synced]);
  fs.writeFileSync(legacy, original);
  const store = open();
  assert.equal(store.getSales(scope).length, 2);
  assert.equal(store.getSales(scope, true).length, 1);
  assert.equal(fs.readFileSync(legacy, 'utf8'), original);
  fs.writeFileSync(legacy, 'corrupt after successful import');
  assert.equal(open().getSales(scope).length, 2);
});

test('malformed legacy records fail visibly without partially importing or destroying the source', (t) => {
  const { open, scope, legacy } = fixture(t);
  const store = open();
  fs.writeFileSync(legacy, JSON.stringify([sale(), { transaction_uuid: 'bad' }]));
  assert.throws(() => store.getSales(scope), /Invalid UUID/);
  assert.equal(JSON.parse(fs.readFileSync(legacy, 'utf8')).length, 2);
  const replacement = sale();
  fs.writeFileSync(legacy, JSON.stringify([replacement]));
  assert.deepEqual(store.getSales(scope).map((s) => s.transaction_uuid), [replacement.transaction_uuid]);
});

test('catalog and checkpoint survive reopening, with Sinhala, warranty, filtering, and barcode lookup', (t) => {
  const { open, scope } = fixture(t);
  const store = open();
  const p = product();
  const catalog = delta([p], 12);
  catalog.categories = [{ id: 1, uuid: p.category!.uuid, name: 'Dairy', slug: 'dairy' }];
  catalog.customers = [{ id: 1, uuid: randomUUID(), name: 'Customer', loyalty_points: 7, credit_limit: 0, balance: 0 }];
  store.applyDelta(scope, catalog);
  const reader = open();
  assert.equal(reader.getCatalog(scope).current_version, 12);
  assert.deepEqual(reader.getCatalog(scope, { search: 'කිරි' }).products, [p]);
  assert.equal(reader.getCatalog(scope, { category_uuid: randomUUID() }).products.length, 0);
  assert.equal(reader.getCatalog(scope).customers[0].loyalty_points, 7);
  assert.deepEqual(reader.getProductByBarcode(scope, p.barcode!), p);
  assert.deepEqual(reader.getProductByBarcode(scope, 'milk-001'), p);
  assert.equal(reader.getProductByBarcode({ ...scope, storeUuid: randomUUID() }, p.barcode!), null);
  assert.equal(reader.getCatalog(scope, { search: "' OR 1=1 --" }).products.length, 0);
});

test('a rejected delta rolls back every changed record and its version', (t) => {
  const { open, scope } = fixture(t);
  const store = open();
  const p = product();
  store.applyDelta(scope, delta([p], 1));
  const invalid = delta([{ ...p, selling_price: 99 }, { ...product(), uuid: 'broken' }], 2);
  assert.throws(() => store.applyDelta(scope, invalid), /Invalid UUID/);
  assert.equal(store.getCatalog(scope).current_version, 1);
  assert.equal(store.getProductByBarcode(scope, p.barcode!)?.selling_price, 11);
  assert.throws(() => store.applyDelta(scope, delta([], 0)), /backwards/);
});

test('inactive and deleted catalog tombstones remove cached entries', (t) => {
  const { open, scope } = fixture(t);
  const store = open();
  const p = product();
  store.applyDelta(scope, delta([p]));
  store.applyDelta(scope, delta([{ ...p, is_active: false }], 2));
  assert.equal(store.getProductByBarcode(scope, p.barcode!), null);
  store.applyDelta(scope, delta([p], 3));
  store.applyDelta(scope, delta([{ ...p, deleted_at: new Date().toISOString() }], 4));
  assert.equal(store.getCatalog(scope).products.length, 0);
});

test('partial push only acknowledges submitted UUIDs and retains rejected sales after reopening', async (t) => {
  const { open, scope } = fixture(t);
  const store = open();
  const sales = [sale(), sale()];
  sales.forEach((s) => store.saveSale(scope, s));
  const result = await synchronizeOfflineData(bridge(store), scope, transport({
    push: async () => ({ synced_uuids: [sales[0].transaction_uuid, sales[0].transaction_uuid, randomUUID()],
      failed_uuids: [{ uuid: sales[1].transaction_uuid, error: 'Rejected' }] }),
  }));
  assert.deepEqual(result, { syncedCount: 1, pendingCount: 1, hasFailures: true });
  assert.deepEqual(open().getSales(scope, true).map((s) => s.transaction_uuid), [sales[1].transaction_uuid]);
});

test('lost push response retains UUID and payload for an idempotent retry', async (t) => {
  const { open, scope } = fixture(t);
  const store = open();
  const data = sale();
  store.saveSale(scope, data);
  const sent: OfflineSale[][] = [];
  await assert.rejects(synchronizeOfflineData(bridge(store), scope, transport({
    push: async ({ transactions }) => { sent.push(transactions); throw new Error('lost response'); },
  })), /lost response/);
  await synchronizeOfflineData(bridge(store), scope, transport({
    push: async ({ transactions }) => { sent.push(transactions); return { synced_uuids: [data.transaction_uuid] }; },
  }));
  assert.deepEqual(sent[0], sent[1]);
  assert.equal(store.getSales(scope, true).length, 0);
});

test('pull failure does not revert acknowledged sales or advance the saved catalog version', async (t) => {
  const { open, scope } = fixture(t);
  const store = open();
  const data = sale();
  store.saveSale(scope, data);
  store.applyDelta(scope, delta([], 5));
  await assert.rejects(synchronizeOfflineData(bridge(store), scope, transport({
    pull: async (params) => {
      assert.equal(params.since_version, 5);
      assert.equal(params.device_uuid, scope.deviceUuid);
      throw new Error('pull failed');
    },
  })), /pull failed/);
  assert.equal(store.getSales(scope, true).length, 0);
  assert.equal(store.getCatalog(scope).current_version, 5);
});

test('sync caps batches at 50 and counts sales created during the request', async (t) => {
  const { open, scope } = fixture(t);
  const store = open();
  for (let i = 0; i < 51; i++) store.saveSale(scope, sale());
  const result = await synchronizeOfflineData(bridge(store), scope, transport({
    push: async ({ transactions }) => {
      assert.equal(transactions.length, 50);
      store.saveSale(scope, sale());
      return { synced_uuids: transactions.map((s) => s.transaction_uuid) };
    },
  }));
  assert.deepEqual(result, { syncedCount: 50, pendingCount: 2, hasFailures: false });
});
