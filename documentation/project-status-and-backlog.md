# SmartShop POS — Project Status, Backlog & Roadmap

> **Document Version**: 1.0.0  
> **Last Updated**: 2026-09-27  
> **Target Platforms**: Windows POS (Electron/React), Backend (Laravel 11 / Filament v3), Mobile POS (Flutter)

---

## 1. Executive Summary & Architecture Status

SmartShop POS is designed as an **offline-first, multi-platform retail management system**. The current priority roadmap focuses on finalizing the **Backend (Laravel API + Filament Admin)** and the **Windows Desktop POS**, followed by the **Mobile POS (Flutter)** as Phase 2.

```text
┌─────────────────────────────────────────────────────────────┐
│                    SMARTSHOP POS SYSTEM                     │
├──────────────────────────────┬──────────────────────────────┤
│      PHASE 1: IMMEDIATE      │       PHASE 2: SECONDARY     │
│   Windows POS & Backend      │           Mobile POS         │
│                              │                              │
│  [Electron + React + TS]     │     [Flutter + Riverpod]     │
│             ▲                │              ▲               │
│             │                │              │               │
│             ▼                │              ▼               │
│  [Laravel 11 REST & Sync]    │    [Offline Sync Engine]     │
│  [Filament v3 Admin Panel]   │    [iPad / iPhone Split-UI]  │
└──────────────────────────────┴──────────────────────────────┘
```

---

## 2. Completed vs. Pending Audit

### 2.1 Backend (`backend/laravel-api`)

| Component | Status | Details |
| :--- | :---: | :--- |
| **Database Migrations** | `COMPLETED` | 24 core tables (stores, devices, users, categories, brands, products, variants, inventory, stock movements, customers, sales, sale_items, payments, refunds, cash_sessions, held_bills, sync_logs, settings). |
| **Authentication & RBAC** | `COMPLETED` | Sanctum tokens, PIN code hashing, Spatie roles (Super Admin, Admin, Manager, Cashier), Device UUID headers. |
| **Core POS Billing Engine** | `COMPLETED` | `BillingService`: idempotent sale creation, inventory reservation/decrement, stock movement ledger. |
| **Offline Sync Engine** | `COMPLETED` | Push `/api/v1/sync/push` (deduplication & stock reconciliation), Pull `/api/v1/sync/pull` (version-based delta update). |
| **Customer CRM & Loyalty API**| `COMPLETED` | Customer CRUD, loyalty point accrual and redemption endpoints. |
| **Refunds Engine API** | `COMPLETED` | `/api/v1/sales/{uuid}/refund` with restock toggle, balance reconciliation, and refund item tracking. |
| **Cash Sessions API** | `COMPLETED` | Register open, close, current session, and X-Report computation with discrepancy tracking. |
| **Held Bills API** | `COMPLETED` | Endpoints `/api/v1/held-bills` (GET, POST, DELETE) for multi-lane queue-busting. |
| **Purchasing & Supplier API** | `COMPLETED` | Supplier CRUD, purchase order drafting, and goods receiving with automatic stock ledger updates. |
| **Analytics & Reporting API** | `COMPLETED` | Endpoints for sales summary, top products, and low stock warnings. |
| **Filament Admin Core** | `COMPLETED` | Panel provider setup, Users, Stores, Devices, Categories, Products, Customers, Sales, Brands resources. |
| **Brand Resource Pages** | `PENDING (CRITICAL)` | `BrandResource.php` exists but missing `ListBrands`, `CreateBrand`, `EditBrand` in `Pages/`, causing a fatal crash. |
| **Filament Missing Resources** | `PENDING` | `CashSessionResource`, `PurchaseResource`, `RefundResource`, `StockMovementResource`, `SupplierResource` exist only as empty directories. |
| **Backend Feature Tests** | `PENDING` | Need automated tests for Held Bills, Purchases, and Reports controllers. |
| **Admin Dashboard Widgets** | `PENDING` | Filament charts for daily sales trends, low stock alerts, active register sessions. |

---

### 2.2 Windows POS App (`apps/windows-pos`)

