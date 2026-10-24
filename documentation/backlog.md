# SmartShop POS — Master Engineering Backlog

> **Document Version**: 1.0.0
> **Last Synchronized**: 2026-10-18
> **Execution Status**: Active
> **Legend**: `✅ DONE` = Work Completed & Verified | `⏳ PENDING` = Work Pending Implementation | `🔄 IN PROGRESS` = Currently Active

---

## Epic 1: Backend API & Synchronization Engine (`backend/laravel-api`)

| Task ID | Task Title | Priority | Status | Description |
| :--- | :--- | :---: | :---: | :--- |
| **API-001** | Database Schema & Migrations | P0 | `✅ DONE` | 24 relational tables with UUIDv4, soft deletes, foreign keys, and indexes. |
| **API-002** | Sanctum Auth & Device Verification | P0 | `✅ DONE` | Cashier PIN / password login, token issuance, and device UUID verification. |
| **API-003** | Core Billing & Inventory Ledger | P0 | `✅ DONE` | `BillingService`: idempotent checkout, stock deduction, and movement audit logs. |
| **API-004** | Offline Push Synchronization | P0 | `✅ DONE` | Batch push `/api/v1/sync/push` with deduplication and conflict-free processing. |
| **API-005** | Versioned Delta Pull Sync | P0 | `✅ DONE` | Delta pull `/api/v1/sync/pull` fetching catalog records changed since local version. |
| **API-006** | Customer CRM & Loyalty Accrual | P1 | `✅ DONE` | Customer search, CRUD, point accrual, and point redemption endpoints. |
| **API-007** | Refund & Restock Engine | P1 | `✅ DONE` | Invoice line-item refund processing with restock option and ledger update. |
| **API-008** | Cash Session & X-Report Engine | P1 | `✅ DONE` | Cash register shifts, opening/closing floats, discrepancy audit, and X-Report API. |
| **API-009** | Multi-Lane Cloud Held Bills | P1 | `✅ DONE` | Endpoints `/api/v1/held-bills` (GET, POST, DELETE) for persistent multi-register hold. |
| **API-010** | Purchasing & Goods Receiving | P1 | `✅ DONE` | Supplier PO drafting and `/api/v1/purchases/{uuid}/receive` stock receiving. |
| **API-011** | Sales & Inventory Analytics API | P1 | `✅ DONE` | Sales summary by period, top selling products, and low stock warnings. |
| **API-012** | Comprehensive Feature Test Suite | P0 | `✅ DONE` | 28 automated tests (281 assertions on local MySQL / 239 on isolated SQLite), including global revisions, stock invalidation, deletion propagation, store authorization, offline tax snapshots, and fractional sale/refund/stock precision. |
| **API-013** | Bilingual Sinhala & English Catalog Schema | P0 | `✅ DONE` | Database migration `sinhala_name` on products table, API index & barcode lookup support. |
| **API-014** | Smart Items & Mobile Devices Schema | P0 | `✅ DONE` | Warranty periods, serial/IMEI tracking flags on products, and `serial_number` & `warranty_notes` on sale items. |
| **API-015** | Durable Catalog Sync Revisions | P0 | `✅ DONE` | Transactional global revision sequence, inventory invalidation, soft/permanent deletion tombstones, and complete bilingual/warranty catalog payloads. |
| **API-016** | Docker Containerization Stack | P0 | `✅ DONE` | Full Docker Compose orchestration: PHP 8.2-FPM with all extensions, Nginx reverse proxy, MySQL 8.0 with healthcheck, and background queue worker. |

---

## Epic 2: Filament v3 Admin ERP Dashboard

