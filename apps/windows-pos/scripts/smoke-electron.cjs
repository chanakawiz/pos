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
let window;
let storage;
let baseUrl;
const requests = [];

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
  // The launcher removes this isolated profile after Chromium exits and releases its files.
  app.exit(code);
}

app.whenReady().then(async () => {
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  baseUrl = `http://127.0.0.1:${server.address().port}`;
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
    'hardware:open-drawer': () => ({ success: false }),
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
  await finish(0);
}).catch(async (error) => {
  console.error(error);
  console.error('API requests:', requests);
  if (window && !window.isDestroyed()) console.error(await evaluate('document.body.innerText'));
  await finish(1);
});
