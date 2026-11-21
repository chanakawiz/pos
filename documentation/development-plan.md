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

### Milestone 11: Self-Service Order Tracking & Returns/Exchange Portal (`✅ COMPLETED`)
- [x] **Omnichannel Fulfillment & Tracking Telemetry Database Layer**:
  - Migration `2026_11_01_000001_add_fulfillment_and_tracking_to_sales_table.php` adding `fulfillment_status` (`unfulfilled`, `processing`, `packed`, `dispatched`, `delivered`, `returned`), `courier_name`, `tracking_number`, `estimated_delivery_at`, `dispatched_at`, and `delivered_at`.
  - Migration `2026_11_01_000002_create_return_requests_tables.php` establishing `return_requests` and `return_request_items` for RMA tracking.
  - Eloquent models `ReturnRequest`, `ReturnRequestItem`, and relationships on `Sale` and `SaleItem`.
- [x] **Central Business Service Engine (`OrderTrackingService`)**:
  - Universal multi-reference lookup (`trackOrder`) via invoice number, courier tracking code, or UUID.
  - Self-service RMA submission (`submitReturnRequest`) supporting item condition reporting, exchange variant preferences, and refunds.
  - Dispatch telemetry updates (`updateFulfillment`) with automated timestamp capture (`dispatched_at`, `delivered_at`).
- [x] **Editorial Light Luxury Web Tracking Portal (`store.track`)**:
  - Search interface supporting instant query resolution for web and counter POS orders.
  - 5-step visual telemetry stepper (Order Placed -> Payment Verified -> Packed & Inspected -> Dispatched with Courier -> Delivered).
  - Courier dispatch banner with tracking code copy and estimated delivery date.
  - Interactive self-service return & exchange submission accordion.
  - Customer account order card direct deep-links (`Track & Return`).
- [x] **Mobile REST APIs & In-App Order Telemetry (`apps/mobile-pos`)**:
  - Public mobile telemetry endpoint `GET /api/v1/orders/track/{identifier}` and submission endpoint `POST /api/v1/orders/returns`.
  - Flutter `StoreOrdersScreen` updated with order telemetry bottom sheet showing 5-step progress and self-service return guidance.
- [x] **100% Verified Automated Test Suite**:
  - 8/8 feature tests in `OrderTrackingTest.php` passing all assertions.
  - 41/41 Laravel backend tests passing (`php artisan test`).
  - 22/22 Flutter mobile tests passing (`flutter test`).
  - 41/41 Desktop POS tests passing (`npm test`).
  - **Total: 104/104 passing tests across the entire omnichannel ecosystem**.

---

### Milestone 12: Automated Courier Dispatch & Concierge RMA Approvals (`✅ COMPLETED`)
- [x] **Filament ERP Courier Dispatch & Delivery Actions**:
  - Enhanced `SaleResource.php` with fulfillment status badges, courier and tracking number columns, and quick table actions:
    - **Dispatch Order**: Modal collecting courier service (Prompt Express, Domex, DHL), tracking number, and estimated delivery date.
    - **Mark Delivered**: Instant delivery confirmation and customer alert.
- [x] **Filament Concierge Returns & Exchanges RMA Resource (`ReturnRequestResource`)**:
  - Dedicated Filament resource under *Sales & Fulfillment* with RMA table, items count, customer lookup, and filterable status tags.
  - Concierge staff actions:
    - **Approve**: Reviews item condition, adds instructions, and optionally credits customer with instant loyalty/privilege points.
    - **Reject**: Captures official concierge reason for rejection.
    - **Complete**: Final settlement upon physical goods inspection.
- [x] **Real-Time Multi-Channel Notification Pipeline (`CustomerNotifier`)**:
  - Automated `orderDispatched` and `orderDelivered` alerts pushed to persistent inbox (`customer_notifications`), broadcasted over Laravel Reverb (`private-customer.{uuid}`), and queued for FCM push.
  - `returnRequestUpdated` alerts triggered on concierge RMA approvals, rejections, and point credits.
- [x] **100% Passing Automated Tests**:
  - 11/11 tests in `OrderTrackingTest.php` passing all assertions for dispatch, RMA approval, rejection, and loyalty credit.
  - 44/44 Laravel tests passing (`php artisan test`).
  - 22/22 Flutter tests passing (`flutter test`).
  - 41/41 Desktop POS tests passing (`npm test`).
  - **Total: 107/107 passing tests across the entire omnichannel ecosystem**.

---

### Milestone 13: Multi-Branch Stock Transfers & Sibling Inventory Lookup (`✅ COMPLETED`)
- [x] **Inter-Branch Stock Transfer Database Layer**:
  - Migration `2026_11_01_000003_create_stock_transfers_tables.php` creating `stock_transfers` and `stock_transfer_items`.
  - Eloquent models `StockTransfer` and `StockTransferItem` with relationships to source and destination stores, products, variants, and audit users.
- [x] **Enterprise Stock Transfer Service (`StockTransferService`)**:
  - `createTransfer`: Validates distinct outlets, non-empty items, and registers pending transfer manifests with `TRF-...` numbering.
  - `dispatchTransfer`: Deducts source store inventory atomically, records `transfer_out` audit log, sets status to `in_transit`.
  - `receiveTransfer`: Increments destination store inventory atomically, records `transfer_in` audit log, sets status to `received`.
  - `cancelTransfer`: Safely aborts transfer and automatically restores deducted stock if cancelled while in transit.
  - `getCrossStoreStock`: Aggregates real-time `quantity_on_hand`, `quantity_reserved`, and `quantity_available` across all active branch outlets for any SKU/barcode.
- [x] **Multi-Outlet REST APIs (`/api/v1`)**:
  - `GET /api/v1/products/{id}/cross-store-stock`: Real-time cross-branch stock inquiry for in-store cashier registers and mobile apps.
  - Full transfer lifecycle endpoints: `GET /api/v1/stock-transfers`, `POST /api/v1/stock-transfers`, `POST /api/v1/stock-transfers/{uuid}/dispatch`, `POST /api/v1/stock-transfers/{uuid}/receive`, `POST /api/v1/stock-transfers/{uuid}/cancel`.
- [x] **Filament ERP Stock Transfer Resource (`StockTransferResource`)**:
  - Created under *Catalog & Inventory* with transfer manifest form, status badges (`draft`, `pending_approval`, `in_transit`, `received`, `cancelled`), and quick table actions for **Dispatch** and **Receive**.
