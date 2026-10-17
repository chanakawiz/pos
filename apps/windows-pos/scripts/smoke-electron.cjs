// Runs the built cashier UI with a real preload bridge and SQLite, using an isolated mock API.
const { app, BrowserWindow, ipcMain, session } = require('electron');
const { createServer } = require('node:http');
const { randomUUID } = require('node:crypto');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { OfflineStore } = require('../dist-electron/offline-store.js');
const Database = require('better-sqlite3');
const net = require('node:net');
const { PrinterService } = require('../dist-electron/printer-service.js');
const { readPrinterProfile } = require('../dist-electron/printer-config.js');
const { renderReceipt } = require('../dist-electron/receipt-renderer.js');
const { parsePrinterProfile } = require('../dist-electron/printer-config.js');
const { validatePrintRequest } = require('../dist-electron/receipt-document.js');
const { PNG } = require('pngjs');

const directory = process.env.SMARTSHOP_SMOKE_DIR || fs.mkdtempSync(path.join(os.tmpdir(), 'smartshop-ui-smoke-'));
const profile = path.join(directory, 'profile');
fs.mkdirSync(profile);
app.setPath('userData', profile);
app.disableHardwareAcceleration();
const scope = { storeUuid: randomUUID(), deviceUuid: randomUUID() };
const user = { uuid: randomUUID(), name: 'Smoke Cashier', email: 'smoke@example.test', role: 'cashier',
  store: { uuid: scope.storeUuid, name: 'Smoke Store', code: 'SMOKE', currency_symbol: '$', currency_code: 'USD' } };
const product = { id: 1, uuid: randomUUID(), name: 'Smoke Milk', sinhala_name: 'කිරි', sku: 'MILK-1', barcode: '1234567890',
  unit: 'pcs', cost_price: 8, selling_price: 11, tax_rate: 5, min_stock_level: 1, stock_quantity: 20, has_variants: false };
let online = false;
let pushed = [];
let shiftClosures = 0;
let window;
let storage;
let baseUrl;
const requests = [];
const printerJobs = [];
const printerServer = net.createServer((socket) => {
  const chunks = [];
  socket.on('data', (data) => chunks.push(data));
  socket.on('end', () => printerJobs.push(Buffer.concat(chunks)));
});

