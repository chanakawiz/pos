import test from 'node:test';
import assert from 'node:assert/strict';
import type { BrowserWindow, IpcMainInvokeEvent } from 'electron';
import { idleCustomerDisplay, selectCustomerMonitor, validateCustomerDisplay } from '../customer-display-types';
import { isTrustedFrame } from '../trusted-ipc';

const rect = (x: number, y = 0, width = 1920, height = 1080) => ({ x, y, width, height });
const monitors = [{ id: 1, bounds: rect(0) }, { id: 2, bounds: rect(-1920) }, { id: 3, bounds: rect(1920) }];

test('customer monitor selection excludes cashier, mirrored and partially overlapping displays', () => {
  assert.equal(selectCustomerMonitor(monitors, rect(100, 100, 1366, 768))?.id, 2);
  assert.equal(selectCustomerMonitor(monitors, rect(100, 100, 1366, 768), 3)?.id, 3);
  assert.equal(selectCustomerMonitor(monitors.slice(0, 1), rect(0)), undefined);
  assert.equal(selectCustomerMonitor([{ id: 1, bounds: rect(0) }, { id: 2, bounds: rect(0) }], rect(100)), undefined);
  assert.equal(selectCustomerMonitor(monitors, rect(1800, 100, 1366, 768))?.id, 2);
  assert.equal(selectCustomerMonitor(monitors.slice(1), rect(-1800, 100, 1366, 768))?.id, 3);
});

test('display IPC removes private fields at every level and validates finite bounded values', () => {
  const state = { ...idleCustomerDisplay(), token: 'secret', customer: { name: 'Private' }, items: [
    { name: '<script>alert(1)</script>', sinhalaName: 'කිරි', quantity: 0.25, unitPrice: 100, total: 25,
      cost_price: 1, serial_number: 'Private', product: { cost_price: 1 } },
  ] };
  const sanitized = validateCustomerDisplay(state);
  assert.deepEqual(Object.keys(sanitized), Object.keys(idleCustomerDisplay()));
  assert.deepEqual(Object.keys(sanitized.items[0]), ['name', 'sinhalaName', 'quantity', 'unitPrice', 'total']);
  assert.equal(sanitized.items[0].name, '<script>alert(1)</script>'); // Rendered as escaped React text.
  for (const value of [NaN, Infinity, -1, '10', 1e13]) assert.throws(() => validateCustomerDisplay({ ...state, total: value }));
  for (const value of [null, [], {}, { ...state, language: 'invalid' }, { ...state, items: Array(5001).fill(state.items[0]) },
    { ...state, storeName: 'x'.repeat(301) }, { ...state, items: [{ ...state.items[0], quantity: NaN }] }]) {
    assert.throws(() => validateCustomerDisplay(value));
  }
});

test('trusted IPC accepts only the exact cashier document and main frame', () => {
  const frame = { url: 'http://localhost:5173/' };
  const sender = { mainFrame: frame };
  const window = { isDestroyed: () => false, webContents: sender } as unknown as BrowserWindow;
  const event = { sender, senderFrame: frame } as unknown as IpcMainInvokeEvent;
  assert.equal(isTrustedFrame(event, window, 'http://localhost:5173/'), true);
  frame.url = 'http://localhost:5173/#cart';
  assert.equal(isTrustedFrame(event, window, 'http://localhost:5173/'), true);
  frame.url = 'http://localhost:5173/customer-display.html';
  assert.equal(isTrustedFrame(event, window, 'http://localhost:5173/'), false);
  frame.url = 'file:///app/dist/customer-display.html';
  assert.equal(isTrustedFrame(event, window, 'file:///app/dist/index.html'), false);
  frame.url = 'file:///app/dist/index.html';
  assert.equal(isTrustedFrame(event, window, frame.url), true);
  assert.equal(isTrustedFrame({ ...event, senderFrame: { url: frame.url } } as IpcMainInvokeEvent, window, frame.url), false);
  assert.equal(isTrustedFrame({ ...event, sender: {} } as IpcMainInvokeEvent, window, frame.url), false);
  assert.equal(isTrustedFrame(event, null, frame.url), false);
  assert.equal(isTrustedFrame(event, { ...window, isDestroyed: () => true } as BrowserWindow, frame.url), false);
});
