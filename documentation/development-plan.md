# OmniLuxe Store Unified Omnichannel Retail & ERP Ecosystem — Master Development Plan

> **System**: OmniLuxe Store (`omniluxe-store`) — Flagship Omnichannel Retail, Desktop POS & Central ERP Engine  
> **Document**: Phased Implementation & Engineering Milestones Roadmap  
> **Target Personas & Channels**:
> 1. **Online Shoppers**: OmniLuxe Web Storefront (`backend/laravel-api` & `apps/web-store`) + Mobile Shopping App (`apps/mobile-pos`)
> 2. **In-Store Cashiers**: Dedicated High-Throughput Counter POS Terminal (`apps/windows-pos`)
> 3. **Admins & Store Managers**: Central ERP & Filament v3 Control Room (`/admin`)  
> **Aesthetic Theme**: Editorial Light Luxury (Ivory `#FBFBF9`, Warm Cream `#F4F2EB`, Forest Green `#233C32`, Deep Ink `#242B27`, Hairline `#E3E5DF`, Sage `#7B846D`, Champagne Gold `#C29B38`)  
> **Cart Terminology**: Standardized to **Cart** across all consumer platforms  
> **Authentication**: Guest Explorer Mode + Multi-Step VIP Onboarding  
> **Current Version**: 3.2.0  
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
│  • Guest Explorer & Guest Checkout   │  • High-throughput cashier lanes     │
│  • Multi-Step Sign In & Sign Up      │  • Cashier PIN quick sign-in (1234)  │
│  • OmniLuxe Privilege VIP Card       │  • USB & Bluetooth barcode scanner   │
│  • Loyalty Points (Earn & Redeem)    │  • Cash drawer kick & thermal print  │
│  • Editorial light aesthetic & splash│  • Multi-lane held bills reservation │
│  • Standardized Cart terminology     │  • Counter device codes (COUNTER-01) │
│  • Instant SMS E-receipts dispatch   │  • Direct offline-first SQLite sync  │
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

### Milestone 3: Editorial Light Web Storefront & Self-Service (`✅ COMPLETED`)
- [x] **Editorial Light Theme Matching Web App**:
  - Warm cream (`#F4F2EB`), pure white paper (`#FFFFFF`), signature forest green (`#233C32`), deep ink text (`#242B27`), and hairline borders (`#E3E5DF`).
  - Removed black/dark theme; unified luxury brand feel.
- [x] **Guest Mode & Multi-Step Authentication**:
  - Dedicated multi-step wizard at `/login` and `/register` with step tracker.
  - Prominent "Continue in Guest Mode" bypass allowing shoppers to add to cart and place orders without upfront registration.
  - Automatic credit of 100 VIP loyalty points upon enrollment.
- [x] **Standardized Cart Terminology**:
  - Replaced all occurrences of "Bag" with "Cart" across navigation, drawer, catalog, and checkout.
- [x] **OmniLuxe Privilege Account Hub (`/account`)**:
  - Deep forest green digital privilege card with cardholder name, member ID, loyalty points, and store credit limit.
  - Order history archive with real-time status badges and direct links to verifiable e-receipts.
- [x] **Real-Time Synchronized Cart Drawer**:
  - Slide-over cart drawer with subtotal calculation, quantity steppers, and guest checkout support.

### Milestone 4: Consumer Mobile Shopping App & VIP Club (`✅ COMPLETED`)
- [x] **Editorial Light Theme Transformation**:
  - Ivory canvas (`#FBFBF9`), warm cream (`#F4F2EB`), forest green (`#233C32`), and deep ink (`#242B27`).
- [x] **Animated Luxury Splash Screen (`SplashScreen`)**:
  - Ivory canvas, forest green medallion with champagne gold monogram `O`, and smooth transition to main store.
- [x] **Guest Mode & Multi-Step Auth (`StoreAuthStepsScreen`)**:
  - Visual step progress indicator: Step 1 (Contact / Guest Option) -> Step 2 (Password & VIP Enrollment) -> Step 3 (Privilege Card Issued).
  - Unauthenticated users can browse and checkout as Guests, with an option to join VIP for 100 welcome points.
- [x] **5-Tab Customer Navigation**:
  - `Home`: Editorial lookbook banner, premier brands, department showcase.
  - `Explore`: Multi-vertical catalog with live search, department filters, warranty badges, and 1-tap cart button.
  - `Cart`: Standardized cart steppers, summary card, and forest green checkout CTA.
  - `Orders`: Local SQLite archive of completed transactions with digital receipt viewer.
  - `VIP Club`: Guest mode overview / Deep forest green digital privilege card for members.
- [x] **Automated Test Suite**: 100% test pass rate across all 21 unit, integration, and widget tests (`flutter test`).
- [x] **Complete Screen Catalog**: 19-screen inventory, navigation routes, and Riverpod state management matrix documented in [`flutter-screens-catalog.md`](flutter-screens-catalog.md).

### Milestone 5: Dedicated In-Store Cashier POS (`apps/windows-pos`) (`✅ COMPLETED`)
- [x] **Counter Register Authentication**: Cashier quick PIN sign-in linked to specific register device (`COUNTER-01`).
- [x] **Barcode Scanner Wedge**: Rapid keyboard wedge listener with `< 60ms` inter-key timing and audio chimes.
- [x] **ESC/POS Thermal Printing**: 58mm/80mm receipt generation with barcode, warranty periods, and cash drawer kick.
- [x] **Multi-Lane Held Bills**: Hold active transaction to serve express customer, resume on any counter terminal with cloud reservation.

### Milestone 6: Enterprise Rebranding & Commercial Packaging (`omniluxe-store`) (`✅ COMPLETED`)
- [x] Unified platform identity standardized as **OmniLuxe Store** (`omniluxe-store`).
- [x] Clean light editorial design consistency across all customer-facing touchpoints (Web Storefront + Flutter Mobile).
- [x] Comprehensive documentation structured milestone-wise without third-party competitor mentions.
- [x] Verified full regression pass across all 28 Laravel backend tests and all 21 Flutter automated tests.

---

## 3. Technology Stack & Design Tokens

| Channel | Framework / Stack | Styling / Theme | Key Dependencies |
| :--- | :--- | :--- | :--- |
| **Web Store** | Laravel 11 Blade + Alpine.js | TailwindCSS (Editorial Light) | Google Fonts Outfit & Inter |
| **Mobile App** | Flutter 3.x (iOS & Android) | Pure Custom Material 3 Light | Riverpod, Google Fonts, SQLite |
| **Desktop POS** | Electron + React 18 + Vite | Vanilla Tailwind Light/Dark Palette | Web Audio API, ESC/POS generator |
| **Backend ERP** | Laravel 11 + Filament v3 | Filament Custom Admin Panel | Spatie Permission, Sanctum, MySQL |

### Color Hierarchy
- **Ivory Canvas**: `#FBFBF9` (Soft luxury background)
- **Warm Cream**: `#F4F2EB` (Section and container backgrounds)
- **Pure Paper**: `#FFFFFF` (Cards, dialogs, drawers)
- **Forest Green**: `#233C32` (Signature luxury brand color & primary CTA)
- **Deep Ink**: `#242B27` (Crisp typographic text)
- **Hairline Border**: `#E3E5DF` (Refined subtle boundary lines)
- **Sage Secondary**: `#7B846D` (Botanical secondary accents & subtitles)
- **Champagne Gold**: `#C29B38` (VIP membership badges, loyalty point highlights)