| Component | Status | Details |
| :--- | :---: | :--- |
| **Electron & React Shell** | `COMPLETED` | Electron 34 + React 18 + Vite + Tailwind CSS + Lucide icons. |
| **Authentication Screen** | `COMPLETED` | Email/password & quick PIN pad login, user role display, active store detection. |
| **Catalog & Product Grid** | `COMPLETED` | Category navigation bar, fast search, barcode auto-detection, responsive item grid. |
| **Cart & Quick Actions** | `COMPLETED` | Line-item quantities, discounts (percentage & fixed), tax calculation, clear cart, hold cart. |
| **Customer CRM Modal** | `COMPLETED` | Customer lookup, quick customer registration, loyalty points application to cart. |
| **Multi-Payment Modal** | `COMPLETED` | Cash calculation (change due), card, bank transfer, split payments, order finalization. |
| **Receipt Modal & Print** | `COMPLETED` | Modal receipt preview, HTML print trigger via Electron IPC. |
| **Cash Session Shift Modal** | `COMPLETED` | Opening float input, session balance overview, closing register flow. |
| **Refund Processing Modal** | `COMPLETED` | Search invoice, select line items to return, restock checkbox, refund calculation. |
| **Background Sync Daemon** | `COMPLETED` | Periodic ping, offline queue push, catalog delta pull, sync status modal. |
| **Cloud Held Bills Sync** | `PENDING` | Wire `HoldBillsModal.tsx` to backend `/api/v1/held-bills` API instead of local in-memory only. |
| **Shift X-Report / Z-Report UI**| `PENDING` | Connect `CashSessionModal` to `/api/v1/cash-sessions/x-report` to view and print cashier shift reports. |
| **Direct ESC/POS Hardware** | `PENDING` | Direct ESC/POS printing (cutter commands, RJ11 drawer kick pulse `ESC p 0 25 250`, 80mm/58mm thermal templates). |
| **Local SQLite Migration** | `PENDING` | Migrate Electron main process from mock JSON storage to native embedded SQLite (`better-sqlite3`). |

---

### 2.3 Mobile POS App (`apps/mobile-pos`)

| Component | Status | Details |
| :--- | :---: | :--- |
| **Project Setup** | `PENDING` | Flutter project initialization, dependencies (Dio, Riverpod, sqflite, flutter_screenutil). |
| **Responsive Tablet UI** | `PENDING` | Split-view for iPad/tablets (catalog on left, cart on right) and single-column for phones. |
| **Offline SQLite Engine** | `PENDING` | `sqflite` database schema matching central catalog and offline sales queue. |
| **Sync Client** | `PENDING` | Dio interceptor with token and device UUID, background sync worker. |

---

## 3. Master Backlog & Action Items

### Sprint 1: Critical Bug Fixes & Backend Completeness (Current Sprint)

- [x] **TASK-B01**: Fix `BrandResource` fatal crash by creating `ListBrands.php`, `CreateBrand.php`, and `EditBrand.php`.
- [x] **TASK-B02**: Implement `SupplierResource` in Filament (Vendor details, phone, email, tax ID, active state).
- [x] **TASK-B03**: Implement `PurchaseResource` in Filament (Purchase orders, receiving line items, updating stock).
- [x] **TASK-B04**: Implement `CashSessionResource` in Filament (Cash register shifts, opening/closing floats, discrepancy audit).
- [x] **TASK-B05**: Implement `RefundResource` in Filament (Customer refunds audit, refunded items list, restocked flags).
- [x] **TASK-B06**: Implement `StockMovementResource` in Filament (Read-only audit ledger of all inventory transactions).
- [x] **TASK-B07**: Add automated feature tests:
  - `HeldBillTest.php`
  - `PurchaseTest.php`
  - `ReportTest.php`
- [x] **TASK-B08**: Verify all Laravel tests pass cleanly (`php artisan test` — 18 passed, 183 assertions).

---

### Sprint 2: Windows POS Enhancements & API Integrations

- [x] **TASK-W01**: Connect `HoldBillsModal.tsx` and `Cart.tsx` to backend `/api/v1/held-bills`:
  - Fetch held bills from backend on modal open.
  - Save held bills to backend on Hold (F4) so any lane can resume the sale.
  - Delete held bill from backend when resumed or discarded.
