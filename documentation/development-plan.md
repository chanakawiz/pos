# OmniLuxe Store Unified Omnichannel Retail & ERP Ecosystem — Master Development Plan

> **System**: OmniLuxe Store (`omniluxe-store`) — Flagship Omnichannel Retail, Desktop POS & Central ERP Engine  
> **Document**: Phased Implementation & Engineering Milestones Roadmap  
> **Target Personas & Channels**:
> 1. **Online Shoppers**: OmniLuxe Web Storefront (`backend/laravel-api` & `apps/web-store`) + Mobile Shopping App (`apps/mobile-pos`)
> 2. **In-Store Cashiers**: Dedicated High-Throughput Counter POS Terminal (`apps/windows-pos`)
> 3. **Admins & Store Managers**: Central ERP & Filament v3 Control Room (`/admin`)  
> **Aesthetic Theme**: Luxury Editorial Dark (Obsidian `#0A0E17`, Deep Slate `#111827`, Hairline `#223048`, Emerald `#10B981`, Champagne Gold `#D4AF37`, Cyan `#06B6D4`)  
> **Current Version**: 3.1.0  
> **Commercial Readiness**: Turnkey Flagship Platform Ready for Commercial Enterprise Deployment

---

## 1. Persona & Architecture Separation

The platform establishes strict separation across customer, cashier, and administrative personas:

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

## 2. Engineering Milestones (Milestone-Wise Execution)

### Milestone 1: Core Relational Engine & Multi-Vertical Data (`✅ COMPLETED`)
- [x] **Relational Core Schema**: 25 database migrations supporting multi-store locations, counter hardware devices, catalog, brands, inventory balances, immutable stock movements, sales, refunds, customer loyalty, cash sessions, and sync revisions.
- [x] **Strict Role-Based Access Control (RBAC)**:
  - `super_admin`: Full system control (`admin@omniluxe.store` & `admin@smartshop.com`).
  - `manager`: Store inventory, pricing, and cashier session reporting (`manager@smartshop.com`).
  - `cashier`: Register operations with numeric PIN login (`cashier1@smartshop.com` / PIN `1234`).
  - `customer`: Online shoppers with loyalty card and order history (`customer@lifestyle.test`).
- [x] **Counter Register Devices**: Pre-seeded `COUNTER-01` (Flagship POS) and `COUNTER-02` (Express POS).
- [x] **Pristine Brand Names & Multi-Vertical Catalog**:
  - Purged all non-English subtitles from product names.
  - Curated international flagship brands: Apple, Samsung, Sony, Nike, Adidas, Clarks, Studio Ceylon, Ralph Lauren, Toyota, Defender, BYD.
  - Zero Sinhala product name entries in database records (`sinhala_name` is NULL).

### Milestone 2: Central ERP Control Room & Role RBAC (`✅ COMPLETED`)
- [x] **Filament v3 ERP Admin Panel (`/admin`)**:
  - Multi-department inventory balancing and real-time movement ledgers.
  - Immutable stock movements ledger with atomic reservation for web and POS sales.
  - Store manager override authorizations, refund approvals, and audit logs.
- [x] **Verified SMS Digital E-Receipt Engine**:
  - Pluggable SMS driver (Notify.lk, Twilio, Dialog, Mobitel, and Mock drivers).
  - Instant dispatch of transaction summaries and warranty tracking links (`http://127.0.0.1:8000/receipt/{invoice}`).
  - Phone number privacy masking (`077 •••• 567`) for customer protection.

### Milestone 3: Flagship Web Storefront & Customer Self-Service (`✅ COMPLETED`)
- [x] **Customer Sign In & Sign Up Experience**:
  - Dedicated dark luxury web authentication at `/login` and `/register`.
  - Automatic credit of 100 VIP loyalty points on registration.
- [x] **OmniLuxe Privilege Account Hub (`/account`)**:
  - Gold-foil digital privilege card with cardholder name, member ID, loyalty points, and store credit limit.
  - Order history archive with real-time status badges and direct links to verifiable e-receipts.
