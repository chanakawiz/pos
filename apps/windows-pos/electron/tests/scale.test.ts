import test from 'node:test';
import assert from 'node:assert/strict';
import { EventEmitter } from 'node:events';
import { setImmediate as nextTick } from 'node:timers/promises';
import { SerialPort, SerialPortMock } from 'serialport';
import { parseScaleProfile } from '../scale-config';
import { parseWeight, ScaleFramer } from '../scale-parser';
import { ScaleService } from '../scale-service';
import type { ScalePort } from '../scale-service';
import { isValidQuantity, quantityFromWeight, roundQuantity } from '../quantity';

const profile = () => parseScaleProfile({ path: 'COM3', baudRate: 2400, dataBits: 7, stopBits: 1,
  parity: 'even', protocol: 'and-indicator', weightType: 'net', staleAfterMs: 1000 });

class FakePort extends EventEmitter implements ScalePort {
  isOpen = false;
  open(callback: (error: Error | null) => void) { this.isOpen = true; callback(null); }
  close(callback: (error: Error | null) => void) { this.isOpen = false; this.emit('close'); callback(null); }
}

test('scale profiles require explicit serial settings and a supported protocol/type', () => {
  assert.equal(profile().path, 'COM3');
  assert.equal(parseScaleProfile({ ...profile(), path: '/dev/cu.usbserial-1' }).staleAfterMs, 1000);
  for (const invalid of [null, {}, { ...profile(), path: '../COM3' }, { ...profile(), baudRate: '2400' },
    { ...profile(), protocol: 'auto' }, { ...profile(), dataBits: 6 }, { ...profile(), weightType: 'tare' },
    { ...profile(), parity: 'guess' }, { ...profile(), staleAfterMs: 60000 }]) assert.throws(() => parseScaleProfile(invalid));
});

test('A&D parser distinguishes stability, overload, net/gross/tare and units without guessing numbers', () => {
  const p = profile();
  assert.deepEqual(parseWeight('ST,NT,+000.125kg', p), { state: 'stable', value: 0.125, unit: 'kg' });
  assert.deepEqual(parseWeight('ST,NT,+00125.0 g', p), { state: 'stable', value: 125, unit: 'g' });
  assert.equal(parseWeight('US,NT,+000.125kg', p).state, 'unstable');
  assert.equal(parseWeight('HD,NT,+000.125kg', p).state, 'unstable');
  assert.equal(parseWeight('OL,NT,+     .  kg', p).state, 'overload');
  for (const line of ['ST,GS,+000.125kg', 'ST,TR,+000.125kg', 'ST,NT,-000.125kg', 'ST,NT,+000.000kg',
    'ST,NT,+000.125lb', '125kg', 'ST,NT,+1e3kg', 'ST,NT,+1 2.3kg', 'garbage125kg']) assert.equal(parseWeight(line, p).state, 'invalid');
  assert.equal(parseWeight('ST,GS,+000.125kg', { ...p, weightType: 'gross' }).state, 'stable');
  assert.deepEqual(parseWeight('ST,+000125.0  g', { ...p, protocol: 'and-balance' }), { state: 'stable', value: 125, unit: 'g' });
});

test('bounded serial framing handles split/coalesced CRLF and discards malformed/overflow frames', () => {
  const lines: string[] = [];
  let rejected = 0;
  const parser = new ScaleFramer((line) => lines.push(line), () => rejected++);
  parser.push(Buffer.from('ST,NT,+000.'));
  assert.equal(parser.hasPartialFrame, true);
  parser.push(Buffer.from('125kg\r\nUS,NT,+000.126kg\r\n'));
  assert.deepEqual(lines, ['ST,NT,+000.125kg', 'US,NT,+000.126kg']);
  assert.equal(parser.hasPartialFrame, false);
  parser.push(Buffer.from('x'.repeat(1000) + '\r\n\x00ST,NT,+000.125kg\r\nmissing-cr\nST,NT,+000.250kg\r\n'));
  assert.equal(rejected, 3);
  assert.equal(lines.at(-1), 'ST,NT,+000.250kg');
});

test('unit conversion preserves gram quantities and rejects unsupported precision instead of rounding', () => {
  assert.equal(quantityFromWeight(125, 'g', 'kg'), 0.125);
  assert.equal(quantityFromWeight(0.125, 'kg', 'g'), 125);
  assert.equal(quantityFromWeight(1, 'g', 'kg'), 0.001);
  assert.equal(roundQuantity(0.1 + 0.2), 0.3);
  for (const value of [0, -1, NaN, Infinity, 0.0001, 0.1234]) assert.equal(isValidQuantity(value), false);
  assert.throws(() => quantityFromWeight(0.1, 'g', 'kg'));
});

