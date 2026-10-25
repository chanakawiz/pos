import test from 'node:test';
import assert from 'node:assert/strict';
import net from 'node:net';
import type { AddressInfo } from 'node:net';
import type { PrintRequest } from '../printer-types';
import { parsePrinterProfile } from '../printer-config';
import { buildReceiptHtml, validatePrintRequest } from '../receipt-document';
import { encodeRaster, drawerPulse, finishReceipt } from '../escpos';
import { PrinterService } from '../printer-service';
import { PrinterDeliveryError, sendPrinterJob, sendTcp, sendWindows } from '../printer-transport';

const profile = () => parsePrinterProfile({ type: 'tcp', host: '127.0.0.1' });
const receipt = (): PrintRequest => ({ kind: 'sale', language: 'bilingual', storeNameSi: 'ස්මාර්ට්ෂොප්', sale: {
  invoice_number: 'POS-123', sold_at: '2026-10-17T10:00:00Z', subtotal: 10, tax_amount: 0.5, discount_amount: 0,
  total_amount: 10.5, paid_amount: 20, change_amount: 9.5, receipt: { store_name: 'Store', currency_symbol: 'Rs.' },
  items: [{ product_name: 'Milk', sinhala_name: 'කිරි', quantity: 1, total: 10.5, serial_number: 'IMEI-123', warranty_notes: '12 months' }],
} });

const listen = async (server: net.Server) => {
  await new Promise<void>((resolve) => server.listen(0, '127.0.0.1', resolve));
  return (server.address() as AddressInfo).port;
};

test('printer profiles select safe widths, explicit targets, pins and bounded timeouts', () => {
  assert.equal(profile().printableDots, 576);
  assert.equal(parsePrinterProfile({ type: 'tcp', host: 'printer.local', paperWidth: 58 }).printableDots, 384);
  assert.equal(parsePrinterProfile({ type: 'windows', printerName: 'USB receipt printer' }).transport.type, 'windows');
  for (const invalid of [null, {}, { type: 'tcp', host: '' }, { type: 'tcp', host: 'http://printer' },
    { type: 'tcp', host: 'printer', port: 0 }, { type: 'tcp', host: 'printer', printableDots: 385 },
    { type: 'tcp', host: 'printer', drawerPin: 3 }, { type: 'tcp', host: 'printer', timeoutMs: 999999 }]) {
    assert.throws(() => parsePrinterProfile(invalid));
  }
});

test('raster bits preserve black/white/alpha, byte padding, and image dimensions', () => {
  const data = Buffer.alloc(9 * 4, 255);
  data.fill(0, 0, 3); // black pixel 0
  data.fill(0, 7 * 4, 7 * 4 + 3); // black pixel 7
  data.fill(0, 8 * 4, 8 * 4 + 4); // transparent black must remain white
  const bytes = encodeRaster({ width: 9, height: 1, data }, 'legacy');
  assert.deepEqual([...bytes.subarray(0, 8)], [0x1d, 0x76, 0x30, 0, 2, 0, 1, 0]);
  assert.deepEqual([...bytes.subarray(8)], [0x81, 0]);
  assert.throws(() => encodeRaster({ width: 10, height: 1, data }, 'legacy'), /Invalid/);
});

test('modern graphics encode bounded bands without losing the last row', () => {
  const data = Buffer.alloc(8 * 129 * 4); // opaque black
  for (let i = 3; i < data.length; i += 4) data[i] = 255;
  const bytes = encodeRaster({ width: 8, height: 129, data }, 'graphics');
  assert.equal(bytes.readUInt16LE(3), 138); // ten control bytes + 128 rows
  assert.equal(bytes.readUInt16LE(11), 8); // width is dots, not bytes
  assert.equal(bytes.readUInt16LE(13), 128);
  assert.ok(bytes.subarray(15, 15 + 128).every((byte) => byte === 255));
  const next = 15 + 128 + 7;
  assert.equal(bytes.readUInt16LE(next + 3), 11);
  assert.equal(bytes.readUInt16LE(next + 13), 1);
  assert.equal(bytes[next + 15], 255);
});

