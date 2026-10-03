# SmartShop POS — Master Engineering Backlog

> **Document Version**: 1.0.0  
> **Last Synchronized**: 2026-09-27  
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
| **API-012** | Comprehensive Feature Test Suite | P0 | `✅ DONE` | 18 automated PHPUnit feature tests with 183 assertions passing cleanly. |
| **API-013** | Bilingual Sinhala & English Catalog Schema | P0 | `✅ DONE` | Database migration `sinhala_name` on products table, API index & barcode lookup support. |
| **API-014** | Smart Items & Mobile Devices Schema | P0 | `✅ DONE` | Warranty periods, serial/IMEI tracking flags on products, and `serial_number` & `warranty_notes` on sale items. |

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
| **WIN-011** | Raw ESC/POS Cash Drawer Pulse | P1 | `✅ DONE` | Send `ESC p 0 25 250` kick code on cash payment finalization and drawer key (F8). |
| **WIN-012** | 80mm & 58mm Thermal Print Engine | P1 | `✅ DONE` | Raw ESC/POS formatter with alignment, bold headers, double-width text, and paper cut. |
| **WIN-013** | Native SQLite Main Process DB | P1 | `⏳ PENDING` | Replace JSON mock storage in Electron main process with `better-sqlite3`. |
| **WIN-014** | Keyboard Shortcut Overlay & Help | P2 | `✅ DONE` | Quick overlay (F1) displaying hotkeys for Cashier operation. |
| **WIN-015** | Hardware Barcode Reader & Audio Synthesizer | P0 | `✅ DONE` | Global USB/Bluetooth HID wedge hook (<60ms inter-key), auto cart add, and 1760Hz audio beep. |
| **WIN-016** | `.env` Configured Multi-Language Architecture | P0 | `✅ DONE` | `VITE_DEFAULT_LANGUAGE=bilingual/si/en`, instant top bar language toggle, adaptive titles. |
| **WIN-017** | Smart Items & Mobile IMEI/Serial Capture | P0 | `✅ DONE` | Serial/IMEI input per cart item, warranty badges, and receipt warranty claim printing. |

---

## Epic 4: Mobile POS for iPad / iPhone (`apps/mobile-pos`) — Phase 2

| Task ID | Task Title | Priority | Status | Description |
| :--- | :--- | :---: | :---: | :--- |
| **MOB-001** | Flutter 3.x Project Scaffolding | P0 | `⏳ PENDING` | Flutter project setup with Material 3, Riverpod, Dio, and responsive screen utility. |
| **MOB-002** | Device Pairing & Cashier Login | P0 | `⏳ PENDING` | QR code store pairing and 4-digit PIN authentication screen. |
| **MOB-003** | Tablet Split-Screen Layout | P0 | `⏳ PENDING` | Landscape 60/40 view with category navigation, product grid, and active cart. |
| **MOB-004** | Phone Portrait Queue-Busting UI | P1 | `⏳ PENDING` | Compact single-column view with camera barcode scanning and floating cart sheet. |
| **MOB-005** | Mobile SQLite Local Storage | P0 | `⏳ PENDING` | Embedded `sqflite` database for catalog caching and offline sales queue. |
| **MOB-006** | Dio Offline Sync Client | P0 | `⏳ PENDING` | Interceptors for auto-headers, background sales push, and delta catalog pull. |
| **MOB-007** | Bluetooth / WiFi Thermal Print | P1 | `⏳ PENDING` | Integration with mobile ESC/POS Bluetooth printers (Star Micronics / Epson). |

---

## Epic 5: Hardware & Peripheral Integrations

| Task ID | Task Title | Priority | Status | Description |
| :--- | :--- | :---: | :---: | :--- |
| **HRD-001** | Standard USB HID Wedge Scanner | P0 | `✅ DONE` | Keyboard buffer listener with rapid input detection `< 50ms`. |
| **HRD-002** | RJ11 Cash Drawer Kick Trigger | P1 | `✅ DONE` | Electron IPC cash drawer handler with ESC/POS pulse generation (pins 2 & 5). |
| **HRD-003** | USB/Network ESC/POS Printer | P1 | `✅ DONE` | Raw printer bridge with header, items, tax, total, and full paper cut commands. |
| **HRD-004** | Dual-Screen Customer Facing Display | P2 | `⏳ PENDING` | Secondary HDMI/VGA display window showing live line items and total due. |
| **HRD-005** | Electronic Weight Scale (RS-232) | P2 | `⏳ PENDING` | Serial port reader for weighed produce items (grams / kilograms). |