- [x] **100% Passing Automated Tests**:
  - 6/6 tests in `StockTransferTest.php` passing all assertions for creation, dispatch, receipt, cancellation restoration, and API lifecycle.
  - 50/50 Laravel backend tests passing (`php artisan test`).
  - 22/22 Flutter mobile tests passing (`flutter test`).
  - 41/41 Desktop POS tests passing (`npm test`).
  - **Total: 113/113 passing tests across the entire omnichannel ecosystem**.

---

### Milestone 14: POS Cross-Branch Stock Modal & Low-Stock Alerts (`✅ COMPLETED`)
- [x] **Desktop POS Cross-Branch Lookup (`BranchStockModal`)**:
  - Added dedicated `BranchStockModal.tsx` in `apps/windows-pos` with `F6` shortcut and Header action button.
  - Cashiers can look up any item by name, barcode, or SKU to inspect stock levels across all active stores (Colombo Flagship Hub, Kandy Galleria, Galle Fort Boutique) with contact and address details.
  - Added `getCrossStoreStock()` API client integration and global modal state in `usePosStore.ts`.
- [x] **Automated Low-Stock Alerts**:
  - `InventoryService::deductStock()` automatically checks against product `min_stock_level` and logs warning alerts on deficit.
  - `InventoryBroadcaster` calculates public availability bands (`in_stock`, `low_stock`, `out_of_stock`) using product minimum stock thresholds, streaming to Reverb WebSockets.
- [x] **Mobile App Boutique Availability**:
  - Added "Check In-Store Availability" interactive live card on `ProductDetailScreen` in `apps/mobile-pos`.
  - Tapping opens a luxury bottom sheet querying `GET /api/v1/products/{id}/cross-store-stock` with real-time stock badges (`In Stock`, `Low Stock`, `Out of Stock`) and resilient offline fallback.
- [x] **100% Passing Automated Tests**:
  - 50/50 Laravel backend tests passing (`php artisan test`).
  - 41/41 Desktop POS tests passing (`npm test`) and Vite build verified.
  - 22/22 Flutter mobile tests passing (`flutter test`).
  - **Total: 113/113 passing tests across the entire omnichannel ecosystem**.

---

### Milestone 15: Omnichannel VIP Gift Cards & Boutique Store Credit Engine (`✅ COMPLETED`)
- [x] **Enterprise Digital Gift Card & Voucher Schema**:
  - Migration `2026_11_01_084858_create_gift_cards_tables.php` establishing `gift_cards` and `gift_card_transactions` tables.
  - Alphanumeric code generator format: `GC-XXXX-XXXX-XXXX` with collision-safe uniqueness guarantees.
  - Eloquent models `GiftCard` and `GiftCardTransaction` with balances, statuses (`active`, `redeemed`, `expired`, `disabled`), customer assignment, and audit histories.
- [x] **Business Service Layer (`GiftCardService`)**:
  - `issueCard`: Creates card with face value, activates initial transaction audit, and assigns 1-year default expiry.
  - `checkBalance`: Validates card status, expiration, and returns available store credit.
  - `redeemCard`: Thread-safe database transactions (`lockForUpdate`) that decrement balance, update status to `redeemed` upon exhaustion, and record audit logs.
  - `refundToCard`: Restores balances on sales returns or RMA concierges.
- [x] **Omnichannel REST APIs (`/api/v1`)**:
  - Public balance verification: `POST /api/v1/gift-cards/verify`.
  - Cashier & staff management: `GET /api/v1/gift-cards`, `POST /api/v1/gift-cards` (issue), and `POST /api/v1/gift-cards/redeem`.
- [x] **Filament ERP Control Room (`GiftCardResource`)**:
  - Created under *Sales & Fulfillment* with card generation, balance monitoring, customer/store associations, and disable/enable quick actions.
- [x] **In-Store Desktop POS Integration (`apps/windows-pos`)**:
  - Added dedicated Gift Card tender option in `PaymentModal.tsx` with instant verification and balance deduction.
  - Extended offline storage types and validators to support `gift_card` payment method.
- [x] **Web Storefront Cart Drawer Integration**:
  - Integrated VIP Gift Card / Voucher accordion into `layout.blade.php` and `WebStoreController.php` with real-time balance lookup and automatic order discount deduction.
- [x] **100% Passing Automated Tests**:
  - 6/6 tests in `GiftCardTest.php` passing all assertions.
  - 56/56 Laravel backend tests passing (`php artisan test`).
  - 41/41 Desktop POS tests passing (`npm test`) and Vite build clean.
  - 22/22 Flutter mobile tests passing (`flutter test`).
  - **Total: 119/119 passing tests across the entire omnichannel ecosystem**.

---

### Milestone 16: Automated VIP Loyalty Tier Progression & Privilege Perks (`✅ COMPLETED`)
- [x] **VIP Tier Architecture & Progression Rules Engine**:
  - Migration `2026_11_01_090927_add_vip_tier_and_total_spend_to_customers_table.php` adding `vip_tier` (`silver`, `gold`, `black`), `total_spend`, and `tier_updated_at` to `customers` table.
  - Multi-tiered tier definition:
    - **Silver Privilege**: Default entry tier (Rs. 0 - 99,999 spend / 0 - 999 pts), 1.0x point multiplier, 0% automatic discount.
    - **Gold Elite**: Rs. 100,000+ spend or 1,000+ loyalty points, 1.5x point multiplier, 5% automatic privilege discount.
    - **Black Diamond**: Rs. 250,000+ spend or 2,500+ loyalty points, 2.0x point multiplier, 10% automatic privilege discount.
  - Eloquent model `Customer` enhanced with `$appends = ['tier_title', 'tier_discount_percent', 'points_multiplier']` and accessors.
- [x] **Automated Tier Upgrade & Billing Engine (`LoyaltyTierService`)**:
  - Real-time spend progression evaluation during sale finalization via `LoyaltyTierService::processSaleSpend()`.
  - Atomic recalculation and tier elevation with in-app customer notification dispatch on tier promotion.
  - Integration with `BillingService.php` to award loyalty points scaled by active tier point multipliers (e.g. 1.5x or 2.0x).
- [x] **Omnichannel Loyalty Tier APIs**:
  - Public tier benefits discovery endpoint `GET /api/v1/loyalty/tiers` returning spend thresholds, point multipliers, and privilege discounts.
  - Customer profile and authentication responses return full tier metadata and progression metrics.
- [x] **Web Storefront VIP Portal & Profile**:
  - Updated `account.blade.php` with luxury tier badge presentation (Onyx Black Diamond, Emerald Gold Elite, Forest Silver), current tier multiplier, spend progress bar towards next tier, and privilege perks overview.