| Task ID | Task Title | Priority | Status | Description |
| :--- | :--- | :---: | :---: | :--- |
| **FIL-001** | Panel Provider Configuration | P0 | `✅ DONE` | Theme, navigation groups, brand logo, and authentication guard setup. |
| **FIL-002** | Stores & Device Management | P1 | `✅ DONE` | Store branch details, terminal registration, and pairing management. |
| **FIL-003** | User Management & Spatie Roles | P1 | `✅ DONE` | User accounts with Super Admin, Admin, Manager, and Cashier permissions. |
| **FIL-004** | Product Catalog & Sinhala Naming Resource | P0 | `✅ DONE` | Products CRUD with English + Sinhala names, Brand/Category selects, barcode scanner helper, pricing & initial stock. |
| **FIL-005** | Brand Resource Management | P0 | `✅ DONE` | BrandResource with ListBrands, CreateBrand, EditBrand pages, slug auto-generation, and logo upload. |
| **FIL-006** | Supplier Directory Resource | P1 | `✅ DONE` | Vendor profiles, contact details, tax identification, and payment terms. |
| **FIL-007** | Purchase Order Resource | P1 | `✅ DONE` | PO management with dynamic line items repeater, unit cost, and receiving status. |
| **FIL-008** | Cash Register Sessions Resource | P1 | `✅ DONE` | Shift overview, opening/closing floats, discrepancy highlight, and terminal mapping. |
| **FIL-009** | Customer Refunds Resource | P1 | `✅ DONE` | Refund tracking, associated invoice links, cash refund amount, and restocked status. |
| **FIL-010** | Stock Movement Ledger Resource | P1 | `✅ DONE` | Immutable audit log displaying every inventory delta, before/after values, and ref IDs. |
| **FIL-011** | Dashboard KPI Metric Cards | P2 | `✅ DONE` | Real-time widgets for daily gross revenue, active registers, and open PO count. |
| **FIL-012** | Daily Revenue Chart Widget | P2 | `✅ DONE` | Graphical 14-day sales and transaction volume trend visualization. |
| **FIL-013** | Low Stock Warning Widget | P2 | `✅ DONE` | Immediate alert table showing items under minimum stock safety threshold. |
| **FIL-014** | Inventory Stock Adjustment Resource | P0 | `✅ DONE` | InventoryResource with branch filtering, English/Sinhala product descriptions, and stock level badges. |

---

## Epic 3: Windows Desktop POS Terminal (`apps/windows-pos`)

| Task ID | Task Title | Priority | Status | Description |
| :--- | :--- | :---: | :---: | :--- |
| **WIN-001** | Electron & React 18 Shell | P0 | `✅ DONE` | Electron main process, secure preload bridge, Vite, and Tailwind dark theme. |
| **WIN-002** | Cashier Auth & PIN Pad Screen | P0 | `✅ DONE` | Rapid numeric PIN pad and standard password login with persistent token store. |
| **WIN-003** | High-Speed Catalog & Cart Engine | P0 | `✅ DONE` | Sub-second item addition, quantity updates, line discounts, and bill discount. |
| **WIN-004** | Customer CRM & Loyalty Modal | P1 | `✅ DONE` | Instant customer lookup by phone, rapid customer creation, and loyalty redemption. |
| **WIN-005** | Multi-Payment Checkout Modal | P0 | `✅ DONE` | Cash with change calculator, Card, Bank transfer, split tenders, and receipt print. |
| **WIN-006** | Bilingual Sinhala & English Thermal Receipt | P0 | `✅ DONE` | Interactive switch (Dual EN+සිං / සිංහල / EN), Sinhala headers, items, labels & ESC/POS buffer. |
| **WIN-007** | Shift Cash Session & X-Report | P1 | `✅ DONE` | Opening float input, mid-shift live balance view, X-Report print, and shift closing. |
| **WIN-008** | Multi-Lane Cloud Held Bills | P1 | `✅ DONE` | F4 key hold to cloud, shared cross-lane bill list, one-click resume and discard. |
| **WIN-009** | Refund Processing Modal | P1 | `✅ DONE` | Invoice lookup, item selection, return quantities, restock toggle, and refund trigger. |
| **WIN-010** | Background Sync Daemon | P0 | `✅ DONE` | Network health ping, queued sales push, delta pull, and visual sync indicator. |
| **WIN-011** | Raw ESC/POS Cash Drawer Pulse | P1 | `✅ DONE` | Configured-pin pulse delivery through serialized TCP/Windows RAW transports, F8/cash-checkout integration, and visible errors. Software verified with a local TCP receiver; physical checks tracked in HRD-002. |
| **WIN-012** | 80mm & 58mm Thermal Print Engine | P1 | `✅ DONE` | Dedicated width-aware raster receipts, bundled Sinhala font, sale/refund/X/Z layouts, cutter controls, and failure feedback. Electron/TCP software tests pass; target checks remain in HRD-003. |
| **WIN-013** | Native SQLite Main Process DB | P1 | `✅ DONE` | `better-sqlite3` with WAL/FULL durability, atomic sales/items/payments, scoped catalog checkpoints, legacy import, offline checkout, and recovery tests. |
| **WIN-014** | Keyboard Shortcut Overlay & Help | P2 | `✅ DONE` | Quick overlay (F1) displaying hotkeys for Cashier operation. |
| **WIN-015** | Hardware Barcode Reader & Audio Synthesizer | P0 | `✅ DONE` | Global USB/Bluetooth HID wedge hook (<60ms inter-key), auto cart add, and 1760Hz audio beep. |
| **WIN-016** | `.env` Configured Multi-Language Architecture | P0 | `✅ DONE` | `VITE_DEFAULT_LANGUAGE=bilingual/si/en`, instant top bar language toggle, adaptive titles. |
| **WIN-017** | Smart Items & Mobile IMEI/Serial Capture | P0 | `✅ DONE` | Serial/IMEI input per cart item, warranty badges, and receipt warranty claim printing. |

