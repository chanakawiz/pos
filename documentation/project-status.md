# SmartShop POS — Current Project Status

> **Audit Date**: 2026-10-24
> **Overall Health**: Healthy / Stable (28 backend tests, 41 native Electron tests, and 14 Flutter mobile POS tests passing)
> **Phase 1 Progress**: SQLite persistence complete; printer/drawer, customer-display, and weighing-scale software complete; physical validation remains
> **Phase 2 Progress**: Flutter Mobile POS Complete — Architecture, SQLite Persistence, Split-Screen & Queue Buster, Network Auto-Sync, and ESC/POS Thermal Printing (MOB-001 through MOB-007)

---

## 1. System Health Dashboard

```text
┌─────────────────────────┬─────────────────────────┬─────────────────────────┐
│     BACKEND API         │    FILAMENT ADMIN ERP   │    WINDOWS POS CLIENT   │
│     ● ONLINE (100%)     │     ● ONLINE (100%)     │     ● OPERATIONAL (95%) │
│  28 Backend Tests Pass  │  13 Resources Active    │  Vite Build Passing     │
│  Sync Revisions Active  │  Full Catalog & Ledger  │  SQLite + Sync Tested   │
└─────────────────────────┴─────────────────────────┴─────────────────────────┘
```

---

## 2. Module Completion Matrix

### 2.1 Backend (`backend/laravel-api`)
| Module | Status | Notes |
| :--- | :---: | :--- |
| **Authentication & RBAC** | `✅ DONE` | Sanctum tokens, PIN pad hash, 4 Spatie roles. |
| **Product & Catalog** | `✅ DONE` | Categories, Brands, Products, Variants, Barcodes, Warranty, Serial/IMEI flags. |
| **Smart Items & Tech Vertical**| `✅ DONE` | Mobile phones, electronics, gadgets, serial number tracking, warranty claim receipts. |
| **Billing & Sales** | `✅ DONE` | Idempotent sales, split tenders, tax, discounts, IMEI/Serial number capture. |
| **Customer CRM & Loyalty**| `✅ DONE` | Phone search, credit limit, balance, point redemption. |
| **Refunds & Restocking** | `✅ DONE` | Return line items, optional restock, audit ledger. |
| **Cash Sessions & Shifts**| `✅ DONE` | Open float, close session, X-Report & Z-Report API. |
| **Multi-Lane Held Bills** | `✅ DONE` | Cross-register hold & recall with store scoping. |
| **Supply Chain & POs** | `✅ DONE` | Suppliers directory, PO drafting, stock receiving. |
| **Reporting & Analytics** | `✅ DONE` | Sales summary, top products, low stock alerts. |
| **Offline Sync Engine** | `✅ DONE` | Push (dedup + stock reconcile), Pull (version delta).|

### 2.2 Filament v3 Admin ERP (`backend/laravel-api`)
| Resource | Status | Notes |
| :--- | :---: | :--- |
| **BrandResource** | `✅ DONE` | Full Brand management: List, Create, Edit pages, slug auto-generation, logo upload (Apple, Samsung, Anker, Sony, etc.). |
| **CategoryResource** | `✅ DONE` | Hierarchical parent-child category tree, auto-slug, image upload (Smartphones, Wearables, Power, Groceries, Apparel). |
| **ProductResource** | `✅ DONE` | Bilingual English + Sinhala names, Smart Items & Warranty tab, serial/IMEI flag, barcode helper, initial stock. |
| **InventoryResource** | `✅ DONE` | Multi-store inventory balances, low-stock danger badges, English/Sinhala product descriptions. |
| **SupplierResource** | `✅ DONE` | Vendor directory, contacts, tax IDs, terms. |
| **PurchaseResource** | `✅ DONE` | Purchase orders, item repeaters, goods receiving with automatic stock increment. |
| **CashSessionResource**| `✅ DONE` | Register shifts, floats, discrepancy audit. |
| **RefundResource** | `✅ DONE` | Customer refunds audit with cashier mapping and restock status. |
| **StockMovementResource**| `✅ DONE` | Immutable audit ledger tracking all stock additions, deductions, sales, and adjustments. |
| **StatsOverviewWidget** | `✅ DONE` | Daily revenue, transactions count, open shifts, low-stock count. |
| **SalesChartWidget**    | `✅ DONE` | Line chart showing 14-day sales trend and order volume. |
| **LowStockWidget**      | `✅ DONE` | Immediate alert table for products below minimum stock safety. |