const server = createServer(async (request, response) => {
  const url = new URL(request.url, baseUrl || 'http://127.0.0.1');
  if (url.pathname.startsWith('/api/v1')) {
    requests.push(`${request.method} ${url.pathname} (${online ? 'online' : 'offline'}, origin: ${request.headers.origin})`);
    if (!online) { request.socket.destroy(); return; }
    const cors = { 'Access-Control-Allow-Origin': request.headers.origin || baseUrl,
      'Access-Control-Allow-Headers': 'Authorization, Content-Type, X-Device-UUID',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS' };
    if (request.method === 'OPTIONS') { response.writeHead(204, cors).end(); return; }
    let body = '';
    for await (const chunk of request) body += chunk;
    const payload = body ? JSON.parse(body) : {};
    let result;
    if (url.pathname.endsWith('/auth/me')) result = { user };
    else if (url.pathname.endsWith('/sync/status')) result = { status: 'success' };
    else if (url.pathname.endsWith('/sync/push')) {
      pushed.push(...payload.transactions);
      result = { synced_uuids: payload.transactions.map((sale) => sale.transaction_uuid), failed_uuids: [] };
    } else if (url.pathname.endsWith('/sync/pull')) result = { current_version: 2, products: [{ ...product, selling_price: 12 }], categories: [], customers: [] };
    else if (url.pathname.endsWith('/cash-sessions/current')) result = { status: 'open', session: { uuid: 'smoke-session' },
      summary: { expected_cash: 100, opening_float: 100, cash_sales: 0, card_sales: 0, transaction_count: 0 } };
    else if (url.pathname.endsWith('/cash-sessions/close')) {
      shiftClosures++;
      result = { status: 'success', report: { session_uuid: 'smoke-session', store_name: user.store.name, cashier_name: user.name,
        opened_at: new Date().toISOString(), closed_at: new Date().toISOString(), opening_float: 100, cash_sales: 0,
        card_sales: 0, gross_sales: 0, discount_total: 0, refund_total: 0, transactions_count: 0,
        expected_cash: 100, actual_closing_cash: 100, discrepancy: 0 } };
    }
    else result = { data: [], status: 'success' };
    response.writeHead(200, { 'Content-Type': 'application/json', ...cors });
    response.end(JSON.stringify(result));
    return;
  }
  const relative = url.pathname === '/' ? 'index.html' : url.pathname.slice(1);
  const filename = path.resolve(__dirname, '../dist', relative);
  if (!filename.startsWith(path.resolve(__dirname, '../dist') + path.sep)) { response.writeHead(403).end(); return; }
  if (!fs.existsSync(filename)) { response.writeHead(404).end(); return; }
  const type = filename.endsWith('.js') ? 'application/javascript' : filename.endsWith('.css') ? 'text/css' : 'text/html';
  let content = fs.readFileSync(filename);
  if (relative === 'index.html') {
    const seed = { pos_token: 'smoke-token', pos_user: JSON.stringify(user), pos_device_uuid: scope.deviceUuid };
    content = content.toString().replace('<head>', `<head><script>for (const [key, value] of Object.entries(${JSON.stringify(seed)})) localStorage.setItem(key, value);</script>`);
  }
  response.writeHead(200, { 'Content-Type': type });
  response.end(content);
});

async function until(check, label) {
  const deadline = Date.now() + 12000;
  while (Date.now() < deadline) {
    if (await check()) return;
    await new Promise((resolve) => setTimeout(resolve, 50));
  }
  throw new Error(`Timed out: ${label}`);
}
const evaluate = (script) => window.webContents.executeJavaScript(script, true);
const clickText = (text) => evaluate(`(() => {
  const button = [...document.querySelectorAll('button')].find((node) => node.textContent.includes(${JSON.stringify(text)}));
  if (!button || button.disabled) throw new Error('Button unavailable: ' + ${JSON.stringify(text)});
  button.click();
})()`);

async function finish(code) {
  if (window && !window.isDestroyed()) window.destroy();
  storage?.close();
  server.closeAllConnections();
  await new Promise((resolve) => server.close(resolve));
  await new Promise((resolve) => printerServer.close(resolve));
  // The launcher removes this isolated profile after Chromium exits and releases its files.
  app.exit(code);
}

app.whenReady().then(async () => {
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
  await new Promise((resolve) => printerServer.listen(0, '127.0.0.1', resolve));
  const printerFilename = path.join(directory, 'printer.json');
  const printerConfig = { type: 'tcp', host: '127.0.0.1', port: printerServer.address().port, paperWidth: 80 };
  fs.writeFileSync(printerFilename, JSON.stringify(printerConfig));
  const printer = new PrinterService(() => readPrinterProfile(printerFilename), async (request, profile) => {
    try { return await renderReceipt(request, profile); }
    catch (error) { console.error('Mock receipt renderer:', String(error.message).slice(0, 200)); throw error; }
  });
  storage = new OfflineStore(path.join(directory, 'pos.sqlite'));
  storage.applyDelta(scope, { current_version: 1, products: [product], categories: [], customers: [] });
  for (const [channel, handler] of Object.entries({
    'storage:save-offline-sale': (s, sale) => storage.saveSale(s, sale),
    'storage:get-offline-sales': (s) => storage.getSales(s, true),
    'storage:get-all-offline-sales': (s) => storage.getSales(s),
    'storage:mark-synced': (s, ids) => storage.markSynced(s, ids),
    'storage:get-catalog': (s, query) => storage.getCatalog(s, query),
    'storage:get-product-by-barcode': (s, code) => storage.getProductByBarcode(s, code),
    'storage:apply-catalog-delta': (s, delta) => storage.applyDelta(s, delta),
    'hardware:open-drawer': () => printer.openCashDrawer(),
    'printer:print-receipt': (request) => printer.printReceipt(request),
    'device:get-info': () => ({ platform: process.platform, appVersion: 'smoke', deviceUuid: scope.deviceUuid }),
  })) ipcMain.handle(channel, (_event, ...args) => handler(...args));
  session.defaultSession.webRequest.onBeforeRequest((details, callback) => {
    const url = new URL(details.url);
    if (url.pathname.startsWith('/api/v1') && !details.url.startsWith(baseUrl)) {
      callback({ redirectURL: `${baseUrl}${url.pathname}${url.search}` });
    } else callback({});
  });
  window = new BrowserWindow({ show: false, width: 1366, height: 900,
    webPreferences: { preload: path.resolve(__dirname, '../dist-electron/preload.js'), contextIsolation: true, nodeIntegration: false, sandbox: false } });
  await window.loadURL(baseUrl);
  await until(() => evaluate("document.body.innerText.includes('Smoke Milk')"), 'offline catalog');
  await evaluate("document.querySelector('div.group').click()");
  await clickText('PROCEED TO PAY');
  await until(() => evaluate("document.body.innerText.includes('Complete Payment')"), 'payment modal');
  const faultConnection = new Database(path.join(directory, 'pos.sqlite'));
  faultConnection.exec("CREATE TRIGGER fail_payment BEFORE INSERT ON payments BEGIN SELECT RAISE(FAIL, 'simulated storage failure'); END");
  await clickText('Complete Payment');
  await until(() => evaluate("document.body.innerText.includes('Unable to save this sale locally')"), 'storage error feedback');
  assert.equal(storage.getSales(scope).length, 0);
  assert.equal(await evaluate("document.body.innerText.includes('Payment Finalized')"), false);
  faultConnection.exec('DROP TRIGGER fail_payment');
  faultConnection.close();
  console.log('PASS: failed storage writes retain the cart and do not confirm payment');
  await clickText('Complete Payment');
  await until(() => evaluate("document.body.innerText.includes('Payment Finalized')"), 'durable offline receipt');
  assert.equal(storage.getSales(scope, true).length, 1);
  const saved = storage.getSales(scope, true)[0];
  assert.equal(saved.total_amount, 11.55);
  assert.equal(saved.cashier_uuid, user.uuid);
  assert.equal(pushed.length, 0);
  console.log('PASS: offline checkout saves the sale before confirming payment');
  await until(() => printerJobs.length === 1, 'automatic cash drawer delivery');
  assert.deepEqual(printerJobs[0], Buffer.from([27, 112, 0, 25, 250]));
  await clickText('Print Receipt');
  await until(() => evaluate("document.body.innerText.includes('Receipt sent to the printer.')"), 'receipt transmission');
  await until(() => printerJobs.length === 2, 'receipt binary delivery');
  assert.ok(printerJobs[1].includes(Buffer.from([29, 40, 76])));
  assert.ok(printerJobs[1].length > 1000);
  assert.deepEqual(printerJobs[1].subarray(-6), Buffer.from([27, 100, 3, 29, 86, 1]));
  console.log('PASS: rendered bilingual receipt and drawer pulse reach the network printer independently');

  fs.unlinkSync(printerFilename);
  await clickText('Print Receipt');
  await until(() => evaluate("document.body.innerText.includes('Configure this terminal')"), 'printer configuration feedback');
  assert.equal(storage.getSales(scope).length, 1);
  assert.equal(printerJobs.length, 2);
  await evaluate("window.dispatchEvent(new KeyboardEvent('keydown', {key: 'F8'}))");
  await until(() => evaluate("document.querySelector('[role=alert]')?.textContent.includes('Configure this terminal')"), 'drawer error notice above receipt');
  console.log('PASS: printing failures remain visible and never recreate or undo the completed sale');

  await new Promise((resolve) => {
    window.webContents.once('did-finish-load', resolve);
    window.reload();
  });
  await until(() => evaluate("document.body.innerText.includes('Smoke Milk')"), 'cached catalog after reload');
  assert.equal(storage.getSales(scope, true)[0].transaction_uuid, saved.transaction_uuid);
  console.log('PASS: catalog and queued sale survive renderer reload during an outage');
  online = true;
  await until(() => evaluate("!document.querySelector('button[title=\"Trigger Immediate Sync\"]').disabled"), 'sync available');
  await evaluate("document.querySelector('button[title=\"Trigger Immediate Sync\"]').click()");
  await until(() => storage.getSales(scope, true).length === 0, 'server acknowledgement');
  await until(() => storage.getCatalog(scope).current_version === 2, 'atomic catalog refresh');
  assert.equal(pushed.length, 1);
  assert.equal(pushed[0].transaction_uuid, saved.transaction_uuid);
  assert.equal(storage.getProductByBarcode(scope, product.barcode).selling_price, 12);
  console.log('PASS: reconnect pushes the original UUID once and persists the updated catalog');

  await clickText('Register');
  await until(() => evaluate("document.body.innerText.includes('Close Register & Print Z-Report')"), 'active shift');
  await clickText('Close Register & Print Z-Report');
  await until(() => evaluate("document.body.innerText.includes('Shift closed successfully.') && document.body.innerText.includes('Configure this terminal')"), 'closed shift with printer error');
  assert.equal(shiftClosures, 1);
  fs.writeFileSync(printerFilename, JSON.stringify(printerConfig));
  await clickText('Reprint Z-Report');
  await until(() => evaluate("document.body.innerText.includes('Receipt sent to the printer.')"), 'Z-report reprint');
  await until(() => printerJobs.length === 3, 'Z-report delivery');
  assert.equal(shiftClosures, 1);
  console.log('PASS: failed Z-report printing preserves shift closure; reprint sends no second close request');

  const longRequest = validatePrintRequest({ kind: 'sale', language: 'bilingual', storeNameSi: 'ස්මාර්ට්ෂොප් වෙළඳසැල', sale: {
    ...saved, invoice_number: 'SMOKE-LONG-58MM', subtotal: 528, tax_amount: 26.4, total_amount: 554.4,
    paid_amount: 554.4, change_amount: 0,
    receipt: { store_name: 'Smoke Store', cashier_name: user.name, currency_symbol: 'Rs.' },
    items: Array.from({ length: 48 }, (_, index) => ({ ...saved.items[0], product_name: `Long merchandise name ${index + 1}`,
      sinhala_name: `සිංහල පරීක්ෂණ භාණ්ඩය ${index + 1}`, serial_number: '358123456789012', warranty_notes: 'Warranty: 12 months' })),
  } });
  const longJob = await renderReceipt(longRequest, parsePrinterProfile({ ...printerConfig, paperWidth: 58, rasterMode: 'legacy' }));
  const bands = [];
  let offset = 5;
  let totalRows = 0;
  while (longJob.subarray(offset, offset + 3).equals(Buffer.from([29, 118, 48]))) {
    const width = longJob.readUInt16LE(offset + 4) * 8;
    const height = longJob.readUInt16LE(offset + 6);
    assert.equal(width, 384);
    const count = width / 8 * height;
    bands.push(longJob.subarray(offset + 8, offset + 8 + count));
    totalRows += height;
    offset += 8 + count;
  }
  assert.ok(totalRows > 2048);
  assert.deepEqual(longJob.subarray(offset), Buffer.from([27, 100, 3, 29, 86, 1]));
  const packed = Buffer.concat(bands);
  // Keep an optional decoded preview for visual QA, never a real customer receipt.
  if (process.env.SMARTSHOP_PRINT_ARTIFACTS) {
    fs.mkdirSync(process.env.SMARTSHOP_PRINT_ARTIFACTS, { recursive: true });
    const preview = new PNG({ width: 384, height: Math.min(1300, totalRows) });
    preview.data.fill(255);
    for (let y = 0; y < preview.height; y++) for (let x = 0; x < preview.width; x++) {
      if (packed[y * 48 + (x >> 3)] & (128 >> (x % 8))) {
        const i = (y * preview.width + x) * 4;
        preview.data[i] = preview.data[i + 1] = preview.data[i + 2] = 0;
      }
    }
    fs.writeFileSync(path.join(process.env.SMARTSHOP_PRINT_ARTIFACTS, 'receipt-58mm.png'), PNG.sync.write(preview));
  }
  console.log(`PASS: long 58mm bilingual receipt preserves all ${totalRows} raster rows across capture tiles`);
  await finish(0);
}).catch(async (error) => {
  console.error(error);
  console.error('API requests:', requests);
  if (window && !window.isDestroyed()) console.error(await evaluate('document.body.innerText'));
  await finish(1);
});