---

## Epic 4: Mobile POS for iPad / iPhone (`apps/mobile-pos`) — Phase 2

| Task ID | Task Title | Priority | Status | Description |
| :--- | :--- | :---: | :---: | :--- |
| **MOB-001** | Flutter 3.x Project Scaffolding | P0 | `✅ DONE` | Flutter 3.27+ project setup with Material 3, Riverpod 2.6, Dio 5.11, and responsive design tokens. |
| **MOB-002** | Device Pairing & Cashier Login | P0 | `✅ DONE` | 3x4 numeric PIN pad, password login, quick session init, and stable device UUID pairing. |
| **MOB-003** | Tablet Split-Screen Layout | P0 | `✅ DONE` | Adaptive 60/40 landscape view with category filter chips, search, product grid, and fixed cart panel. |
| **MOB-004** | Phone Portrait Queue-Busting UI | P1 | `✅ DONE` | Compact single-column view with live camera barcode scanner and floating cart bottom sheet. |
| **MOB-005** | Mobile SQLite Local Storage | P0 | `✅ DONE` | Embedded `sqflite` WAL database for products, categories, customers, and atomic `offline_sales` queue. |
| **MOB-006** | Dio Offline Sync Client | P0 | `✅ DONE` | Background sales push to `/api/v1/sync/push` and delta catalog pull from `/api/v1/sync/pull`. |
| **MOB-007** | Network / WiFi Thermal Print & Cash Drawer | P1 | `✅ DONE` | ESC/POS binary engine, raw TCP socket (port 9100), 80mm/58mm column formatting, pin 2/5 drawer kick, and in-app simulator. |
| **MOB-008** | Sales History & Receipt Reprint | P1 | `✅ DONE` | Recent transactions list with invoice/customer search, sync status filters (All/Synced/Pending), line items bottom sheet, and instant reprinting. |
| **MOB-009** | Cash Register Shift Audit & X-Report | P1 | `✅ DONE` | Mid-shift cash audit dialog, cash-in-drawer tally, tender breakdowns (Cash/Card/Bank), manual drawer kick, and ESC/POS X-Report printing. |
| **MOB-010** | Multi-Lane Cloud Held Bills Sync | P1 | `✅ DONE` | Cross-register hold and recall via `/api/v1/held-bills` with local SQLite fallback for aisle queue-busting. |
| **MOB-011** | Quick Customer Registration & CRM | P1 | `✅ DONE` | In-cart rapid customer creation dialog with auto-sync to `/api/v1/customers` and immediate cart attachment. |

---

## Epic 5: Hardware & Peripheral Integrations