- [x] **TASK-W02**: Cashier Shift X-Report / Z-Report in `CashSessionModal.tsx`:
  - Live shift summary from `/api/v1/cash-sessions/x-report`.
  - Display breakdown: Opening float, Cash sales, Card sales, Refunds, Expected cash in drawer.
  - Action button to print formal thermal X-Report or Z-Report.
- [ ] **TASK-W03**: ESC/POS Hardware Printing Enhancements:
  - Add drawer kick code support on cash sale completion.
  - Optimize receipt layout for 80mm and 58mm thermal printers.
- [ ] **TASK-W04**: UI Polish & Notifications:
  - Add toast feedback on sync events, held bill actions, and session closures.
  - Ensure keyboard shortcuts (`F1` Help, `F2` New Sale, `F4` Hold Bill, `F8` Cash Drawer, `F9` Pay, `Esc` Cancel) are responsive.

---

### Sprint 3: Filament Dashboard Analytics & Widgets

- [ ] **TASK-F01**: Add Sales Overview Chart widget (daily / weekly gross revenue).
- [ ] **TASK-F02**: Add Low Stock Alerts widget (products below `min_stock_level`).
- [ ] **TASK-F03**: Add Active Cash Register Sessions widget.

---

### Sprint 4: Mobile POS (Flutter — Phase 2 Plan)

- [ ] **TASK-M01**: Scaffold Flutter app in `apps/mobile-pos` with Dart 3, Material 3, and Riverpod.
- [ ] **TASK-M02**: Implement tablet landscape split-screen layout (Catalog + Cart).
- [ ] **TASK-M03**: Implement local SQLite offline database and Dio sync engine.
- [ ] **TASK-M04**: Device pairing and cashier PIN login screens.

---

## 4. UI Specifications & Wireframe Concepts

### 4.1 Windows POS: Cloud Held Bills Modal
```text
┌─────────────────────────────────────────────────────────────┐
│ 🛒 Held Transactions (Multi-Lane Cloud Sync)            [✕] │
├─────────────────────────────────────────────────────────────┤
│  HOLD REF       CASHIER       ITEMS   AMOUNT   HELD AT      │
│ ─────────────────────────────────────────────────────────── │
│  HLD-2026-001   Sarah Miller    4     $62.50   14:20 (12m)  │ [Resume] [✕]
│  HLD-2026-002   Alex Tan        2     $18.00   14:28 (4m)   │ [Resume] [✕]
│  HLD-2026-003   Self-Checkout   7    $114.20   14:31 (1m)   │ [Resume] [✕]
├─────────────────────────────────────────────────────────────┤
│ Total 3 bills on hold across store registers.               │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 Windows POS: Cashier Shift X-Report / Z-Report
```text
┌─────────────────────────────────────────────────────────────┐
│ 🧾 Register Shift Report (Lane 01 — Terminal #1)        [✕] │
├─────────────────────────────────────────────────────────────┤
│ Cashier: Sarah Miller      Opened: 2026-09-27 08:30:00       │
│ Status: OPEN (Mid-Shift X-Report)                           │
│ ─────────────────────────────────────────────────────────── │
│ Opening Cash Float:                                $ 150.00 │
│ + Cash Sales (24 transactions):                    $ 685.50 │
│ + Card / Digital Sales (18 transactions):          $ 420.00 │
│ - Cash Refunds (1 transaction):                   -$  25.00 │
│ ─────────────────────────────────────────────────────────── │
│ Expected Cash in Drawer:                           $ 810.50 │
│ Total Register Gross:                            $ 1,230.50 │
├─────────────────────────────────────────────────────────────┤
│ [ 🖨️ Print X-Report ]   [ Close Register & Generate Z-Report ] │
└─────────────────────────────────────────────────────────────┘
```

---

## 5. Progress Tracking Guide for AI & Developers

When picking up work from this backlog:
1. Locate the Task ID in Section 3 (e.g., `TASK-B01`).
2. Mark the status as `[/] In Progress` while working.
3. Once completed and tested, update the checkbox to `[x]` and document any pertinent changes.
