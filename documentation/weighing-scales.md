# RS-232 weighing scales

HRD-005 now has a configured serial reader and cashier capture flow. Supported protocols are explicitly selected A&D ASCII formats. No scale model was available during development; Windows serial-adapter operation, wiring, scale stability, tare, and calibration still require the actual equipment. Other manufacturers/protocols need a documented parser and fixtures before use.

## Deploy the quantity prerequisite first

Apply backend migration `2026_10_17_000002_preserve_three_decimal_stock_quantities.php` before updating terminals:

```sh
cd backend/laravel-api
php artisan migrate --force
```

The migration widens sale/refund/purchase quantities, inventory balances/reservations, and stock ledger quantities from `DECIMAL(12,2)` to `DECIMAL(15,3)`. Money retains two decimal places. Model casts and API validation preserve up to three decimal places, including `0.001 kg` (one gram). Offline SQLite retains the same quantity in its immutable sale payload. Refund entry accepts fractional quantities; Filament inventory and receiving inputs support three decimals.

The new migration has been applied to the development MySQL database and tested on a fresh seeded SQLite database. Its rollback refuses to narrow the columns when existing values would be rounded or exceed the old range. Do not deploy this desktop update against the old two-decimal backend schema.

## Configure one explicit port

Copy [scale.example.json](../apps/windows-pos/scale.example.json) to `scale.json` in Electron's user-data directory. Edit the file to match the device manual and OS port; the example settings do not identify your equipment.

```json
{
  "path": "COM3",
  "baudRate": 2400,
  "dataBits": 7,
  "stopBits": 1,
  "parity": "even",
  "protocol": "and-indicator",
  "weightType": "net",
  "staleAfterMs": 1500
}
```

Windows paths are explicit `COM` port names; macOS/Linux use an explicit `/dev/...` serial device. Baud rate, 7/8 data bits, 1/2 stop bits, and none/even/odd parity are required. Supported freshness is 500–5000ms. No port is selected automatically, and no port is opened while the profile is absent. An invalid profile produces visible feedback in the weighing dialog.

Enable continuous output on the scale, or use its physical print/send key to send a fresh reading just before capture. The reader transmits no zero/tare/calibration commands or polling bytes. RTS/CTS and XON/XOFF flow control are disabled; the port uses exclusive locking. Match the adapter, cable, wiring, and flow-control requirements to the device manual.

### Supported frames

Both formats require ASCII with CRLF termination and an explicit `kg` or `g` suffix:

| Profile protocol | Example stable frame | Interpretation |
| --- | --- | --- |
| `and-indicator` | `ST,NT,+000.125kg\r\n` | Two headers; only configured `NT` (net) or `GS` (gross) is accepted. `TR` (tare) is rejected. |
| `and-balance` | `ST,+000125.0  g\r\n` | One header; weight type is not encoded. Configure and verify the balance's displayed net/gross/tare behavior itself. |

`ST` is stable, `US` is moving, `OL` is overload, and indicator `HD` is held output. Only fresh positive `ST` readings can be captured. Bare numbers, unknown formats/units, wrong net/gross type, negative/zero values, and invalid frames are rejected. Serial chunks may split or combine frames; framing is bounded and resynchronizes after a full delimiter. A partial next frame temporarily blocks capture so an old stable frame cannot be used while new bytes are arriving.

These formats are documented in the manufacturer's [AD-4410 manual, data-format section](https://weighing.andonline.com/sites/default/files/documents/ad4410%20IM.pdf) and [EK-W/G manual, serial-interface section](https://www.aandd.jp/products/manual/balances/ekw-g.pdf). A&D models also offer other formats; the brand name alone does not establish compatibility. CR-only frames, FS comma-before-unit variants, device IDs, pounds, ounces, and automatic format detection are outside this implementation.

## Cashier operation

1. In the catalog, set the product's unit to `kg` or `g` and its price per that unit. Other units keep the regular add-to-cart flow.
2. Click the product or scan its barcode. The **Weigh product** dialog opens and connects the configured port. Browser preview cannot access the scale.
3. Check the physical scale's unit/tare and wait for a stable reading. The dialog converts grams/kilograms to the product's unit. A weight that cannot be represented exactly to three decimal places is rejected rather than rounded; for kilogram products the minimum is one gram.
4. Select **Capture weight**. Main-process validation rechecks freshness, stability, revision, and unit. A changed/expired reading fails visibly and leaves the cart unchanged. Identical continuous stable frames refresh freshness without invalidating the same displayed weight. Repeated clicks during capture cannot add duplicates.
5. The captured quantity is fixed in the cart. Selecting that product again adds a separately confirmed weight; **Reweigh** replaces its existing quantity. Reducing a quantity clamps its line discount to keep the line nonnegative. Live scale motion never changes an already captured cart quantity.
6. Cancel, capture, sign-out/session change, renderer reload/crash, and cashier shutdown release the port. **Reconnect scale** closes the old connection and rereads `scale.json`. There is no automatic reconnect or automatic sale after an error. Open/close waits are bounded; a failed close keeps an unusable handle for a deliberate close retry and does not authorize captures.

The main process owns the serial port. Only the trusted cashier main frame can connect, read status, capture, or disconnect through fixed IPC methods. The customer display has no serial bridge. Serial data never becomes code or a product lookup. No live readings are written to disk; the confirmed sale retains its quantity through normal persistence/sync.

## Verification

From `apps/windows-pos`, using Node.js 24:

```sh
npm test
npm run test:smoke
npm run lint
```

Native tests cover configuration, parser states, net/gross/unit validation, fragmented/oversize frames, freshness/revision rules, exact unit conversion, open/close timeouts, disconnect races, one-gram SQLite recovery/sync, a real SerialPort stream with its mock binding, and loading the native binding under Electron. The GUI smoke suite checks moving/stale/overload feedback, grams-to-kilograms conversion, capture deduplication, reweighing, port release, fractional offline checkout, and unchanged quantity on reconnect push.

Optional synthetic screenshots:

```sh
SMARTSHOP_SCALE_ARTIFACTS=/tmp/smartshop-scale-qa npm run test:smoke
```

Backend tests cover a `0.125 kg` sale, `0.024 + 0.101 kg` partial refunds, one-gram sync retries, rejected excess precision, and refused lossy rollback on SQLite and MySQL. Native serial libraries are unpacked from ASAR for packaging. SerialPort's API and mock binding are described in its [official documentation](https://serialport.io/docs/api-serialport/).

## Target-device acceptance

- [ ] Confirm exact model/protocol, port settings, CRLF frames, and intended net/gross output from the manufacturer's manual and a sample capture.
- [ ] Verify the Windows serial driver, adapter/cable, exclusive-port behavior, and device output against known loads and units.
- [ ] Confirm physical tare, zero, overload, motion, negative readings, unit changes, and device IDs cannot produce an incorrect captured quantity.
- [ ] Disconnect/reconnect during reads/open/close, test a busy/missing port, edit the profile, and restart after an error.
- [ ] Complete an offline weighed sale, restart, sync it, and partially refund/restock it against the deployed three-decimal schema.