| Task ID | Task Title | Priority | Status | Description |
| :--- | :--- | :---: | :---: | :--- |
| **HRD-001** | Standard USB HID Wedge Scanner | P0 | `✅ DONE` | Keyboard buffer listener with rapid input detection `< 50ms`. |
| **HRD-002** | RJ11 Cash Drawer Kick Trigger | P1 | `🔄 IN PROGRESS` | TCP and Windows RAW transport implemented; configured-pin bytes verified against a mock receiver. Actual drawer pin/timing/operation still requires target hardware. |
| **HRD-003** | USB/Network ESC/POS Printer | P1 | `🔄 IN PROGRESS` | Real TCP delivery and Windows RAW spooler path implemented. 58/80mm raster rendering is tested; Windows spooler execution and physical output/cutter validation remain. |
| **HRD-004** | Dual-Screen Customer Facing Display | P2 | `✅ SOFTWARE DONE` | Isolated secondary window, live bilingual cart/totals, safe monitor selection/hotplug, and persisted pause/resume. Physical Windows dual-monitor acceptance remains; see [setup](customer-display.md). |
| **HRD-005** | Electronic Weight Scale (RS-232) | P2 | `✅ SOFTWARE DONE` | Explicit A&D serial protocols, stable/fresh capture, kg/g conversion, reweighing, and three-decimal quantity persistence/sync/refunds. Actual model/Windows adapter acceptance remains; see [setup](weighing-scales.md). |


## 2026-10-17 continuation

Completed WIN-013 and the API-015 prerequisite. Desktop payment now commits locally before showing a receipt, and the background worker retries the same transaction UUID. Catalog records and their checkpoint commit together. Failed writes, partial acknowledgements, and invalid legacy data remain visible rather than being reported as successful.

Verification: `npm run build:all`, `npm test` (13 native Electron tests), backend suite (24 tests; 257 assertions on local MySQL and 215 on isolated seeded SQLite), the UI failure/retry/reload/reconnect smoke test, and unsigned macOS arm64 packaging. See the desktop README for the UI smoke test command. Windows installer execution and physical power-cut/hardware testing still require the target equipment.

The follow-up below implements printer/drawer transport. Remaining Phase 1 items include physical peripheral/secondary-monitor validation (HRD-002/HRD-003/HRD-004) and electronic scales (HRD-005). Mobile remains Phase 2.


## 2026-10-17 printing continuation

Completed WIN-011/WIN-012 software implementation: real TCP and Windows RAW spooler transports, main-process printer configuration, serialized jobs, configured drawer pin, 58/80mm receipt rasterization, bundled Sinhala shaping, and dedicated sale/refund/X/Z documents. Print failures stay separate from completed sales and shift closure. Uncertain writes are never automatically retried and cancel already queued follow-up jobs.

Verified 27 Electron tests, the cashier UI smoke test with a real renderer/local TCP receiver, and an unsigned macOS arm64 package containing the font, OFL license, and PNG decoder. Long 58mm output spans capture tiles and was visually inspected. Physical hardware and Windows spooler execution remain unverified, so HRD-002/HRD-003 remain in progress. See [receipt printing setup](receipt-printing.md).


## 2026-10-17 customer-display continuation

Completed HRD-004 software: a separate sandboxed customer renderer receives a validated public cart projection over IPC, supports English/Sinhala/bilingual output with the bundled font, and clears on cart completion/logout/cashier reload or shutdown. Monitor selection excludes cashier overlap and mirrored layouts; hotplug and bounds changes reconcile placement. F1 provides status and persistent pause/resume.

Verification: 30 native Electron tests, the expanded cashier/customer GUI smoke suite, desktop build, lint (seven existing warnings), and screenshot inspection. Physical Windows monitor/DPI/focus/hotplug acceptance remains open; see [customer-display.md](customer-display.md).


## 2026-10-18 weighing-scale continuation

