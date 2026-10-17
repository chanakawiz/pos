# SmartShop POS 🛒

> **Enterprise-Grade, Offline-First Point of Sale & Retail Management System**

SmartShop POS is a multi-platform retail solution designed for modern stores, supermarkets, and franchises. It supports desktop cashier stations on Windows, mobile POS on iPads/iPhones, centralized inventory/store management with a Laravel 11 backend, and an offline-first synchronization engine that guarantees zero lost sales during network outages.

---

## 🏗️ Monorepo Architecture

```text
pos/
├── apps/
│   ├── windows-pos/             # Electron + React + TypeScript + Vite + Tailwind + SQLite
│   └── mobile-pos/              # Flutter + Material 3 + SQLite + Dio + Riverpod
├── backend/
│   └── laravel-api/             # Laravel 11 REST API + Filament Admin Dashboard + MySQL
├── documentation/
│   ├── architecture.md          # Comprehensive system architecture & data flow
│   ├── database-schema.md       # Full database dictionary (24 tables, UUIDs, indexes)
│   ├── api-documentation.md     # Versioned REST API documentation (/api/v1)
│   ├── offline-sync.md          # Offline-first sync protocol & conflict resolution
│   └── setup-guide.md           # Developer & production setup guide
└── README.md
```

---

## ⚡ Key Highlights

1. **Multi-Platform Cashier Terminals**:
   - **Windows Desktop**: Electron, React 18, Tailwind CSS, TypeScript, Zustand, and local SQLite for instant, sub-second billing.
   - **iPad / iPhone**: Flutter, Material 3, and local SQLite for mobile floor sales and queue busting.
2. **True Offline-First Resilience**:
   - Bills are saved locally in SQLite with unique UUIDs.
   - Automatic background synchronization when the network reconnects.
   - Idempotent API prevents duplicate sales, double-charging, or duplicate inventory deductions.
3. **Robust Laravel 11 Backend**:
   - Sanctum token authentication & Spatie role-based access control (Super Admin, Admin, Manager, Cashier).
   - Real-time stock movement ledger (audit-trail for every single stock in/out/damage/sale/refund).
   - Filament Admin Dashboard for catalog, inventory, devices, cash registers, and analytics.
4. **Hardware Integrations**:
   - 80mm & 58mm thermal receipt printing, ESC/POS preparation.
   - Barcode scanners (HID wedge mode & serial).
   - Cash drawer kick-out triggers upon cash finalization.

---

## 🚀 Quick Start

For detailed step-by-step setup instructions, refer to [`documentation/setup-guide.md`](documentation/setup-guide.md).

### 1. Backend (Laravel API + Filament Admin)
```bash
cd backend/laravel-api
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan serve
```

### 2. Windows POS Terminal (Electron + React)
```bash
cd apps/windows-pos
npm install
npm run dev
```
For the native terminal, configure `VITE_DEVICE_UUID` from a registered store device, then run `npm run build:electron` and `npm run electron:start` in a second terminal. SQLite/offline checkout requires Electron; see the [desktop README](apps/windows-pos/README.md).

---

## 📚 Documentation & Engineering Blueprints
- [Master Development Plan (Phase 1 & Phase 2)](documentation/development-plan.md)
- [Master Engineering Backlog (Task IDs & Statuses)](documentation/backlog.md)
- [Current Project Status & Module Audit](documentation/project-status.md)
- [UI Design & Wireframe Specifications](documentation/ui-design-and-wireframes.md)
- [System Architecture Specification](documentation/architecture.md)
- [Database Schema & Data Dictionary](documentation/database-schema.md)
- [REST API Specification](documentation/api-documentation.md)
- [Offline-First Sync Engine Specification](documentation/offline-sync.md)
- [Installation & Setup Guide](documentation/setup-guide.md)

---

## 📄 License
Proprietary & Confidential. Built for enterprise retail deployment.