test('drawer uses only the configured pin and receipt reprints contain no drawer pulse', () => {
  assert.deepEqual([...drawerPulse(2)], [0x1b, 0x70, 0, 25, 250]);
  assert.deepEqual([...drawerPulse(5)], [0x1b, 0x70, 1, 25, 250]);
  assert.deepEqual([...finishReceipt('none')], [0x1b, 0x64, 3]);
  assert.deepEqual([...finishReceipt('full')], [0x1b, 0x64, 3, 0x1d, 0x56, 0]);
  assert.equal(finishReceipt('partial').includes(drawerPulse(2)), false);
});

test('receipt documents escape untrusted strings and preserve language, currency, serial and warranty', () => {
  const input = receipt();
  assert.equal(input.kind, 'sale');
  if (input.kind !== 'sale') return;
  input.sale.invoice_number = '<script>danger()</script>';
  input.sale.items[0].product_name = '<img src="https://bad.test">';
  const request = validatePrintRequest(input);
  const html = buildReceiptHtml(request, profile(), 'AA==');
  assert.ok(html.includes('&lt;script&gt;danger()&lt;/script&gt;'));
  assert.ok(!html.includes('<img'));
  assert.ok(html.includes('කිරි'));
  assert.ok(html.includes('Rs.10.50'));
  assert.ok(html.includes('IMEI-123'));
  assert.ok(html.includes('12 months'));
  assert.ok(html.includes("default-src 'none'"));
  assert.ok(!html.includes('Current Sale'));
  const english = buildReceiptHtml({ ...input, language: 'en' }, profile(), 'AA==');
  assert.ok(!english.includes('කිරි'));
  const sinhala = buildReceiptHtml({ ...input, language: 'si' }, profile(), 'AA==');
  assert.ok(sinhala.includes('කිරි'));
  assert.ok(!sinhala.includes('&lt;img'));
});

test('invalid receipt totals and oversize jobs fail validation before reaching hardware', () => {
  const input = receipt();
  if (input.kind !== 'sale') return;
  assert.throws(() => validatePrintRequest({ ...input, sale: { ...input.sale, total_amount: NaN } }));
  assert.throws(() => validatePrintRequest({ ...input, sale: { ...input.sale, items: [] } }));
  assert.throws(() => validatePrintRequest({ ...input, language: 'invalid' }));
});

test('X/Z reports and refunds use their own financial fields rather than empty sale totals', () => {
  const shift = validatePrintRequest({ kind: 'shift', reportType: 'Z', report: {
    session_uuid: 'session-1', store_name: 'Store', cashier_name: 'Cashier', opened_at: '2026-10-17',
    opening_float: 100, cash_sales: 20, card_sales: 5, gross_sales: 25, discount_total: 0, refund_total: 150,
    transactions_count: 2, expected_cash: -30, actual_closing_cash: 0, discrepancy: 30,
  } });
  const html = buildReceiptHtml(shift, profile(), 'AA==');
  assert.ok(html.includes('Z-REPORT'));
  assert.ok(html.includes('-30.00'));
  assert.ok(html.includes('Variance'));
  const refund = validatePrintRequest({ kind: 'refund', receipt: { refund_number: 'REF-1', invoice_number: 'INV-1',
    store_name: 'Store', cashier_name: 'Cashier', total_refunded: 42.25, reason: 'Return', refunded_at: '2026-10-17' } });
  assert.ok(buildReceiptHtml(refund, profile(), 'AA==').includes('42.25'));
});