- [x] **In-Store Desktop POS Tier Benefits & Automatic Discounting**:
  - Extended `storage-types.ts` with VIP tier fields.
  - Updated `useCartStore.ts` to automatically apply the customer's tier discount (5% for Gold Elite, 10% for Black Diamond) upon customer attachment.
  - Updated `CustomerModal.tsx` displaying luxury VIP tier badge and automatic discount percentage.
- [x] **100% Passing Automated Tests**:
  - 5/5 tests in `LoyaltyTierTest.php` passing all assertions (spend calculation, multiplier calculation, tier upgrade notifications, API tier list).
  - 61/61 Laravel backend tests passing (`php artisan test`).
  - 41/41 Desktop POS tests passing (`npm test`) and Vite build verified.
  - 22/22 Flutter mobile tests passing (`flutter test`).
  - **Total: 124/124 passing tests across the entire omnichannel ecosystem**.

---

### Milestone 17: Multi-Branch Performance & Inventory Health Dashboards (`✅ COMPLETED`)
- [x] **Omnichannel Branch Analytics Engine (`BranchAnalyticsService`)**:
  - `getBranchPerformanceSummary`: Real-time cross-branch sales, cost of goods sold (COGS), gross margin ($ and %), orders count, average order value (AOV), online/offline channel breakdown, and branch inventory valuation across Colombo Flagship (`STORE-001`), Kandy Galleria (`STORE-002`), and Galle Fort Boutique (`STORE-003`).
  - `getCashierPerformance`: Sales velocity tracking, completed transactions count, revenue volume, drawer discrepancy tracking, and reconciliation integrity status (`100% Balanced`, `Minor Variance`, `Audit Required`).
  - `getStockAgingAndRecommendations`: Automated inventory age calculation (days inactive since latest sale or movement), turnover classification (`Fast Mover`, `Steady`, `Slow Moving`, `Stagnant`), and dynamic inter-branch transfer recommendations.
  - `getExecutiveKpis`: High-level executive KPIs including network gross margin %, top branch revenue, total network inventory valuation, and cash drawer reconciliation accuracy.
- [x] **Filament ERP Visual Intelligence Suite**:
  - `BranchPerformanceStatsWidget`: Executive KPI cards (Network Gross Margin %, Top Branch, Reconciliation Accuracy %, Luxury Inventory Valuation).
  - `BranchPerformanceChartWidget`: Grouped multi-branch comparative bar chart visualizing Gross Revenue vs. Gross Margin vs. COGS.
  - `CashierVelocityWidget`: Table tracking staff throughput, processed revenue, shift register counts, drawer variances, and integrity health badges.
  - `StockAgingVelocityWidget`: Table monitoring slow-moving luxury inventory with 1-click inter-branch transfer dispatch actions.
  - Dedicated Filament Page: `BranchPerformance` (`/admin/branch-performance`) grouped under *Analytics & Reports*.
- [x] **REST Telemetry Endpoints**:
  - `GET /api/v1/reports/branch-performance`: Consolidated executive KPIs, branch summaries, and cashier velocity.
  - `GET /api/v1/reports/stock-aging`: Inventory aging metrics with transfer advisories.
- [x] **100% Passing Automated Tests**:
  - 6/6 tests in `BranchPerformanceTest.php` passing all assertions.
  - 67/67 Laravel backend tests passing (`php artisan test`).
  - 41/41 Desktop POS tests passing (`npm test`).
  - 22/22 Flutter mobile tests passing (`flutter test`).
  - **Total: 130/130 passing tests across the entire omnichannel ecosystem**.

---

### Milestone 18: Production Containerization & Resilient Health Audits (`✅ COMPLETED`)
- [x] **Enterprise Multi-Container Orchestration (`docker-compose.yml`)**:
  - `omniluxe-app`: High-concurrency PHP 8.3 FPM alpine container running Laravel 11.
  - `omniluxe-web`: Nginx reverse proxy with gzip compression, secure headers, and automated HTTP healthcheck probes.
  - `omniluxe-mysql`: Dedicated MySQL 8.0 instance with container volume persistence and automated `mysqladmin ping` health validation.
  - `omniluxe-reverb`: Native WebSocket broadcasting server (`php artisan reverb:start`) on port 8080 delivering real-time omnichannel inventory updates and dispatch alerts.
  - `omniluxe-queue`: Background asynchronous worker processing email receipts, device push notifications, and analytics crunching.
- [x] **Production Health Check Endpoints & Probes**:
  - `GET /health/live`: High-frequency liveness probe for load balancers and Kubernetes checking PHP runtime viability.
  - `GET /health/ready`: Deep readiness audit verifying database connectivity (with latency telemetry), cache read/write responsiveness, storage permissions, and Reverb WebSocket configuration.
- [x] **100% Passing Automated Tests**:
  - 3/3 tests in `HealthCheckTest.php` passing all assertions.
  - 70/70 Laravel backend tests passing (`php artisan test`).
  - 41/41 Desktop POS tests passing (`npm test`).
  - 22/22 Flutter mobile tests passing (`flutter test`).
  - **Total: 133/133 passing tests across the entire omnichannel ecosystem**.

---

### Milestone 19: Progressive Web App (PWA) & Offline Storefront Resilience (`✅ COMPLETED`)
- [x] **Web App Manifest (`/manifest.json`)**:
  - Configured standalone display mode, orientation, brand theme color `#233C32`, canvas color `#FBFBF9`, and 192x192 & 512x512 luxury monogram icons for iOS and Android "Add to Home Screen" installation.
- [x] **Service Worker Caching Engine (`/sw.js`)**:
  - Intelligent multi-strategy caching with versioned cache storage (`omniluxe-cache-v1`).
  - Network-first navigation routing with seamless fallback to offline boutique view.
  - Cache-first strategy for Google fonts, Tailwind styling, and static image assets.
  - Explicit bypass rules for ERP (`/admin`), API endpoints (`/api`), and Reverb WebSocket channels (`/app`).
- [x] **Offline Concierge View (`/offline`)**:
  - Light Editorial Luxury offline screen with session cart retention notification, one-tap connection retry, and 24/7 VIP Concierge hotline.
- [x] **Connectivity Telemetry & Toasts**:
  - Live browser online/offline event listeners in `layout.blade.php` displaying informative notifications when connection status changes.