Implemented HRD-005 software with an explicitly configured main-process SerialPort reader, bounded CRLF framing, strict A&D balance/indicator parsers, fresh stable-reading capture, wrong-unit/type rejection, visible failures, and port lifecycle handling. kg/g catalog products open a capture dialog from clicks or barcode lookup; reweighing replaces the quantity. No scale is assumed or opened without configuration.

Added the required three-decimal quantity migration, model/API/admin updates, fractional refund entry, and offline quantity validation. Applied the additive migration to local MySQL. Verification covers native serial/mocked-stream tests, fractional SQLite persistence/sync, backend sale/refund/idempotency/rollback tests on SQLite and MySQL, and the expanded GUI smoke flow. Physical scale/Windows peripheral acceptance remains open; see [weighing-scales.md](weighing-scales.md).


## 2026-10-24 mobile-pos continuation

Completed Phase 2 Mobile POS (`apps/mobile-pos`) scaffolding and implementation across MOB-001 through MOB-009:
## Epic 4: Consumer Mobile Shopping App (`apps/mobile-pos`) — Phase 2 & 3

> **Strategic Architectural Alignment**: The mobile application is now the **Consumer Mobile Shopping App** (matching the web storefront experience), providing a flagship lifestyle mobile store for retail customers. In-store cashier and point-of-sale checkout operations are strictly dedicated to the Windows / macOS Desktop POS terminal.

- Consumer Store Scaffolding & Design System (`MOB-001`): Flutter 3.27+, Material 3 dark luxury aesthetic (`#0A0E17`), Riverpod 2.6 state management, and Google Fonts (Outfit & Inter).
- Flagship Lifestyle Home Screen (`MOB-002`): Hero lifestyle collection showcase banner, Premier Brand Spotlight bar (Apple, Nike, Toyota, Studio Ceylon, Zara, etc.), Department Quick Access grid, and Curated Highlights.
- Interactive Catalog & Instant Search (`MOB-003`): 2-column luxury product cards, debounced live text search, department filter chips, stock status badges, and warranty pills.
- Product Detail & Variant Selector (`MOB-004`): Full media preview container, brand tags, variant matrix (S/M/L, UK 7-11, 128GB-1TB), warranty and authenticity guarantees, and "Add to Bag" / "Buy Now" actions.
- Interactive Shopping Bag (`MOB-005`): Dynamic item counter badge, quantity adjustment steppers, item deletion, subtotal calculation, and complimentary packaging.
- Customer Checkout & Fulfillment (`MOB-006`): Recipient details (Name, Mobile for SMS e-receipt, Email), Express Delivery vs Flagship Click-and-Collect, Card vs COD tender, and atomic stock reservation.
- Order Confirmation & E-Receipts Archive (`MOB-007`): Verified order confirmation badge, order number (`ORD-XXXX`), SMS dispatch notice, verifiable public link (`http://127.0.0.1:8000/receipt/{invoice}`), and local SQLite orders archive.
- Animated Luxury Splash Screen (`MOB-008`): Pulsing gold monogram medallion, luxury tagline, and smooth transition to StoreMainScreen.
- VIP Member Loyalty Card & Auth (`MOB-009`): Gold-trimmed digital membership card with 350 PTS, credit limit, Sign In & Sign Up tabbed view, and instant demo login.

Verification: `flutter analyze` passes with 0 issues; `flutter test` passes with 21 automated unit and widget tests covering catalog filtering, barcode lookup, offline queue, sync versioning, mock ESC/POS printing, X-Report generation, drawer kicks, sales history querying, and consumer store app launch.

---

## Epic 5: Customizable E-Commerce Web Storefront (`apps/web-store` & `backend/laravel-api`)

> **Design Reference**: Inspired by the clean, luxury editorial aesthetic of `store_web` on Desktop, now integrated as a unified first-class application in the monorepo.