test('capture rejects changed, moving, partial, stale and disconnected readings; equal frames stay capturable', async () => {
  let now = 100;
  const port = new FakePort();
  const scale = new ScaleService(profile, () => port, () => now);
  await scale.connect();
  const send = (line: string) => port.emit('data', Buffer.from(line + '\r\n'));
  send('ST,NT,+000.125kg');
  const first = scale.status().reading!;
  assert.equal(scale.capture(first.revision, 'kg'), 0.125);
  now += 500;
  send('ST,NT,+000.125kg');
  assert.equal(scale.status().reading!.revision, first.revision);
  assert.equal(scale.capture(first.revision, 'g'), 125);
  send('ST,NT,+000.126kg');
  assert.throws(() => scale.capture(first.revision, 'kg'));
  send('US,NT,+000.126kg');
  assert.equal(scale.status().reading, null);
  assert.throws(() => scale.capture(first.revision, 'kg'));
  send('ST,NT,+000.125kg');
  const second = scale.status().reading!;
  port.emit('data', Buffer.from('US,'));
  assert.equal(scale.status().state, 'waiting');
  assert.throws(() => scale.capture(second.revision, 'kg'));
  port.emit('data', Buffer.from('NT,+000.125kg\r\n'));
  send('ST,NT,+000.125kg');
  now += 1001;
  assert.equal(scale.status().state, 'stale');
  assert.throws(() => scale.capture(scale.status().reading?.revision, 'kg'));
  await scale.disconnect();
  assert.equal(port.isOpen, false);
  assert.throws(() => scale.capture(second.revision, 'kg'));
});

test('serial errors invalidate capture until a deliberate reconnect, and missing config opens no port', async () => {
  let created = 0;
  const absent = new ScaleService(() => null, () => { created++; return new FakePort(); });
  assert.equal((await absent.connect()).state, 'disabled');
  assert.equal(created, 0);
  const port = new FakePort();
  const scale = new ScaleService(profile, () => port);
  await scale.connect();
  port.emit('data', Buffer.from('ST,NT,+000.125kg\r\n'));
  const revision = scale.status().reading!.revision;
  port.emit('error', new Error('Cable failure'));
  port.emit('data', Buffer.from('ST,NT,+000.125kg\r\n'));
  assert.equal(scale.status().state, 'error');
  assert.throws(() => scale.capture(revision, 'kg'));
  await scale.disconnect();
});

test('disconnect during open closes a late connection and lets the next request connect cleanly', async () => {
  let callback: ((error: Error | null) => void) | undefined;
  const port = new FakePort();
  port.open = (ready) => { callback = ready; };
  const scale = new ScaleService(profile, () => port);
  const opening = scale.connect();
  const closing = scale.disconnect();
  assert.equal(scale.status().reading, null);
  port.isOpen = true;
  callback!(null);
  await Promise.all([opening, closing]);
  assert.equal(port.isOpen, false);
  assert.equal(scale.status().state, 'disabled');
  port.open = FakePort.prototype.open;
  assert.equal((await scale.connect()).state, 'waiting');
  scale.dispose();
});

test('a stalled open times out and a late success closes without authorizing a capture', async () => {
  const port = new FakePort();
  let callback: ((error: Error | null) => void) | undefined;
  port.open = (ready) => { callback = ready; };
  const scale = new ScaleService(profile, () => port, Date.now, 10);
  assert.equal((await scale.connect()).state, 'error');
  port.isOpen = true; callback!(null);
  assert.equal(port.isOpen, false);
  assert.throws(() => scale.capture(1, 'kg'));
  scale.dispose();
});

test('real SerialPort stream with mock binding delivers split data and releases its port', async () => {
  const path = '/dev/smartshop-test-scale';
  SerialPortMock.binding.createPort(path, { record: true });
  const port = new SerialPortMock({ path, baudRate: 2400, autoOpen: false });
  const scale = new ScaleService(profile, () => port);
  await scale.connect();
  port.port!.emitData('ST,NT,+000.');
  await nextTick();
  port.port!.emitData('125kg\r\n');
  for (let i = 0; i < 20 && scale.status().state !== 'stable'; i++) await nextTick();
  const reading = scale.status().reading!;
  assert.ok(reading);
  assert.equal(scale.capture(reading.revision, 'kg'), 0.125);
  await scale.disconnect();
  assert.equal(port.isOpen, false);
  // Enumerating ports proves the shipped native binding can load under Electron's ABI.
  assert.ok(Array.isArray(await SerialPort.list()));
});

test('a stalled close expires visibly and retains the handle for a deliberate retry', async () => {
  const port = new FakePort();
  const scale = new ScaleService(profile, () => port, Date.now, 10);
  await scale.connect();
  port.close = () => {};
  await scale.disconnect();
  assert.equal(scale.status().state, 'error');
  port.emit('data', Buffer.from('ST,NT,+000.125kg\r\n'));
  assert.equal(scale.status().state, 'error');
  assert.equal(scale.status().reading, null);
  assert.throws(() => scale.capture(1, 'kg'));
  port.close = FakePort.prototype.close;
  await scale.disconnect();
  assert.equal(port.isOpen, false);
  assert.equal((await scale.connect()).state, 'waiting');
  scale.dispose();
});