- [x] **100% Passing Automated Tests**:
  - 4/4 tests in `PwaStoreTest.php` passing all assertions.
  - 74/74 Laravel backend tests passing (`php artisan test`).
  - 41/41 Desktop POS tests passing (`npm test`).
  - 22/22 Flutter mobile tests passing (`flutter test`).
  - **Total: 137/137 passing tests across the entire omnichannel ecosystem**.

---

### Milestone 20: Omnichannel Multi-Gateway SMS E-Receipts & Delivery Alerts (`✅ COMPLETED`)
- [x] **Multi-Driver SMS Gateway Engine (`config/sms.php` & `SmsService`)**:
  - Architecture supporting driver connectors: `NotifyLkDriver` (Sri Lanka telecom gateway), `TwilioDriver` (international), `DialogEsmsDriver` (Dialog Axiata eSMS), `LogDriver` (local development), and `MockDriver` (in-memory testing).
  - Phone normalization engine converting Sri Lankan local numbers (`077...`, `77...`, `9477...`) to standard E.164 (`+9477...`) and foreign international formats.
  - Privacy masking engine formatting numbers (e.g. `+94 77 •••• 567`) for secure displays, receipts, and public tracking.
  - Database audit ledger via migration `2026_11_18_000001_create_sms_logs_table.php` and `SmsLog` model tracking delivery status, gateway references, costs, and error messages.
- [x] **Automated Omnichannel Event Dispatches**:
  - **In-Store Desktop POS & Web Store Sales**: `BillingService::processSale()` automatically dispatches digital e-receipt SMS with permanent URL (`/receipt/{invoice}`) and helpline contacts upon sale finalization.
  - **Courier Order Dispatch**: `OrderTrackingService::updateFulfillment()` automatically dispatches SMS with courier name, tracking number, and live tracking URL (`/track/{invoice}`).
  - **Order Delivery**: Automated delivery confirmation SMS with digital warranty lookup link.
  - **VIP Loyalty Tier Upgrades**: `LoyaltyTierService::processSaleSpend()` automatically dispatches congratulatory SMS detailing newly unlocked VIP tier (Gold Elite / Black Diamond) and automatic privilege discount perks.
- [x] **REST APIs & Cashier Desktop POS Integration**:
  - `POST /api/v1/sales/{uuid}/resend-sms`: Allows cashiers or customers to trigger or re-send digital SMS e-receipts to any provided mobile number.
  - `GET /api/v1/sms/logs`: Paginated audit log retrieval with store and status filtering.
  - `POST /api/v1/sms/test-send`: Gateway connectivity test endpoint for administrators.
  - `ReceiptModal.tsx` in `apps/windows-pos`: Instant mobile input bar allowing cashiers to dispatch digital SMS e-receipts with real-time feedback.
- [x] **Filament ERP Control Room (`SmsLogResource`)**:
  - Located under *Settings & System* with search, event badges (`POS E-Receipt`, `Web Store Order`, `Courier Dispatch`, `VIP Tier Upgrade`), gateway driver badges, status filtering, and 1-click **Resend SMS** and **Test Gateway Dispatch** action modals.
  - Added direct `SMS Receipt` modal action to `SaleResource` in Filament.
- [x] **100% Passing Automated Tests**:
  - 9/9 tests in `SmsGatewayTest.php` passing all assertions (phone normalization, privacy masking, mock dispatches, failure handling, sale receipts, courier tracking, VIP upgrade, resend API, logs API, test send API).
  - 83/83 Laravel backend tests passing (`php artisan test`).
  - 41/41 Desktop POS tests passing (`npm test`) and Vite build verified.
  - 22/22 Flutter mobile tests passing (`flutter test`).
  - **Total: 146/146 passing tests across the entire omnichannel ecosystem**.

---

### Milestone 21: Customer Product Reviews, Star Ratings & Verified Purchase Badges (`✅ COMPLETED`)
- [x] **Enterprise Product Reviews Schema & Eloquent Relations**:
  - Migration `2026_11_18_000002_create_product_reviews_table.php` establishing `product_reviews` with fields: `uuid`, `product_id`, `customer_id`, `author_name`, `author_email`, `rating` (1–5 integer), `title`, `comment`, `is_verified_purchase` (boolean), `is_approved` (boolean default true), `helpful_votes` (unsigned integer), and timestamps.
  - Eloquent model `ProductReview` with casts, scopes (`approved`, `verified`, `byRating`), and relationship links to `Product` and `Customer`.
  - `Product` model extended with `reviews()`, `approvedReviews()`, dynamic `average_rating`, and `reviews_count` accessors.
- [x] **Business Service Layer (`ReviewService`)**:
  - `checkVerifiedPurchase`: Cross-references customer ID, customer email, or customer phone against historical completed and paid `SaleItem` records to authenticate genuine ownership.
  - `getReviewsSummary`: Computes aggregate star rating (rounded to 1 decimal), total review count, and full 5-star percentage breakdown (5, 4, 3, 2, 1 stars).
  - `submitReview`: Validates rating range, sanitizes input, performs automatic verified purchase detection, and stores the review record.
  - `voteHelpful`: Atomically increments review helpfulness counter.
- [x] **Omnichannel REST APIs (`/api/v1`)**:
  - `GET /api/v1/products/{id}/reviews`: Paginated list of approved reviews with comprehensive summary breakdown.
  - `POST /api/v1/products/{id}/reviews`: Public submission endpoint for customer reviews with verified purchaser auto-tagging.
  - `POST /api/v1/reviews/{uuid}/helpful`: 1-click endpoint to register helpful votes on customer reviews.
- [x] **Web Storefront Editorial Product Experience (`store.product` Blade)**:
  - Header star rating preview badge next to SKU and brand tag.
  - Comprehensive luxury ratings summary card with large average rating, star visualizer, and 5-to-1 star distribution bar meters.
  - Customer review card stream displaying author monogram avatars, Champagne Gold star rating icons, and "Verified Purchaser" luxury badge.
  - Interactive Alpine.js review submission form with interactive 5-star rating selector, form validation, and instantaneous optimistic UI submission feedback.
  - 1-click "Helpful" vote button with reactive count increments.
- [x] **Filament ERP Control Room (`ReviewResource`)**:
  - Located under *Catalog & Inventory* with product, reviewer, star rating, verified status, and approval status columns.
  - 1-click quick actions: **Approve Review** and **Reject / Hide Review** for frictionless customer feedback moderation.
