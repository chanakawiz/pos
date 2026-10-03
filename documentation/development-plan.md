# SmartShop POS — Master Development Plan

> **System**: SmartShop POS — Multi-Platform Retail & Inventory Management  
> **Document**: Phased Implementation & Engineering Roadmap  
> **Target Platforms**: Windows POS (Electron/React), Backend (Laravel 11 / Filament v3), Mobile POS (Flutter)  
> **Current Version**: 1.0.0

---

## 1. Development Strategy & Sequencing

To ensure maximum operational stability and immediate commercial viability, the engineering roadmap is divided into two distinct, sequential phases:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                       SMARTSHOP POS PHASED STRATEGY                         │
├──────────────────────────────────────┬──────────────────────────────────────┤
│    PHASE 1: IMMEDIATE PRIORITY       │         PHASE 2: SECONDARY           │
│    Windows POS & Laravel Backend     │        Mobile POS (iPad/iPhone)      │
│                                      │                                      │
│  • High-throughput cashier lanes     │  • Mobile floor sales & line-busting │
│  • Sub-second local billing engine   │  • Flutter 3.x with Material 3       │
│  • Full hardware ESC/POS integration │  • Tablet landscape split-screen     │
│  • Filament 3 ERP & admin panel      │  • Offline SQLite + Dio sync engine  │
│  • Bidirectional sync protocol       │  • Bluetooth thermal receipt print   │
└──────────────────────────────────────┴──────────────────────────────────────┘
```

---

## 2. Phase 1: Windows Desktop POS & Backend Hardening

### Milestone 1.1: Core Reliability & Complete Catalog/Billing (`✅ COMPLETED`)
- [x] **25 Relational Database Migrations**: Relational schema covering multi-store, hardware devices, catalog, inventory, ledger movements, sales, refunds, cash sessions, held bills, warranty tracking, and sync logs.
- [x] **Universal Multi-Vertical Retail Support (Smart Items / Mobile Devices / All Goods)**:
  - Not restricted to groceries: explicitly engineered for mobile phone shops, smart gadgets, computer electronics, hardware, apparel, and general merchandise.
  - Added `warranty_period` (e.g. "12 Months Apple Care", "6 Months Company") and `requires_serial` flags to products.
  - Added `serial_number` (IMEI / Serial) and `warranty_notes` to sale items for warranty claim tracking on invoices.
- [x] **Bilingual English & Sinhala Catalog Schema**: Added `sinhala_name` support across products, API endpoints, POS catalog views, and receipt formatting.
- [x] **Filament Admin ERP Completeness**: Full administrative control for Brands, Categories, Products, Customers, Sales, Stores, Devices, Users, Suppliers, Purchases, Cash Sessions, Refunds, and Stock Movements.
  - **Product Management**: Create and edit products with English name, Sinhala name, Category, Brand, barcode scanner input helper, Smart Items & Warranty tab, serial/IMEI flags, pricing, and automated initial stock initialization.
  - **Brand Management**: Create and edit brands (Apple, Samsung, Anker, Sony, Xiaomi, etc.) with auto-slug generation, logo uploads, and active state controls.
  - **Inventory System & Stock Ledger**: Multi-store stock balances, low-stock warnings, purchase order goods receiving with automatic stock additions, and immutable `stock_movements` ledger logging all additions, sales, refunds, and adjustments.
- [x] **Automated Test Coverage**: 100% test pass rate covering Auth, Billing, Cash Sessions, Customers, Held Bills, Products, Purchases, Refunds, Reports, and Offline Sync (18 tests, 225 assertions).
- [x] **Multi-Lane Cloud Held Bills**: Cross-register bill hold and resume engine with automatic inventory reservation.

### Milestone 1.2: Hardware Integration & ESC/POS Engine (`✅ COMPLETED`)
- [x] **Environment-Driven Multi-Language Configuration (`.env`)**:
  - Configurable via `VITE_DEFAULT_LANGUAGE=bilingual` (or `si`, `en`) in `apps/windows-pos/.env` and `DEFAULT_RECEIPT_LANGUAGE=bilingual` in `backend/laravel-api/.env`.
  - Terminal starts in the specified language mode automatically.
  - Dynamic 1-click language switcher (`[EN | සිං | Dual]`) on the cashier top-bar and receipt modal for instant on-the-fly toggling.
- [x] **Universal Barcode Scanner Integration**:
  - Global USB and Bluetooth HID keyboard wedge hook (`useBarcodeScanner`) with `< 60ms` inter-key detection.
  - Operates reliably whether the search input is focused or unfocused.
  - Web Audio API synthesizer for classic retail barcode scanner beep (`1760Hz` chirp) and cash register chime on sale.
  - Sub-second product lookup via `/api/v1/products/barcode/{code}` with in-memory fallback.
- [x] **Bilingual Thermal Receipt Printing (Sinhala & English)**:
  - Interactive multi-language switch: `Dual (EN+සිං)`, `සිංහල`, `EN`.
  - Store headers in English & Sinhala (`ස්මාර්ට්ෂොප් වෙළඳසැල / SMARTSHOP POS`).
  - Item lines display English name and Sinhala name (`item.sinhala_name`).
  - Mobile & electronics warranty lines: prints IMEI/Serial number (`SN/IMEI: 3589...`) and warranty period (`🛡️ 1 Year Apple Care Warranty`).
  - Sri Lankan retail metadata labels: බිල්පත් අංකය (Invoice), දිනය (Date), අයකැමි (Cashier), උප එකතුව (Subtotal), වැට් බදු (Tax), මුළු එකතුව (Total), ගෙවූ මුදල (Paid), ඉතිරි මුදල (Change).
  - Cultural blessings and footer: "ස්තූතියි! නැවත එන්න." / "Thank you! Please visit again."
- [x] **Direct ESC/POS Thermal Printing**:
  - Raw binary command generation for 80mm and 58mm thermal rolls.
  - Native cash drawer kickout pulse (`ESC p 0 25 250` on RJ11 pin 2/pin 5).
  - Automated full paper cut command (`GS V 66 0`).
- [x] **Cashier Speed & Shortcuts**:
  - F1 Help cheat sheet overlay, F2 Add Customer, F4 Cloud hold, F8 Cash drawer kick, F9 Checkout.
- [ ] **Dual-Screen Customer Display (VFD / Secondary Monitor)**: (`⏳ PENDING`)
  - Electron multi-window support for pole display / customer-facing monitor.
  - Real-time cart reflection on secondary monitor via IPC broadcast.

### Milestone 1.3: Filament Admin Analytics & ERP Widgets (`✅ COMPLETED`)
- [x] **Dashboard KPI Cards (`StatsOverviewWidget`)**: Gross sales, +% vs yesterday, transaction count, active shifts, low stock alert counter.
- [x] **Daily/Weekly Sales Trend Chart (`SalesChartWidget`)**: Interactive 14-day sales trend and order volume chart.
- [x] **Low Stock Warning Widget (`LowStockWidget`)**: Immediate alert table displaying products at or below safety stock.

### Milestone 1.4: Embedded SQLite Persistence Upgrade (`⏳ PENDING`)
- [ ] **Migration from JSON mock to native SQLite**:
  - Integrate `better-sqlite3` compiled with electron-rebuild in the Electron main process.
  - Local database tables mirroring central catalog and queued transactions.
  - Atomic transaction commits with write-ahead logging (WAL) for corruption resistance during power cuts.

---

## 3. Phase 2: Mobile POS for iPad & iPhone

### Milestone 2.1: Flutter Architecture & Core Setup
- **Framework**: Flutter 3.24+ with Dart 3.
- **State Management**: `flutter_riverpod` with code generation (`riverpod_generator`).
- **Networking**: `dio` with custom interceptors for token refresh and `X-Device-UUID` injection.
- **Local Persistence**: `sqflite` for offline-first catalog and pending sales queue.

### Milestone 2.2: Responsive Adaptive UI
- **Tablet Landscape Layout (iPad / Android Tablet)**:
  - Left pane (60%): Interactive product category bar, search, and grid.
  - Right pane (40%): Live cart summary, customer loyalty badge, line-item quantity controls, and payment button.
- **Phone Portrait Layout (iPhone / Android Phone)**:
  - Floating cart bottom sheet for fast queue-busting on the retail sales floor.
  - Camera-based barcode scanner integration (`mobile_scanner`).

### Milestone 2.3: Mobile Offline Synchronization
- Background delta pull for catalog and customers using server version counters.
- Automatic sales queue flushing upon internet connection detection (`connectivity_plus`).

---

## 4. Engineering Standards & Quality Assurance

1. **Sub-Second Performance**:
   - Barcode scans must resolve to cart additions within `< 15ms`.
   - Offline receipt generation must trigger within `< 100ms` of payment finalization.
2. **Idempotency Guarantee**:
   - Every sales payload must include a unique `transaction_uuid`.
   - Server must never double-charge or double-deduct inventory on network retry.
3. **Audit Trail Immutability**:
   - No stock balance may be modified without an accompanying row in `stock_movements`.
4. **Code Quality & CI**:
   - Laravel: Strict types, Pest/PHPUnit tests (`php artisan test`).
   - Windows POS: Oxlint, TypeScript strict checks (`tsc -b`), Vite build verification.
   - Mobile POS: `flutter analyze`, unit and widget tests.
