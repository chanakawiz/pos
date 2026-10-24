# OmniLuxe Store (`omniluxe-store`) 💎

> **Unified Omnichannel Retail, Desktop POS, Consumer Mobile App & Central ERP Engine**  
> **Target Enterprise Tier**: Flagship Department Stores, Luxury Tech & Boutiques, Multi-Vertical Retail Chains (Smartphones & Tech, Designer Fashion & Haute Couture, Footwear & Sneakers, Luxury Automobili & High-Value Assets)  
> **Commercial Readiness**: Turnkey Solution Ready for Commercial Licensing & Multi-Store Deployment

---

## 🏛️ System Architecture: The 4 Pillars

OmniLuxe Store delivers an integrated multi-channel retail infrastructure with strict persona and channel separation:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                 OMNILUXE STORE UNIFIED RETAIL & ERP ARCHITECTURE            │
├──────────────────────────────────────┬──────────────────────────────────────┤
│       1. ONLINE CONSUMER CHANNELS    │       2. IN-STORE CASHIER POS        │
│       (Web Store + Mobile App)       │       (Dedicated Desktop Terminal)   │
│                                      │                                      │
│  • Customer Sign Up & Sign In        │  • High-throughput cashier lanes     │
│  • OmniLuxe Privilege Digital Card   │  • Cashier PIN quick sign-in (1234)  │
│  • Loyalty Points (Earn & Redeem)    │  • USB & Bluetooth barcode scanner   │
│  • Animated luxury gold splash screen│  • Cash drawer kick & thermal print  │
│  • Omnichannel real-time cart & stock│  • Multi-lane held bills reservation │
│  • Instant SMS E-receipts dispatch   │  • Counter device codes (COUNTER-01) │
├──────────────────────────────────────┴──────────────────────────────────────┤
│                   3. CENTRAL CLOUD ERP & ADMIN PANEL                        │
│                   (Laravel 11 / Filament v3 at /admin)                      │
│                                                                             │
│  • Super Admin (admin@omniluxe.store) & Store Manager (manager@smartshop.com│
│  • Multi-department catalog: Tech, Fashion, Footwear, Luxury Automobili    │
│  • Real-time stock ledger, purchase orders, refunds, and cash sessions      │
│  • RESTful API (Sanctum), offline SQLite sync revisions, and SMS gateway    │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🏗️ Monorepo Structure

```text
pos/
├── apps/
│   ├── windows-pos/             # Dedicated Desktop Cashier POS (Electron + React 18 + TypeScript + Vite + SQLite)
│   ├── mobile-pos/              # Consumer Mobile Shopping App (Flutter + Riverpod + Editorial Light Luxury + SQLite)
│   └── web-store/               # Branded E-Commerce Web Storefront (Laravel 11 Blade + Alpine.js + Editorial Light)
├── backend/
│   └── laravel-api/             # Central ERP Engine + REST API Gateway (/api/v1) + Filament v3 Admin (/admin)
├── documentation/
│   ├── development-plan.md      # Master Phased Implementation & Engineering Milestones
│   ├── flutter-screens-catalog.md # Complete Flutter Screen Catalog, Routes & Providers
│   ├── unified-retail-ecosystem.md # Master Architectural Blueprint & Omnichannel Workflows
│   ├── project-status.md        # Current Project Status & Module Health Dashboard
│   ├── ui-design-and-wireframes.md # Dark Luxe Aesthetics & Screen Specifications
│   ├── database-schema.md       # Full Relational Core Schema (25 migrations, UUIDs, ledgers)
│   ├── api-documentation.md     # Versioned REST API Documentation (/api/v1)
│   ├── offline-sync.md          # Offline-First Sync Protocol & Conflict Resolution
│   └── setup-guide.md           # Developer & Enterprise Production Deployment Guide
└── README.md
```

---

## ⚡ Key Highlights & Capabilities

1. **Consumer Mobile Shopping App (`apps/mobile-pos`)**:
   - Editorial dark luxury aesthetic (`#0A0E17` obsidian canvas, `#10B981` emerald, `#D4AF37` champagne gold).
   - Animated gold monogram medallion splash screen (`SplashScreen`).
   - 5-Tab flagship shopping: **Home** (lifestyle hero, premier brand spotlight), **Explore** (catalog with live filters), **Bag** (real-time subtotal), **Orders** (local SQLite archive & digital receipt viewer), and **VIP Club** (**OmniLuxe Privilege** digital loyalty card, points redemption, customer login/register).
2. **Flagship Web Storefront (`backend/laravel-api` & `apps/web-store`)**:
   - Fast customer self-service with dedicated `/login` and `/register` routes.
   - 100 Welcome loyalty points awarded on registration.
   - Member hub at `/account` displaying the OmniLuxe Privilege digital card and complete order history.
   - Slide-over synchronized cart drawer and verified e-receipt lookup at `/receipt/{invoice}` with phone privacy masking (`077 •••• 567`).
3. **Dedicated In-Store Cashier POS (`apps/windows-pos`)**:
   - Hardware-ready for Windows and macOS touchscreen POS stations.
   - 4-digit quick numeric PIN pad (`1234`) tied to counter device codes (`COUNTER-01`).
   - Hardware barcode scanner listener (`<60ms` keystroke burst) with audio synthesiser feedback.
   - Thermal 80mm & 58mm ESC/POS receipt generation, RJ11 cash drawer pulse, and multi-lane cloud held bills.
4. **Central Cloud ERP & Filament v3 Admin (`/admin`)**:
   - Multi-store catalog management across Apple, Samsung, Sony, Nike, Adidas, Clarks, Studio Ceylon, Ralph Lauren, Toyota, Defender, and BYD.
   - Immutable stock movements ledger tracking all sales, web orders, returns, and write-offs.
   - Role-based access control for Super Admins, Store Managers, Cashiers, and Customers.
5. **Customer Protection & Verified SMS E-Receipts**:
   - Modular SMS driver supporting Notify.lk, Twilio, Dialog, Mobitel, and Mock drivers.
   - Dispatches instant SMS order confirmations and tamper-evident warranty verification links to customers upon payment.

---

## 🚀 Quick Start Guide

### 1. Central Backend & ERP (`backend/laravel-api`)
```bash
cd backend/laravel-api
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate:fresh --seed
php artisan serve --port=8000
```
- Web Storefront: `http://127.0.0.1:8000`
- Central ERP Admin: `http://127.0.0.1:8000/admin` (Sign in as `admin@omniluxe.store` or `manager@smartshop.com`)

### 2. Consumer Mobile App (`apps/mobile-pos`)
```bash
cd apps/mobile-pos
flutter pub get
flutter run -d <simulator_or_device_id>
```

### 3. Dedicated Cashier POS (`apps/windows-pos`)
```bash
cd apps/windows-pos
npm install
npm run dev
# To launch the native Electron station with local SQLite offline durability:
npm run electron:start
```

---

## 🧪 Automated Regression Suites

All components are covered by automated test suites:
- **Laravel Central API & ERP**: 28 passed (330 assertions) (`php artisan test`)
- **Flutter Consumer Mobile App**: 21 passed (`flutter test`)
- **Electron Cashier Terminal**: 41 passed (`npm test`)

---

## 📄 License
Proprietary & Confidential. OmniLuxe Store Omnichannel Retail Solution.