- [x] **100% Passing Automated Tests**:
  - 7/7 tests in `ProductReviewTest.php` passing all assertions (verified purchase detection, unverified handling, aggregate summary calculation, helpful voting, REST API retrieval, REST API submission, web storefront submission).
  - 90/90 Laravel backend tests passing (`php artisan test`).
  - 41/41 Desktop POS tests passing (`npm test`) and Vite build verified.
  - 22/22 Flutter mobile tests passing (`flutter test`).
  - **Total: 153/153 passing tests across the entire omnichannel ecosystem**.

---

### Milestone 22: Automated End-of-Day (EOD) Closeout & Scheduled Z-Report Dispatcher (`✅ COMPLETED`)
- [x] **Consolidated EOD Reports Schema & Eloquent Model**:
  - Migration `2026_11_18_000003_create_eod_reports_table.php` establishing `eod_reports` with fields: `uuid`, `store_id`, `report_date`, `generated_by`, `closed_sessions_count`, `total_opening_float`, `total_cash_sales`, `total_card_sales`, `total_gift_card_sales`, `gross_sales`, `total_discounts`, `total_refunds`, `net_sales`, `expected_cash`, `actual_closing_cash`, `net_discrepancy`, `is_automated`, `breakdown_json`, `notes`, and timestamps.
  - Eloquent model `EodReport` with relationships to `Store` and `User` (`generatedBy`), array casting for lane breakdown, and scopes (`forStore`, `forDate`).
- [x] **Business Service Layer (`EodCloseoutService`)**:
  - `getRegisterStatus`: Real-time audit of open register sessions across stores, detecting elapsed hours, individual cash drawer balances, and total cash at risk.
  - `calculateDailySummary`: Consolidated financial aggregation across all counter lanes for any chosen date (gross, discounts, net sales, cash/card/gift card tender splits, refunds, drawer float, and net variance).
  - `performCloseout`: Transaction-safe drawer closure with counted balances, discrepancy logging, automated Z-report creation, and executive SMS alert dispatch.
  - `dispatchEodSms`: Dispatches concise executive SMS digest to store managers with store gross sales, payment splits, closed register counts, and balanced status.
- [x] **Nightly Scheduler & Artisan Command (`pos:eod-closeout`)**:
  - Console command `php artisan pos:eod-closeout` supporting `--store=`, `--force`, `--dry-run`, and `--notify` options with clean ANSI table output.
  - Automatically scheduled in `routes/console.php` to run nightly at 23:59 without overlapping (`omniluxe-nightly-eod-closeout`).
- [x] **Omnichannel REST APIs (`/api/v1/eod`)**:
  - `GET /api/v1/eod/status`: Real-time status of registers and cash at risk.
  - `GET /api/v1/eod/summary`: Detailed multi-lane Z-report summary for current date or historical query.
  - `POST /api/v1/eod/closeout`: 1-click immediate store reconciliation and drawer closure endpoint.
  - `GET /api/v1/eod/history`: Paginated archive of past consolidated Z-reports.
  - `POST /api/v1/eod/{uuid}/resend-sms`: On-demand manager SMS re-dispatch endpoint.
- [x] **Filament ERP Control Room (`EodReportResource`)**:
  - Located under *POS & Registers* with date, store, gross sales, payment splits, closed register badges, variance highlights, and automated indicator icons.
  - Interactive "Run EOD Reconciliation" modal action in `ListEodReports` with store picker, force toggle, notes, and SMS trigger.
  - Row action "Resend SMS" allowing managers to dispatch Z-report digests on demand.
- [x] **100% Passing Automated Tests**:
  - 7/7 tests in `EodCloseoutTest.php` passing all assertions (register status, daily sales aggregation, session closure, SMS dispatch, artisan command dry-run & execute, REST APIs, resend SMS).
  - 97/97 Laravel backend tests passing (`php artisan test`).
  - 41/41 Desktop POS tests passing (`npm test`) and Vite build verified.
  - 22/22 Flutter mobile tests passing (`flutter test`).
  - **Total: 160/160 passing tests across the entire omnichannel ecosystem**.

---

### Milestone 23: Handheld Flutter Mobile POS Architecture, Terminal Device Provisioning & Staff PIN Auth (`apps/flutter-mobile-pos`) (`✅ COMPLETED`)
- [x] **Handheld Flutter Mobile POS App Foundation**:
  - Created dedicated Flutter mobile POS terminal project in `apps/flutter-mobile-pos` using Flutter 3.27+ with Dart 3.6+.
  - Clean feature-first architecture with Riverpod state management (`posAuthProvider`).
  - High-contrast, tactile Staff POS Dark/Light Hybrid theme (`PosTheme`) with deep obsidian canvas (`#111413`), card surfaces (`#19201C`), and Champagne Gold accents (`#C29B38`) optimized for handhelds and store associate tablets.
- [x] **Hardware Device Provisioning & Counter Pairing**:
  - Device enrollment screen (`DevicePairingScreen`) linking device code (e.g., `ROAMING-01`), Store code (`STORE-001`), and central ERP URL (`http://127.0.0.1:8000`) with persistent storage.
  - Automatic graceful offline fallback pairing ensuring store resilience during network disconnects.
- [x] **Cashier Numeric PIN Pad & Shift Session Initialization**:
  - Ergonomic tactile numeric PIN pad (`StaffPinScreen`) with 4-dot gold indicator and cashier choice chips (`Cashier 01`, `Cashier 02`, `Store Manager`).
  - Shift Open Float modal dialog (`ShiftOpenDialog`) requiring counted opening cash float entry (with quick denomination chips: LKR 5,000, 10,000, 15,000, 20,000) before accessing register.
  - Cashier dashboard (`PosHomeScreen`) displaying store name, terminal badge, cashier profile, live active shift float, and quick cashier actions.
- [x] **100% Passing Automated Tests**:
  - 7/7 tests in `pos_auth_test.dart` and `widget_test.dart` passing all assertions (PIN verification, shift opening, terminal locking, keypad input, choice chips).
  - 97/97 Laravel backend tests passing (`php artisan test`).
  - 41/41 Desktop POS tests passing (`npm test`).
  - 22/22 Consumer mobile tests passing (`flutter test`).
  - 7/7 Handheld staff POS tests passing (`flutter test`).
  - **Total: 167/167 passing tests across the entire omnichannel ecosystem**.

---

