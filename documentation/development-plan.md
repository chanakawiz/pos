# OmniLuxe Store Unified Omnichannel Retail & ERP Ecosystem — Master Development Plan

> **System**: OmniLuxe Store (`omniluxe-store`) — Flagship Omnichannel Retail, Desktop POS & Central ERP Engine  
> **Document**: Phased Implementation & Engineering Milestones Roadmap  
> **Consolidated Architecture**: Web Storefront and Central ERP Engine are **combined into a single unified Laravel project** (`backend/laravel-api`) on one master MySQL database (`smartshop_pos`), eliminating separate project divergence and submodule friction.  
> **Target Personas & Channels**:
> 1. **Web Storefront & Central ERP Engine**: `backend/laravel-api` (Port 8000 Web Store + Filament v3 Admin + REST API + Reverb WebSockets)
> 2. **In-Store Cashier POS Counter**: `apps/windows-pos` (Electron + React 18 + Vite)
> 3. **Consumer Mobile Shopping App**: `apps/mobile-pos` (Flutter 3.x + Riverpod)  
> **Aesthetic Theme**: Editorial Light Luxury (Ivory `#FBFBF9`, Warm Cream `#F4F2EB`, Forest Green `#233C32`, Deep Ink `#242B27`, Hairline `#E3E5DF`, Sage `#7B846D`, Champagne Gold `#C29B38`)  
> **Cart Terminology**: Standardized to **Cart** across all consumer platforms  
> **Authentication**: Guest Explorer Mode + Multi-Step VIP Onboarding  
> **Current Version**: 3.4.0  
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
│  • Customer Profile & More Concierge │  • Counter device codes (COUNTER-01) │
│  • Instant SMS E-receipts dispatch   │  • Direct offline-first SQLite sync  │
│  • Push Alerts (FCM & Reverb WS)     │  • Cash drawer kick & thermal print  │
├──────────────────────────────────────┴──────────────────────────────────────┤
│                   3. CENTRAL CLOUD ERP & ADMIN PANEL                        │
│                   (Laravel 11 / Filament v3 at /admin)                      │
│                                                                             │
│  • Super Admin (admin@omniluxe.store) & Store Manager (manager@smartshop.com│
│  • Multi-department catalog: Fashion, Beauty, Footwear, Kids, Lifestyle Tech│
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
- [x] **Pristine Brand Names & Department Store Catalog**:
  - Purged all non-English subtitles and automotive vehicle references.
  - Curated international department store brands: Apple, Samsung, Sony, Nike, Adidas, Clarks, Studio Ceylon, Ralph Lauren, Dior, Calvin Klein, Chanel, Tommy Hilfiger, Fossil, Polo Kids.
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

### Milestone 7: Real-Time Omnichannel Push Notifications & Extended Customer Suite (`✅ COMPLETED`)
- [x] **Firebase Cloud Messaging (FCM) Push Engine**:
  - Laravel backend `FcmNotificationService` dispatches targeted device pushes on bill creation, loyalty points accumulation, and promotion events using Firebase HTTP v1 API with service account OAuth2 signing.
  - Device token registration API endpoint `POST /api/v1/customer/device-token` with customer-to-device mapping.
  - Flutter `NotificationService` handles Firebase FCM background/foreground message reception, channel routing, and badge sync.
- [x] **Customer Profile Screen (`StoreProfileScreen`)**:
  - Shopper identification, verified phone number with SMS bill badge, delivery address, and push notification toggle switches.
- [x] **In-App Notification Center (`StoreNotificationsScreen`)**:
  - Categorized alert feed with filter chips (`All`, `Orders`, `VIP`, `Promos`), unread badges, and 1-tap "Mark all read".
  - Live unread notification counter badge in AppBar across Home and VIP screens.
- [x] **Customer Concierge & More Screen (`StoreMoreScreen`)**:
  - Flagship boutique locator (Colombo, Kandy, Galle) with contact numbers.
  - Official warranty claims, 14-day exchange policy, and 100% authenticity guarantee modal.
  - 24/7 VIP Concierge WhatsApp link, privilege tier breakdown, and customer privacy protection.

### Milestone 8: Enterprise Security Hardening & Zero-Leakage Channel Isolation (`✅ COMPLETED`)
- [x] **Strict Consumer & Operational Boundary Enforcement**:
  - Purged all cashier PIN logins, staff terminal switchers, and ESC/POS hardware pairing from consumer mobile app (`apps/mobile-pos`).
  - Purged `/admin` ERP hyperlinks from the public web storefront (`layout.blade.php`), ensuring the company's internal ERP control room remains 100% hidden from outsiders and unauthorized consumers.
  - Confined all physical cashier operations (barcode gun wedge, ESC/POS thermal slips, RJ11 drawer pulse, cashier shifts, X/Z reports) strictly to the dedicated in-store counter station (`apps/windows-pos`).
- [x] **Verified Zero-Regression Test Pass**:
  - 28/28 passed on Laravel API backend (`php artisan test`).
  - 22/22 passed on Flutter mobile consumer app (`flutter test`).

### Milestone 9: Laravel Reverb WebSockets & Unified Master Database (`✅ COMPLETED`)
- [x] **Full Migration from Pusher to Laravel Reverb WebSockets**:
  - Installed and configured `laravel/reverb:^1.4` running on high-throughput native port 8080.
  - Secure Sanctum broadcast authentication endpoint `POST /api/v1/broadcasting/auth`.
  - Authenticated private channels (`private-customer.{uuid}`) for order updates and VIP rewards.
  - Internal staff operations channel (`private-store.{uuid}.operations`) strictly guarded by `isStaff()`.
  - Public channels (`catalog` and `promotions`) dispatch coarse, sanitized availability band changes with zero pricing or supplier data exposure.
  - Web storefront toast notifications hardened with XSS-safe DOM text nodes (`textContent`).
- [x] **Single Unified MySQL Database of Truth**:
  - Migrated `apps/web-store` from disconnected SQLite to the central MySQL database (`smartshop_pos`).
  - Both web storefront ports (8000 & 8010), Central ERP, and POS counter write to and read from the exact same database tables with identical products (Dior, Nike, Apple, Calvin Klein), categories, and stock.
  - Created centralized `customer_notifications` persistent inbox and `customer_device_tokens` tables.
- [x] **Mobile App Synchronization with Central Inbox**:
  - Flutter `NotificationService` and `NotificationNotifier` updated to fetch notification history from `GET /api/v1/customer/notifications`, sync read states via `POST /api/v1/customer/notifications/{uuid}/read`, and sync device tokens.

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

---

## 4. Current Execution Roadmap (3-Stage Ordered Delivery)

As requested, development progresses sequentially across the 3 core platform channels:

### 🌟 Stage 1: Web Storefront Deep-Dive & Commerce (`backend/laravel-api`) — `IN PROGRESS`
> **Consolidation**: The Web Storefront is combined directly inside `backend/laravel-api`, running from the single project and identical MySQL database (`smartshop_pos`). Zero submodule overhead, zero duplicated models.
- [x] Consolidate Web Store views, routes, and controllers inside `backend/laravel-api`.
- [x] Implement luxury editorial product detail view (`/product/{id}`) with inventory availability, warranty tags, and serial tracking chips.
- [x] Standardize Cart drawer with Alpine.js reactivity, guest checkout option, and subtotal calculation.
- [x] Multi-step customer registration wizard with 100 VIP welcome loyalty points.
- [x] Integrate Laravel Reverb WebSockets client (Port 8080) for real-time stock availability and order toasts.
- [x] Verified public e-receipt page at `/receipt/{invoice}` with customer phone number masking (`077 •••• 567`).
- [ ] End-to-end checkout validation: Guest order placement, VIP points deduction, atomic inventory decrement in MySQL, and SMS link generation.

### 💻 Stage 2: In-Store Cashier POS System (`apps/windows-pos`) — `QUEUED`
> **Counter Hardware & Terminal Integration**: Dedicated desktop POS station for retail staff.
- [ ] Verify cashier shift workflow (opening float, cash sessions, mid-day drops, X/Z reports).
- [ ] Test hardware barcode scanner wedge (<60ms key bursts) and instant line item addition.
- [ ] Test ESC/POS thermal printer engine (58mm/80mm slips) and RJ11 drawer kick pulse.
- [ ] Test multi-lane held bills cloud sync and retrieval across registers.
- [ ] Verify atomic inventory synchronization against the central MySQL database on sale completion.

### 📱 Stage 3: Consumer Mobile App Harmonization (`apps/mobile-pos`) — `QUEUED`
> **Customer Mobile Experience**: Flagship luxury shopping on iOS and Android.
- [ ] Connect Flutter Riverpod state to central persistent notification inbox API (`GET /api/v1/customer/notifications`).
- [ ] Push notification read state synchronization (`POST /api/v1/customer/notifications/{uuid}/read`).
- [ ] Hardware device push token registration (`POST /api/v1/customer/device-token`).
- [ ] Enforce zero-leakage security (zero staff PIN login or counter hardware pairing on consumer mobile).
- [ ] End-to-end catalog browsing, cart steppers, guest mode, orders ledger, and VIP card.

