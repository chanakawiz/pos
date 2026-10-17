# Desktop receipt printing and cash drawers

Implemented 2026-10-17 for WIN-011/WIN-012 and HRD-002/HRD-003. The software paths are tested with a local TCP receiver and real Electron rendering. Physical output, cutter behavior, drawer operation, and Windows spooler execution still need target-device verification.

## Terminal configuration

Create `printer.json` in Electron's user-data directory. The main process logs the exact path at startup. Packaged defaults are `%APPDATA%\SmartShop POS\printer.json` on Windows and `~/Library/Application Support/SmartShop POS/printer.json` on macOS; development runs may use the `Electron` directory instead. Keep this file outside the source checkout and configure each terminal separately.

Start from [`printer.example.json`](../apps/windows-pos/printer.example.json). Replace the example address with the printer's actual address:

```json
{
  "type": "tcp",
  "host": "192.168.1.50",
  "port": 9100,
  "paperWidth": 80,
  "printableDots": 576,
  "rasterMode": "graphics",
  "cut": "partial",
  "drawerPin": 2,
  "drawerEnabled": true,
  "timeoutMs": 15000
}
```

For a USB printer installed in Windows, use its exact Windows printer queue name:

```json
{
  "type": "windows",
  "printerName": "EPSON TM-T82 Receipt",
  "paperWidth": 58,
  "printableDots": 384,
  "rasterMode": "legacy",
  "cut": "none",
  "drawerPin": 2,
  "drawerEnabled": true,
  "timeoutMs": 15000
}
```

The Windows helper uses PowerShell and the Winspool `RAW` datatype. The queue must target an ESC/POS-compatible printer: these bytes are not suitable for arbitrary document printers. Printer names and binary payloads are passed as JSON over stdin, outside executable command text. No receipt files are left on disk. [Microsoft's RAW printing sequence](https://learn.microsoft.com/en-us/windows/win32/printdocs/sending-data-directly-to-a-printer) describes the underlying spooler calls.

- `paperWidth`: `58` or `80`. Defaults to `80`.
- `printableDots`: actual usable print-head width, defaulting to 384 for 58mm and 576 for 80mm. Configure this from the printer manual; roll width alone does not establish its printable dot width. Values must be multiples of eight from 256 through 832.
- `rasterMode`: `graphics` uses Epson's `GS ( L` graphics functions. Use `legacy` for models requiring `GS v 0`. Select the mode supported by the exact printer. [Epson graphics reference](https://download4.epson.biz/sec_pubs/pos/reference_en/escpos/gs_lparen_cl_fn112.html).
- `cut`: `partial`, `full`, or `none`; use `none` on printers without a cutter.
- `drawerPin`: `2` or `5`. Only the chosen pin receives the `ESC p` pulse (50ms on, 500ms off).
- `drawerEnabled`: set `false` on terminals without a drawer. Automatic cash-sale requests are then skipped quietly; F8 explains that drawer control is disabled.
- `timeoutMs`: 100–60000ms, default 15000ms. This bounds transport delivery; rendering has its own 30-second limit.

The configuration is read for each submitted job, so edits take effect without rebuilding the app. An absent or invalid file reports a visible error and sends nothing. Renderer requests cannot choose a destination or provide arbitrary raw printer bytes. USB printing through non-Windows hosts is not implemented; use the TCP path on those platforms.

## Receipt and drawer behavior

The receipt button prints a dedicated document containing the selected English/Sinhala language, store metadata, item names, quantities, tax/discount totals, paid/change amounts, serial/IMEI details, warranty notes, and footer. Sinhala is shaped by Chromium with the bundled, OFL-licensed Noto Sans Sinhala font, then rasterized. The printer does not need a Sinhala text code page. The receipt renderer has no Node access, network access, or app preload, and business text is HTML-escaped.

The 58mm/80mm layouts use the configured printable dot width. Large receipts are captured in tiles and encoded in bands of up to 128 rows. Scrollbars and cashier controls are excluded. Dates use the terminal's local time zone. X/Z reports and refund receipts have dedicated layouts using their own fields.

Cash checkout commits the sale first, then requests a drawer pulse. Drawer failures appear separately and cannot turn a committed sale into a failed payment. F8 ignores key repeats and shares the same in-flight drawer request. Reprinting a receipt never opens the drawer. Successful shift closure is retained in the modal with a separate Z-report reprint action if printing fails; closing the register is not repeated to retry printing.

Receipt and drawer jobs are serialized. Sending succeeds only after the socket accepts all bytes or Windows returns a spool job ID. This confirms transport/spool submission, not physical paper output or drawer motion. An interrupted write is flagged as uncertain, cancels already queued follow-up jobs, and is never automatically retried. Check the output and printer state before explicitly submitting again; a partial raster transfer may require clearing or restarting the printer.

## Verification

```sh
cd apps/windows-pos
npm test
npm run test:smoke
npm run lint
```

The native suite includes configuration, raster geometry and alpha handling, binary TCP delivery, refused connections, stalled writes, job ordering, uncertain delivery, language/escaping, report/refund layouts, and existing offline queue recovery. The GUI smoke test uses real Electron rendering and a mock network printer to check cash drawer delivery, bilingual printing, visible failures without duplicate sales, and a long 58mm receipt spanning multiple capture tiles. It makes no connection to a real printer.

Optional visual QA of mock data: set `SMARTSHOP_PRINT_ARTIFACTS` to an output directory while running `npm run test:smoke`; a decoded 58mm PNG preview is written there. Source font and license are copied into the packaged app.

Before deployment, verify each supported Windows/printer combination: RAW spool submission, graphics mode, usable width, Sinhala readability, long receipts, cutter selection, configured drawer pin, unavailable printer behavior, and interrupted-delivery recovery. The macOS software tests do not establish those hardware results.