test('network transport delivers exact binary bytes to the configured endpoint', async (t) => {
  let delivered!: (value: Buffer) => void;
  const received = new Promise<Buffer>((resolve) => { delivered = resolve; });
  const server = net.createServer((socket) => {
    const chunks: Buffer[] = [];
    socket.on('data', (data) => chunks.push(data));
    socket.on('end', () => delivered(Buffer.concat(chunks)));
  });
  const port = await listen(server);
  t.after(() => server.close());
  const bytes = Buffer.from([0, 255, 27, 112, 1, 25, 250]);
  await sendPrinterJob(parsePrinterProfile({ type: 'tcp', host: '127.0.0.1', port }), bytes);
  assert.deepEqual(await received, bytes);
});

test('refused connections fail visibly and never claim successful delivery', async () => {
  const server = net.createServer();
  const port = await listen(server);
  await new Promise<void>((resolve) => server.close(() => resolve()));
  await assert.rejects(sendTcp('127.0.0.1', port, Buffer.from('receipt'), 1000),
    (error: unknown) => error instanceof PrinterDeliveryError && error.uncertain === false);
});

test('stalled writes time out and explicitly flag potentially partial delivery', { skip: process.platform === 'win32' }, async (t) => {
  const sockets: net.Socket[] = [];
  const server = net.createServer((socket) => { sockets.push(socket); socket.pause(); });
  const port = await listen(server);
  t.after(() => { sockets.forEach((socket) => socket.destroy()); server.close(); });
  await assert.rejects(sendTcp('127.0.0.1', port, Buffer.alloc(8 * 1024 * 1024), 100),
    (error: unknown) => error instanceof PrinterDeliveryError && error.uncertain);
});

test('an uncertain delivery cancels already queued jobs without retrying; new requests can resume after inspection', async () => {
  const order: string[] = [];
  let fail = true;
  const service = new PrinterService(profile, async () => { order.push('render'); return Buffer.from('receipt'); }, async (_profile, bytes) => {
    const kind = bytes[0] === 27 ? 'drawer' : 'receipt';
    order.push(kind);
    if (fail) { fail = false; throw new PrinterDeliveryError('Disconnected', true); }
  });
  const first = service.printReceipt(receipt());
  const second = service.openCashDrawer();
  const third = service.printReceipt(receipt());
  const results = await Promise.all([first, second, third]);
  assert.deepEqual(order, ['render', 'receipt']);
  assert.equal(results[0].success, false);
  assert.equal(results[0].uncertain, true);
  assert.equal(results[1].success, false);
  assert.equal(results[2].success, false);
  assert.equal((await service.openCashDrawer()).success, true);
  assert.deepEqual(order, ['render', 'receipt', 'drawer']);
});

test('successful receipt and drawer jobs remain in submission order', async () => {
  const delivered: string[] = [];
  const service = new PrinterService(profile, async () => Buffer.from('receipt'), async (_profile, bytes) => {
    await new Promise<void>((resolve) => setImmediate(resolve));
    delivered.push(bytes[0] === 27 ? 'drawer' : 'receipt');
  });
  await Promise.all([service.printReceipt(receipt()), service.openCashDrawer(), service.printReceipt(receipt())]);
  assert.deepEqual(delivered, ['receipt', 'drawer', 'receipt']);
});

test('missing configuration and disabled drawers cannot produce a false success', async () => {
  let sends = 0;
  const service = new PrinterService(() => parsePrinterProfile(null), async () => Buffer.from('receipt'), async () => { sends++; });
  assert.equal((await service.printReceipt(receipt())).success, false);
  assert.equal((await service.openCashDrawer()).success, false);
  const disabled = new PrinterService(() => ({ ...profile(), drawerEnabled: false }), async () => Buffer.from('receipt'), async () => { sends++; });
  const skipped = await disabled.openCashDrawer();
  assert.equal(skipped.success, false);
  assert.equal(skipped.skipped, true);
  assert.equal(sends, 0);
});

test('Windows printer queues fail visibly on unsupported platforms', { skip: process.platform === 'win32' }, async () => {
  await assert.rejects(sendWindows('Printer', Buffer.from('receipt'), 1000), /only on Windows/);
});