### Milestone 24: Mobile POS Fast-Touch Catalog, Continuous Camera/Bluetooth Barcoding & Line-Busting (`✅ COMPLETED`)
- [x] **Ultra-Fast Mobile Catalog & Department Switcher**:
  - Implemented responsive `PosCheckoutScreen` featuring search-as-you-type (<15ms filtering), department filter chips (`Smartphones & Tech`, `Designer Fashion`, `Footwear & Sneakers`, `Fragrances & Beauty`), and tactile luxury dark product card grid with live stock badge overlays.
  - Variant selection bottom sheet modal supporting apparel sizing (S, M, L, XL), footwear sizes (UK 8–11), and tech storage capacities.
  - Reactive Riverpod provider `posCatalogProvider` with resilient offline-first fallback luxury inventory.
- [x] **Continuous Camera Viewfinder & Hardware Barcode Wedge**:
  - Integrated `BarcodeScannerDialog` with animated optical laser scanning beam, reticle markers, audio/haptic status banner, and manual hardware wedge keystroke listener.
  - Interactive 1-tap test wedge chips (`445566 iPhone 16 Pro Max`, `556677 Galaxy S24 Ultra`, `667788 AirPods Pro 2`, `112233 Studio Ceylon`, `223344 Nike Pegasus`, `334455 Dior Sauvage`) providing instant item addition to the active register cart.
- [x] **Multi-Lane Line-Busting & Held Bills Cloud Sync**:
  - `PosCartProvider` managing cart state, quantities, order discounts, and VIP loyalty customer attachments.
  - In-aisle line-busting action: Roaming staff scan a customer's basket and tap **"HOLD BILL"** to push to central cloud `/api/v1/held-bills` with a unique reference (`HOLD-XXXXXX`), immediately freeing the handheld register to serve the next customer.
  - `HeldBillsDialog` displaying real-time multi-lane held queue with customer details, item totals, and 1-tap **"RECALL TO REGISTER"** restoring items and releasing the cloud hold via `DELETE /api/v1/held-bills/{uuid}`.
- [x] **100% Passing Automated Tests**:
  - 20/20 Flutter mobile POS tests passing across `pos_auth_test.dart`, `pos_catalog_cart_test.dart`, `pos_checkout_widget_test.dart`, and `widget_test.dart`.
  - 97/97 Laravel backend tests passing (`php artisan test`).
  - 41/41 Desktop POS tests passing (`npm test`).
  - 22/22 Consumer mobile tests passing (`flutter test`).
  - 20/20 Handheld staff POS tests passing (`flutter test`).
  - **Total: 180/180 passing tests across the entire omnichannel ecosystem**.

---

### Milestone 25: Handheld Checkout, Payment Tender, Bluetooth ESC/POS Printing & SMS Bills (`✅ COMPLETED`)
- [x] **Omnichannel Mobile Payment Tender Modal**:
  - Implemented `PaymentTenderSheet` supporting multi-tender split payments:
    - **Cash**: Exact change chip, quick denomination buttons (+500, +1,000, +2,000, +5,000, +10,000), numeric entry, and live change due calculation.
    - **Card / mPOS**: Terminal selection, authorization reference code, and instant card charge.
    - **VIP Gift Card**: Voucher code lookup, balance verification against `/api/v1/gift-cards/verify` with offline fallback, and credit deduction.
    - **LankaQR**: Dynamic QR modal with CBSL / LankaPay compliance certification and 1-tap confirmation.
  - Customer VIP loyalty points redemption slider (100 pts = LKR 1,000, 250 pts = LKR 2,500, 500 pts = LKR 5,000) with real-time cart discount deduction.
- [x] **Bluetooth & Portable ESC/POS Thermal Receipt Engine**:
  - Built `EscPosService` generating standard binary ESC/POS byte buffers for 58mm (portable belt clip printers) and 80mm (counter wireless printers).
  - Encodes hardware initialization (`ESC @`), double-width luxury brand headers (`OMNILUXE`), store telemetry, item line tables, subtotal/discount/tax summaries, tender breakdown, change due, VIP points, and full paper cut (`GS V 0`).
  - Integrated audit log buffer tracking transmitted bytes and job parameters.
- [x] **Instant SMS E-Receipt & Paperless Checkout**:
  - Automated digital SMS e-receipt dispatch via central `SmsService` (`/api/v1/sms/test-send` or `/api/v1/sales/{uuid}/resend-sms`).
  - `SaleSuccessDialog` displaying official invoice number (`INV-XXXXXX`), high-contrast cash change due badge, 1-tap thermal reprint, and new sale restart.
- [x] **100% Passing Automated Tests**:
  - 28/28 Flutter mobile POS tests passing across `pos_auth_test.dart`, `pos_catalog_cart_test.dart`, `pos_checkout_widget_test.dart`, `pos_payment_test.dart`, `pos_payment_widget_test.dart`, and `widget_test.dart`.
  - 97/97 Laravel backend tests passing (`php artisan test`).
  - 41/41 Desktop POS tests passing (`npm test`).
  - 22/22 Consumer mobile tests passing (`flutter test`).
  - 28/28 Handheld staff POS tests passing (`flutter test`).
  - **Total: 188/188 passing tests across the entire omnichannel ecosystem**.

---

### Milestone 26: Mobile POS Offline SQLite WAL Durability & Bidirectional Delta Sync (`✅ COMPLETED`)
- [x] **Local Embedded SQLite Database (`sqflite`)**:
  - Embedded WAL-mode SQLite database engine implemented in `PosDatabaseService` (`pos_database_service.dart`).
  - Durable offline schema managing `products`, `offline_sales`, `sync_queue`, and `sync_checkpoints`.
  - Transaction-safe offline sales queue generator creating unique sales records with JSON-serialized item lines and payment tenders.
  - Headless mock fallback automatically enabling seamless, robust unit & widget testing without emulator dependencies.
- [x] **Resilient Offline-to-Online Sync Queue (`posSyncProvider`)**:
  - Background synchronization manager in `pos_sync_provider.dart` actively monitoring network reachability.
  - Batch offline sales push to `/api/v1/sync/push` with retry idempotency and queue purging on confirmation.
  - Delta catalog updates pulled via `/api/v1/sync/pull` with revision checkpoint advancing and local catalog upsert.
  - Interactive `SyncStatusRibbon` providing real-time telemetry ("CLOUD SYNC ACTIVE" vs "OFFLINE - X SALES PENDING SYNC") with manual 1-tap trigger.
- [x] **100% Passing Automated Tests**:
  - 8/8 tests in `pos_database_sync_test.dart` passing all assertions for SQLite caching, sync queue transitions, and delta pulls.

---