| Task ID | Task Title | Priority | Status | Description |
| :--- | :--- | :---: | :---: | :--- |
| **WEB-001** | E-Commerce Storefront Architecture & Routing | P0 | `✅ DONE` | Public storefront layer connected to the central Laravel API and database (`/` & `/shop`). |
| **WEB-002** | Multi-Vertical Customizable Themes | P0 | `✅ DONE` | Dynamic theme configuration for Designer Fashion, Tech/Smartphones (Specs & IMEI lookup), Footwear (Size matrix), and Automobili/Vehicles. |
| **WEB-003** | Product Catalog, Filters & Lookbooks | P0 | `✅ DONE` | Category, brand, size, price, and stock filters with image galleries and pristine international flagship names. |
| **WEB-004** | Shopping Bag & Stock Reservation | P0 | `✅ DONE` | Persistent session bag, quantity controls, and atomic stock reservation preventing overselling. |
| **WEB-005** | Checkout Engine & Payment Adapters | P0 | `✅ DONE` | Cash on Delivery (COD) and Card checkout integration with signed callback verification. |
| **WEB-006** | Real-Time POS & Storefront Inventory Sync | P0 | `✅ DONE` | Instant two-way stock synchronization between in-store POS checkouts and web purchases. |
| **WEB-007** | Public Digital SMS E-Receipt Page | P0 | `✅ DONE` | Verified digital tax invoice at `/receipt/{invoice}` with customer privacy phone masking. |
| **WEB-008** | Customer Web Sign In & Sign Up | P0 | `✅ DONE` | Dedicated luxury `/login` and `/register` views with automatic 100 welcome bonus loyalty points. |
| **WEB-009** | Customer Account & Order History Hub | P0 | `✅ DONE` | Dedicated `/account` dashboard with digital VIP membership card, loyalty points value, and digital receipt links. |

---

## Epic 6: Customer Protection, Privacy & SMS E-Receipts Gateway

| Task ID | Task Title | Priority | Status | Description |
| :--- | :--- | :---: | :---: | :--- |
| **SEC-001** | Screen-Level Customer Privacy Masking | P0 | `✅ DONE` | Mask customer phone numbers (e.g. `077 **** 567`) in checkout and queue displays to prevent shoulder-surfing. |
| **SEC-002** | SMS E-Receipt Service Architecture | P0 | `✅ DONE` | `SmsService` driver architecture supporting digital bill generation, thank-you messages, and receipt links. |
| **SEC-003** | Checkout SMS Bill Toggle & Mobile Capture | P0 | `✅ DONE` | Toggle switch in POS `PaymentDialog` with customer mobile input and automatic e-receipt dispatch. |
| **SEC-004** | SMS Gateway Provider Integrations | P1 | `⏳ PENDING` | Live API driver connectors for Notify.lk, Twilio, Dialog, and Mobitel (gateway credentials can be configured per merchant). |
| **SEC-005** | Customer Data Protection & GDPR Compliance | P1 | `✅ DONE` | Cryptographic data hashing for customer ledgers and phone masking on public receipt capabilities. |

---

## Epic 7: Turnkey Multi-Vertical Commercial Packaging (For Selling to Business Owners)

> **Commercial Objective**: A complete, white-label, production-grade retail software suite ready to be deployed, branded, and sold to established retail enterprises (Smartphones & Tech, Designer Fashion & Apparel, Footwear & Sneakers, Luxury Automotive Dealerships).

| Task ID | Task Title | Priority | Status | Description |
| :--- | :--- | :---: | :---: | :--- |
| **TRN-001** | Multi-Vertical Master Catalog Seeder | P0 | `✅ DONE` | Comprehensive demo catalog seeding Apple/Samsung tech (IMEI), Studio Ceylon/Zara clothing, Nike/Adidas shoes, Toyota/Defender vehicles (VIN), removing grocery items for a premier flagship profile. |
| **TRN-002** | Single-Engine Unified Runtime | P0 | `✅ DONE` | Port 8000 serves E-Commerce Storefront + Filament ERP Admin Panel + POS REST API from a single database. |
| **TRN-003** | Standalone Web Storefront Runtime | P0 | `✅ DONE` | Independent web store running on Port 8010 with dedicated PayHere checkout and admin control room. |
| **TRN-004** | Merchant Onboarding & Deployment Blueprint | P0 | `✅ DONE` | Step-by-step documentation for packaging, customizing store name/branding, and delivering to commercial clients. |