### 2.3 Windows POS Client (`apps/windows-pos`)
| Feature | Status | Notes |
| :--- | :---: | :--- |
| **Electron & React Shell** | `✅ DONE` | Secure context isolation bridge, dark UI, cross-platform macOS/Windows runtime. |
| **.env Language Switcher** | `✅ DONE` | Configurable default via `VITE_DEFAULT_LANGUAGE=bilingual/si/en`, instant top-bar language toggle. |
| **Smart Items & Serial/IMEI**| `✅ DONE` | Enter or scan IMEI/Serial number per cart item, warranty tags, and warranty claim printing. |
| **Login & PIN Pad** | `✅ DONE` | Fast numerical keypad authentication. |
| **Catalog Grid & Barcodes**| `✅ DONE` | Sub-second category search & item scanning with Sinhala names and warranty badges. |
| **Hardware Barcode Reader**| `✅ DONE` | Universal USB/Bluetooth HID wedge hook (<60ms key detection), auto cart add, 1760Hz synth beep. |
| **Cart & Quick Actions** | `✅ DONE` | Line discounts, bill discount, hold bill (F4), Sinhala name sub-labels, IMEI modal prompt. |
| **Multi-Lane Held Bills** | `✅ DONE` | Cloud API synchronized with cross-lane resume. |
| **Multi-Payment Modal** | `✅ DONE` | Cash change calculation, cards, split payment, melodic success chime. |
| **Bilingual Receipt Modal**| `✅ DONE` | Dual (EN+සිං) / සිංහල / EN switch, Sinhala headers, items, labels, IMEI/Serial, & blessings. |
| **Shift Audit (X/Z-Report)**| `✅ DONE` | Mid-shift balance audit & shift end reconciliation. |
| **Refund Processing** | `✅ DONE` | Invoice lookup and item return flow with automatic stock restoration. |
| **Background Sync Daemon**| `✅ DONE` | Network ping, queue flush, delta pull. |
| **ESC/POS Cash Drawer** | `✅ SOFTWARE DONE` | Configured-pin pulse, TCP/Windows RAW transport, F8/checkout handling, serialized delivery, and visible errors. Physical operation awaits equipment. |
| **ESC/POS Thermal Engine**| `✅ SOFTWARE DONE` | Dedicated 58/80mm raster documents with a bundled Sinhala font, sale/refund/X/Z layouts, and real transport. Physical/Windows checks remain. |
| **Customer Secondary Display** | `✅ SOFTWARE DONE` | Sandboxed English/Sinhala/bilingual cart, separate session, hotplug placement, persisted F1 pause/resume, and logout/reload clearing. Physical Windows monitor checks remain. |
| **RS-232 Weighing Scales** | `✅ SOFTWARE DONE` | Explicit A&D formats, stable/fresh kg/g capture, reweighing, three-decimal sale/stock/refund/sync quantities, and visible failures. Actual scale and Windows adapter acceptance remain. |
| **Help & Shortcuts (F1)** | `✅ DONE` | Instant cheat sheet modal for cashier hotkeys. |
| **Embedded SQLite** | `✅ DONE` | WAL/FULL durability; atomic sales/items/payments; scoped catalog checkpoints; safe legacy queue import; native recovery/sync tests. |

### 2.4 Mobile POS (`apps/mobile-pos`) — Phase 2
| Feature | Status | Notes |
| :--- | :---: | :--- |
| **Flutter Project Init** | `✅ DONE` | Flutter 3.27+, Material 3 dark retail design system, and Riverpod state container. |
| **Tablet Split Screen** | `✅ DONE` | Adaptive 60/40 Landscape cashier workspace with fixed cart panel and live totals. |
| **Phone Queue Buster** | `✅ DONE` | Single-column view with live camera barcode scanner (`mobile_scanner`) and floating cart sheet. |
| **Mobile SQLite & Sync** | `✅ DONE` | Embedded `sqflite` database with atomic sales persistence, WAL durability, and Dio delta sync. |
| **Smart Items & Warranty**| `✅ DONE` | Serial number / IMEI capture, warranty period badges, and bilingual Sinhala receipt preview. |
| **ESC/POS Printing & Drawer**| `✅ DONE` | Raw TCP socket (port 9100), 80/58mm formatting, pin 2/5 drawer kick, and in-app simulator. |

---

## 3. Test Suite Verification
```bash
$ php artisan test
  Tests:    28 passed (281 assertions on local MySQL; 239 on isolated SQLite)
  Duration: 0.89s
```
```bash
$ npm run build (apps/windows-pos)
  ✓ built in 215ms
```


## 4. Offline persistence verification — 2026-10-17

WIN-013 is complete. Desktop checkout now saves a sale before confirming payment, and the cached catalog works during an outage and after restart for an existing authenticated session. Initial login and device setup require connectivity. Browser preview remains online-only.

API-015 replaces independent record counters with a transactional global revision sequence, includes stock changes and deletion tombstones in catalog pulls, and preserves captured tax rates for offline receipts. The new backend migration was applied to the local MySQL database and verified on a fresh isolated SQLite database. Apply it to other environments before using the updated desktop sync client.

Remaining Phase 1 work is physical peripheral/secondary-monitor/scale acceptance and Windows device testing. Desktop scale software is implemented for explicitly configured A&D formats. Real printer/drawer transport is now implemented; local TCP receiver tests verify byte delivery, while physical output and Windows spooler execution still require target validation.

Final lint check exits successfully with seven existing React hook/unused-variable warnings. PHP formatting and `git diff --check` pass. The GUI smoke test also verifies failed-write feedback, cart retention, retry, reload recovery, and reconnect synchronization.

Printing continuation: WIN-011/WIN-012 software is verified by 27 native tests and the GUI smoke test (including long 58mm Sinhala output). The unsigned macOS arm64 package includes the font/license and decoder. Configuration and deployment checks are in [receipt-printing.md](receipt-printing.md).

Customer-display continuation: HRD-004 software passes native validation/monitor/IPC tests and an expanded GUI smoke suite using a real sandboxed renderer and simulated monitor events. Live quantities/discounts/held bills, all language modes, reconnect, persistent pause/resume, sale/logout clearing, and cashier shutdown are covered. Screenshot inspection passes. See [customer-display.md](customer-display.md) for operation and outstanding physical acceptance.

Weighing continuation (2026-10-18): HRD-005 software is verified with 41 native tests and the expanded GUI smoke suite using a real SerialPort stream/mock binding. Backend tests total 28 (281 MySQL / 239 SQLite assertions), covering fractional sale/refund precision and one-gram idempotent sync. The quantity migration is applied to development MySQL. See [weighing-scales.md](weighing-scales.md) for required rollout ordering and the unverified physical device checklist.
