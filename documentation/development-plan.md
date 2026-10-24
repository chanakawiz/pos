# SmartShop Unified Omnichannel Retail & ERP Ecosystem — Master Development Plan

> **System**: SmartShop Luxe — Flagship Omnichannel Retail, Desktop POS & Central ERP Engine  
> **Document**: Phased Implementation & Engineering Roadmap  
> **Target Channels**:
> 1. **In-Store Cashiers**: Dedicated High-Throughput Desktop POS Terminal (`apps/windows-pos`)
> 2. **Online Shoppers**: Web Storefront (`backend/laravel-api` & `apps/web-store`) + Luxury Mobile Shopping App (`apps/mobile-pos`)
> 3. **Admins & Store Managers**: Central ERP & Filament v3 Control Room (`/admin`)  
> **Aesthetic Theme**: Luxury Editorial Dark (Obsidian `#0A0E17`, Deep Slate `#111827`, Hairline `#223048`, Emerald `#10B981`, Gold `#D4AF37`)  
> **Current Version**: 3.0.0

---

## 1. Persona & Architecture Separation

The platform establishes strict separation across customer, cashier, and administrative personas:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                 SMARTSHOP UNIFIED RETAIL & ERP ARCHITECTURE                 │
├──────────────────────────────────────┬──────────────────────────────────────┤
│       1. ONLINE CONSUMER CHANNELS    │       2. IN-STORE CASHIER POS        │
│       (Web Store + Mobile App)       │       (Dedicated Desktop Terminal)   │
│                                      │                                      │
│  • Customer Sign Up & Sign In        │  • High-throughput cashier lanes     │
│  • VIP Club Privilege Digital Card   │  • Cashier PIN quick sign-in (1234)  │
│  • Loyalty Points (Earn & Redeem)    │  • USB & Bluetooth barcode scanner   │
│  • Luxury animated splash screen     │  • Cash drawer & ESC/POS receipt     │
│  • Omnichannel real-time cart & stock│  • Multi-lane held bills reservation │
│  • Instant SMS E-receipts dispatch   │  • Counter device codes (COUNTER-01) │
├──────────────────────────────────────┴──────────────────────────────────────┤
│                   3. CENTRAL CLOUD ERP & ADMIN PANEL                        │
│                   (Laravel 11 / Filament v3 at /admin)                      │
│                                                                             │
│  • Super Admin (admin@smartshop.com) & Store Manager (manager@smartshop.com)│
│  • Multi-department catalog: Tech, Fashion, Footwear, Luxury Automobili    │
│  • Real-time stock ledger, purchase orders, refunds, and cash sessions      │
│  • RESTful API (Sanctum), offline SQLite sync revisions, and SMS gateway    │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Key Modules & Milestones

### Milestone 1: Central Database Schema & Role-Based Seeding (`✅ COMPLETED`)
- [x] **Relational Core Schema**: 25 migrations supporting stores, counter hardware devices, catalog, brands, inventory balances, immutable stock movements, sales, refunds, customer loyalty, cash sessions, and sync revisions.
- [x] **Strict Role Hierarchy**:
  - `super_admin`: Full system control (`admin@smartshop.com`).
  - `manager`: Store inventory, pricing, and cashier session reporting (`manager@smartshop.com`).
  - `cashier`: Register operations with numeric PIN login (`cashier1@smartshop.com` / PIN `1234`).
  - `customer`: Online shoppers with loyalty card and order history (`customer@lifestyle.test`).
- [x] **Counter Register Devices**: Pre-seeded `COUNTER-01` (Flagship POS) and `COUNTER-02` (Express POS).
- [x] **Pristine Brand Names**: Standardized English brand catalog across Apple, Samsung, Nike, Adidas, Toyota, Land Cruiser, and designer boutique apparel without Sinhala subtitles.

### Milestone 2: Web Storefront & Customer Self-Service (`✅ COMPLETED`)
- [x] **Customer Sign In & Sign Up**:
  - Web routes: `/login`, `/register`, `/logout`, `/account`.
  - Welcome bonus: 100 loyalty points automatically credited on new customer registration.
- [x] **VIP Membership Account Hub (`/account`)**:
  - Gold-foil digital privilege card with cardholder name, member ID, loyalty points, and store credit limit.
  - Complete order history archive with live payment and delivery status badges.
  - Public verifiable digital e-receipt lookup via `/receipt/{invoice}` with phone number privacy masking.
- [x] **Real-Time Synchronized Bag Drawer**:
  - Floating slide-over cart drawer with subtotal calculation.
  - Fast online checkout form with pre-filled customer details for logged-in users.
  - Automatic inventory deduction in central ERP `inventories` and `stock_movements`.

### Milestone 3: Luxury Mobile Shopping App (`apps/mobile-pos`) (`✅ COMPLETED`)
- [x] **Animated Luxury Splash Screen (`SplashScreen`)**:
  - Pulsing gold SmartShop monogram medallion (`S`), luxury tagline, and smooth fade transition into main screen.
- [x] **VIP Club Member Screen (`StoreMemberScreen`)**:
  - Luxury gold-bordered digital card displaying Loyalty Points (`350 PTS`), tier badge (`GOLD VIP`), and credit limit (`Rs. 500,000`).
  - Interactive tabs for Customer Sign In & Sign Up with instant demo login for VIP testing.
- [x] **5-Tab Navigation Architecture**:
  - `Home`: Hero showcase carousel, premier brands, department grid, curated highlights.
  - `Explore`: Multi-vertical catalog with live search, department filters, warranty badges, and stock counters.
  - `Bag`: Quantity steppers, discount calculations, subtotal breakdown.
  - `Orders`: Local SQLite archive of completed transactions with digital receipt viewer.
  - `VIP Club`: Member digital privilege card, point redemption value, and account credentials.
- [x] **Automated Test Suite**: 100% test pass rate across all 21 unit, integration, and widget tests (`flutter test`).

### Milestone 4: Cashier Desktop Terminal & Hardware Operations (`apps/windows-pos`)
- [x] **Counter Authentication**: Cashier quick PIN sign-in linked to specific register device (`COUNTER-01`).
- [x] **Barcode Scanner Wedge**: Rapid keyboard wedge listener with `< 60ms` inter-key timing and audio chimes.
- [x] **ESC/POS Thermal Printing**: 58mm/80mm receipt generation with barcode, warranty periods, and cash drawer kick.
- [x] **Multi-Lane Held Bills**: Hold active transaction to serve express customer, resume on any counter terminal with cloud reservation.

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