### Milestone 27: Mobile POS Cash Drawer Float, Shift Management, X/Z Reports & EOD (`✅ COMPLETED`)
- [x] **Mobile Shift Data Architecture & Reporting Engine**:
  - Structured `ShiftSessionReport` model with balance calculations (`isBalanced`, `isOver`, `isShort`), JSON serialization, and audit metadata.
  - Binary ESC/POS receipt generation in `EscPosService.buildShiftReportBytes` formatted for both 58mm and 80mm portable thermal printers.
- [x] **Staff Shift Notifier (`posShiftProvider`)**:
  - `loadCurrentSummary`: Pulls live transaction and tender breakdown from `/api/v1/cash-sessions/current` with offline fallback.
  - `generateXReport`: Produces non-closing mid-day audit summaries with thermal receipt queuing.
  - `closeShift`: Calculates physical cash count discrepancy against expected drawer balance, calls `/api/v1/cash-sessions/close`, issues official Z-Report, and locks terminal.
- [x] **Interactive Cash Reconciliation UI (`ShiftCloseDialog`)**:
  - Clean cash count input dialog with fast preset chips (`Exact`, `+1,000`, `+5,000`), real-time discrepancy computation with visual badges (`BALANCED`, `OVER`, `SHORT`), notes field, and post-closeout confirmation card.
  - Seamlessly embedded in `PosHomeScreen` alongside mid-shift X-Report bottom sheet.
- [x] **100% Passing Automated Tests**:
  - 7/7 tests in `pos_shift_test.dart` passing all assertions.
  - 43/43 Flutter mobile POS tests passing (`apps/flutter-mobile-pos`).
  - 97/97 Laravel backend tests passing (`backend/laravel-api`).
  - 41/41 Desktop POS tests passing (`apps/windows-pos`).
  - 22/22 Consumer mobile tests passing (`apps/mobile-pos`).
  - **Total: 203/203 passing tests across the entire omnichannel ecosystem**.

---

### Milestone 28: Handheld Mobile POS Operations Parity (Sales History, Refunds, Cross-Store Stock, VIP CRM & Cash Drops) (`✅ COMPLETED`)
- [x] **Backend Cash Drawer Movements Engine (`backend/laravel-api`)**:
  - Migration `2026_11_21_000001_create_cash_session_movements_table.php` and `CashSessionMovement` model tracking `cash_in` (float pay-ins), `cash_out` (safe cash drops), and `petty_cash` (store expenses) per open shift.
  - Added `GET /api/v1/cash-sessions/movements` and `POST /api/v1/cash-sessions/movements` to `CashSessionController` with live recalculation of `expected_cash = opening_float + cash_sales + cash_in_total - cash_drop_total - total_refunds` across current summaries, X-Reports, and Z-Reports.
- [x] **Sales History, Thermal Reprint & SMS Re-Dispatch (`SalesHistoryScreen` & `posSalesHistoryProvider`)**:
  - Merged local SQLite (`PosDatabaseService.recordCompletedSale` / `getLocalSalesHistory`) and cloud `/api/v1/sales` transaction ledger with invoice/customer search and `All / Synced / Pending / Refunded` filter chips.
  - Detail bottom sheet with 1-tap 58mm/80mm ESC/POS thermal reprint, editable mobile SMS e-receipt resend (`/api/v1/sales/{uuid}/resend-sms`), and direct return initiation.
- [x] **In-Store Refunds & Exchanges (`RefundDialog` & `EscPosService.buildRefundReceiptBytes`)**:
  - Invoice lookup (`/api/v1/sales/{uuid}`) with 1-tap recent invoice selection, line-item return quantity steppers, preset return reason chips, branch inventory restock toggle, `/api/v1/sales/{uuid}/refund` dispatch, shift cash impact updates, and ESC/POS Customer Refund Voucher printing.
- [x] **Cross-Branch Boutique Stock Locator (`BranchStockDialog` & `posBranchStockProvider`)**:
  - Real-time multi-branch inventory modal querying `/api/v1/products/{id}/cross-store-stock` across Colombo Flagship, Kandy Galleria, and Galle Fort Boutique with on-hand, reserved, and available counts, accessible from both the Cashier Hub and every catalog product card.
- [x] **VIP Customer CRM & Automatic Tier Discounting (`CustomerCrmDialog` & `posCustomerProvider`)**:
  - Replaced basic customer prompt with tabbed VIP Directory Search (`/api/v1/customers`) and Quick Register (+100 welcome VIP points via `POST /api/v1/customers`).
  - Automatically applies VIP tier privilege discounts on cart attachment (`Gold Elite 5% OFF`, `Black Diamond 10% OFF`) and cleanly resets on detach.
- [x] **Petty Cash & Safe Drops Modal (`CashMovementDialog` & `EscPosService.buildCashMovementBytes`)**:
  - Interactive modal for Safe Cash Drops, Petty Cash Expenses, and Float Pay-Ins with preset denomination chips, live expected drawer cash preview, shift movement ledger, and ESC/POS cash drop voucher printing.
- [x] **100% Passing Automated Tests**:
  - 12/12 new tests in `pos_operations_parity_test.dart` passing (55/55 Flutter handheld POS tests).
  - 2/2 new backend tests in `CashSessionTest.php` passing (99/99 Laravel backend tests, 776 assertions).
  - 41/41 Desktop POS tests (`apps/windows-pos`) and 22/22 Consumer mobile tests (`apps/mobile-pos`).
  - **Total: 217/217 passing tests across the entire omnichannel ecosystem**.

---

### Milestone 29: Omnichannel Promotions, Coupon Codes & Seasonal Campaigns Engine (`✅ COMPLETED`)
- [x] **Enterprise Promotions & Redemptions Schema (`backend/laravel-api`)**:
  - Migration `2026_11_21_000002_create_promotions_tables.php` establishing `promotions` and `promotion_redemptions` tables supporting `percentage` (with max cap), `fixed_amount`, and `buy_x_get_y` (cheapest free unit) rules, channel targeting (`web`, `mobile`, `pos`), VIP tier gating (`silver`, `gold`, `black`), category scoping, date windows, and global/per-customer usage limits.
  - Eloquent models `Promotion` (with `live()` scope and `discount_label` accessor) and `PromotionRedemption`.
- [x] **Promotion Calculation & Atomic Redemption Engine (`PromotionService`)**:
  - `validateAndCalculate`: Validates eligibility, dates, limits, channel, VIP tier hierarchy, minimum spend, and calculates exact discount.
  - `redeem`: Atomic row-locked (`lockForUpdate`) usage counter increment and redemption audit creation, automatically invoked from `BillingService::processSale` when `promotion_code` is provided.