- [x] **Real-Time Synchronized Cart Drawer**:
  - Floating slide-over cart drawer with subtotal calculation.
  - Pre-filled customer profile details for logged-in shoppers.
  - Automatic stock decrement in central ERP `inventories` and `stock_movements`.

### Milestone 4: Consumer Mobile Shopping App & VIP Club (`✅ COMPLETED`)
- [x] **Animated Luxury Splash Screen (`SplashScreen`)**:
  - Pulsing gold OmniLuxe monogram medallion (`O`), luxury tagline, and smooth transition into main screen.
- [x] **VIP Club Member Screen (`StoreMemberScreen`)**:
  - Gold-bordered digital card displaying Loyalty Points (`350 PTS`), tier badge (`GOLD VIP`), and credit limit (`Rs. 500,000`).
  - Interactive tabs for Customer Sign In & Sign Up with instant demo login for VIP testing.
- [x] **5-Tab Navigation Architecture**:
  - `Home`: Hero showcase carousel, premier brands, department grid, curated highlights.
  - `Explore`: Multi-vertical catalog with live search, department filters, warranty badges, and stock counters.
  - `Bag`: Quantity steppers, discount calculations, subtotal breakdown.
  - `Orders`: Local SQLite archive of completed transactions with digital receipt viewer.
  - `VIP Club`: Member digital privilege card, point redemption value, and account credentials.
- [x] **Automated Test Suite**: 100% test pass rate across all 21 unit, integration, and widget tests (`flutter test`).

### Milestone 5: Dedicated In-Store Cashier POS (`apps/windows-pos`) (`✅ COMPLETED`)
- [x] **Counter Register Authentication**: Cashier quick PIN sign-in linked to specific register device (`COUNTER-01`).
- [x] **Barcode Scanner Wedge**: Rapid keyboard wedge listener with `< 60ms` inter-key timing and audio chimes.
- [x] **ESC/POS Thermal Printing**: 58mm/80mm receipt generation with barcode, warranty periods, and cash drawer kick.
- [x] **Multi-Lane Held Bills**: Hold active transaction to serve express customer, resume on any counter terminal with cloud reservation.

### Milestone 6: Enterprise Rebranding & Commercial Packaging (`omniluxe-store`) (`✅ COMPLETED`)
- [x] Unified platform identity standardized as **OmniLuxe Store** (`omniluxe-store`).
- [x] Dark luxury theme consistency: Obsidian `#0A0E17`, Deep Slate `#111827`, Hairline `#223048`, Emerald `#10B981`, Champagne Gold `#D4AF37`.
- [x] Comprehensive documentation structured milestone-wise without third-party competitor mentions.
- [x] Verified full regression pass across all 28 Laravel backend tests and all 21 Flutter automated tests.

---

## 3. Technology Stack & Design Tokens

| Channel | Framework / Stack | Styling / Theme | Key Dependencies |
| :--- | :--- | :--- | :--- |
| **Web Store** | Laravel 11 Blade + Alpine.js | TailwindCSS (Dark Luxe) | Google Fonts Outfit & Inter |
| **Mobile App** | Flutter 3.x (iOS & Android) | Pure Custom Material 3 Dark | Riverpod, Google Fonts, SQLite |
| **Desktop POS** | Electron + React 18 + Vite | Vanilla Tailwind Dark Palette | Web Audio API, ESC/POS generator |
| **Backend ERP** | Laravel 11 + Filament v3 | Filament Dark Custom Panel | Spatie Permission, Sanctum, MySQL |

### Color Hierarchy
- **Obsidian Black**: `#0A0E17` (Deep primary canvas)
- **Slate Surface**: `#111827` (Card and header backgrounds)
- **Hairline Border**: `#223048` (Refined metallic border accents)
- **Emerald Accent**: `#10B981` (In-stock indicators, bag count, CTA buttons)
- **Gold Luxury**: `#D4AF37` (VIP membership badges, warranty indicators)
- **Cyan Tech**: `#06B6D4` (IMEI/Serial badges and technical specifications)