- [x] **REST APIs & Filament ERP Control Panel (`PromotionController` & `PromotionResource`)**:
  - Public APIs: `GET /api/v1/promotions/active`, `POST /api/v1/promotions/validate`.
  - Staff/ERP APIs: `GET /api/v1/promotions`, `POST /api/v1/promotions`, `PATCH /api/v1/promotions/{uuid}/toggle`.
  - Filament v3 `PromotionResource` under *Sales & Fulfillment* with reactive rule form, redemption progress column, and 1-click **Pause / Activate** action.
- [x] **Web Storefront & Handheld Staff POS Coupon Checkout**:
  - Web Storefront cart drawer (`layout.blade.php` + `WebStoreController.php`): Live Promo / Coupon Code accordion validating against `/api/v1/promotions/validate` and stacking cleanly ahead of Gift Card redemptions.
  - Handheld Staff POS (`pos_cart_provider.dart`, `pos_checkout_screen.dart`, `pos_payment_provider.dart`): Promo code dialog with quick campaign chips (`LUXE15`, `WELCOME2500`, `FLASH20`, `B2G1`), removable emerald applied discount badge, offline fallback evaluation, and `promotion_code` transmission on checkout.
- [x] **100% Passing Automated Tests**:
  - 5/5 tests in `PromotionTest.php` passing (104/104 Laravel backend tests, 810 assertions).
  - 3/3 tests in `pos_promotion_test.dart` passing (58/58 Flutter handheld POS tests).
  - 41/41 Desktop POS tests (`apps/windows-pos`) and 22/22 Consumer mobile tests (`apps/mobile-pos`).
  - **Total: 225/225 passing tests across the entire omnichannel ecosystem**.

---

## 3. Technology Stack & Design Tokens

| Channel | Framework / Stack | Styling / Theme | Key Dependencies |
| :--- | :--- | :--- | :--- |
| **Web Store** | Laravel 11 Blade + Alpine.js | TailwindCSS (Editorial Light) | Google Fonts Outfit & Inter |
| **Consumer Mobile App** | Flutter 3.x (iOS & Android) | Pure Custom Material 3 Light | Riverpod, Google Fonts, SQLite |
| **Handheld Mobile POS** | Flutter 3.x (Handheld & Tablet) | Cashier Dark/Light Hybrid POS | Riverpod, mobile_scanner, blue_thermal_printer, sqflite |
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

## 4. Current Execution Roadmap (4-Stage Ordered Delivery)

As requested, development progresses sequentially across the core platform channels:

### 🌟 Stage 1: Web Storefront Deep-Dive & Commerce (`backend/laravel-api`) — `✅ COMPLETED`
> **Consolidation**: The Web Storefront is combined directly inside `backend/laravel-api`, running from the single project and identical MySQL database (`smartshop_pos`). Zero submodule overhead, zero duplicated models.
- [x] Consolidate Web Store views, routes, and controllers inside `backend/laravel-api`.
- [x] Implement luxury editorial product detail view (`/product/{id}`) with inventory availability, warranty tags, and serial tracking chips.
- [x] Standardize Cart drawer with Alpine.js reactivity, guest checkout option, and subtotal calculation.
- [x] Multi-step customer registration wizard with 100 VIP welcome loyalty points.
- [x] Integrate Laravel Reverb WebSockets client (Port 8080) for real-time stock availability and order toasts.
- [x] Verified public e-receipt page at `/receipt/{invoice}` with customer phone number masking (`077 •••• 567`).
- [x] End-to-end checkout validation: Guest order placement, VIP points deduction, atomic inventory decrement in MySQL, and SMS link generation.

### 💻 Stage 2: In-Store Cashier POS System (`apps/windows-pos`) — `✅ COMPLETED`
> **Counter Hardware & Terminal Integration**: Dedicated desktop POS station for retail staff.
- [x] Verify cashier shift workflow (opening float, cash sessions, mid-day drops, X/Z reports).
- [x] Test hardware barcode scanner wedge (<60ms key bursts) and instant line item addition.
- [x] Test ESC/POS thermal printer engine (58mm/80mm slips) and RJ11 drawer kick pulse.
- [x] Test multi-lane held bills cloud sync and retrieval across registers.
- [x] Verify atomic inventory synchronization against the central MySQL database on sale completion.
- [x] 100% test pass rate across all 41 Electron and React unit/integration tests (`npm test`).

### 📱 Stage 3: Consumer Mobile App Harmonization (`apps/mobile-pos`) — `✅ COMPLETED`
> **Customer Mobile Experience**: Flagship luxury shopping on iOS and Android.
- [x] Connect Flutter Riverpod state to central persistent notification inbox API (`GET /api/v1/customer/notifications`).
- [x] Push notification read state synchronization (`POST /api/v1/customer/notifications/{uuid}/read`).
- [x] Hardware device push token registration (`POST /api/v1/customer/device-token`).
- [x] Enforce zero-leakage security (zero staff PIN login or counter hardware pairing on consumer mobile).
- [x] End-to-end catalog browsing, cart steppers, guest mode, orders ledger, and VIP card.
- [x] 100% test pass rate across all 22 Flutter automated tests (`flutter test`).

### 🛒 Stage 4: Dedicated Handheld Flutter Mobile POS System (`apps/flutter-mobile-pos`) — `✅ COMPLETED`
> **Roaming Staff & Handheld Counter Terminal**: Dedicated staff POS application for roaming associates, popup shops, trunk shows, and line-busting.
- [x] Scaffold dedicated Flutter Mobile POS application in `apps/flutter-mobile-pos`.
- [x] Staff PIN pad authentication (`1234`), biometric unlock, and terminal device code binding (`ROAMING-01`).
- [x] Continuous camera barcode scanning viewfinder (`mobile_scanner`) and Bluetooth scanner wedge.
- [x] Fast-touch luxury catalog with variant selectors and real-time cross-store stock inspection.
- [x] Handheld line-busting: Scan items in aisle, hold bill with QR/token, and retrieve on counter POS.
- [x] Split tender modal (Cash with quick denominations, Bluetooth mPOS card, LankaQR, VIP Gift Cards).
- [x] Bluetooth SPP/BLE portable thermal printer driver (58mm/80mm) and instant SMS e-receipt dispatch.
- [x] Offline SQLite WAL database with background sync queue (`/api/v1/sync/push` & `/api/v1/sync/pull`).
- [x] Mobile shift management: Drawer float entry, petty cash drops, X-reports, and Z-report closeout.
- [x] 100% test pass rate across 43 Flutter unit, provider, and widget test suites.



