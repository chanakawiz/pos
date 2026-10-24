# OmniLuxe Store Enterprise Omnichannel Platform — System Architecture Specification

> **System Scope**: Multi-Platform Flagship Retail Ecosystem  
> **Platform Version**: 3.2.0  
> **Brand & Identity**: OmniLuxe Store (`omniluxe-store`)  
> **Aesthetic Theme**: Editorial Light Luxury (Ivory `#FBFBF9`, Warm Cream `#F4F2EB`, Forest Green `#233C32`, Deep Ink `#242B27`, Hairline `#E3E5DF`, Sage `#7B846D`, Champagne Gold `#C29B38`)  
> **Cart Terminology**: Standardized to **Cart** across all consumer platforms  
> **Customer Access**: Guest Explorer Mode + Multi-Step VIP Onboarding  

---

## 1. Executive Omnichannel Architecture

OmniLuxe Store connects four specialized application layers into a unified real-time retail engine:

```text
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                      OMNILUXE STORE MULTI-PLATFORM ECOSYSTEM                           │
├───────────────────────────────────────────┬────────────────────────────────────────────┤
│         1. CONSUMER ONLINE CHANNELS       │         2. IN-STORE CASHIER POS TERMINAL   │
│                                           │                                            │
│  A. Web Storefront (Blade / Alpine / CSS) │  Dedicated Desktop POS (Electron / React)  │
│     • Routes: /, /shop, /login, /account  │  • Windows & macOS counter terminals       │
│     • OmniLuxe Privilege digital hub      │  • Cashier PIN quick authentication (1234) │
│     • Public verifiable SMS e-receipts    │  • Barcode scanner wedge (<60ms burst)     │
│                                           │  • Thermal ESC/POS slip (80mm / 58mm)      │
│  B. Mobile App (Flutter 3.x / Riverpod)   │  • RJ11 cash drawer kickout pulse          │
│     • iOS & Android flagship shopping     │  • Multi-lane cloud held bills             │
│     • 5-Tab luxury customer journey       │  • Offline SQLite WAL local durability     │
│     • Animated gold monogram splash       │  • Register device pairing (COUNTER-01)    │
│     • Offline order archiving in SQLite   │                                            │
├───────────────────────────────────────────┴────────────────────────────────────────────┤
│                       3. CENTRAL CLOUD ERP & BACKEND API                               │
│                       (Laravel 11 / MySQL 8 / Redis at Port 8000)                      │
│                                                                                        │
│  • RESTful API Gateway (/api/v1) with Sanctum authentication & Spatie RBAC             │
│  • Filament v3 ERP Admin Control Room (/admin) for catalog, inventory, and POs         │
│  • Real-time stock movement ledger with atomic reservations on web & POS sales         │
│  • Customer CRM, VIP loyalty ledger, and phone number privacy masking                  │
│  • Verified SMS E-Receipt Engine (Notify.lk, Twilio, Dialog, Mobitel, Mock drivers)    │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. End-to-End System Component Diagram

```mermaid
flowchart TB
    subgraph Consumers["Customer Channels (Online Shoppers)"]
        CustomerWeb["Luxury E-Commerce Web Storefront\n(Laravel Blade • Alpine.js • Tailwind Luxe)"]
        CustomerMobile["Consumer Mobile Shopping App\n(Flutter iOS & Android • Riverpod • SQLite)"]
    end

    subgraph InStoreStaff["In-Store Staff Channels"]
        DesktopPOS["Dedicated In-Store Cashier POS\n(Electron • React 18 • TypeScript • better-sqlite3)"]
        CounterHardware["Counter Peripherals\n(Barcode Gun • 80mm Thermal Printer • RJ11 Cash Drawer)"]
        DesktopPOS --- CounterHardware
    end

    subgraph CentralEngine["Central Cloud ERP & REST Engine (Laravel 11)"]
        APIGateway["REST API Gateway (/api/v1)\nSanctum Token Auth • Device Headers"]
        FilamentAdmin["Filament v3 ERP Admin Panel (/admin)\nMulti-Store • POs • Shifts • Audit Ledgers"]
        InventoryLedger["Atomic Inventory & Movement Ledger\nReal-Time Decrement • Safety Stock • Serial Tracking"]
        BillingEngine["Billing, Invoicing & Digital E-Receipt Engine"]
        CustomerCRM["Customer CRM & VIP Loyalty Club\nPhone Masking • Points Engine (1 Pt = Rs. 10)"]
        SmsEngine["SMS E-Receipt Gateway Engine\nNotify.lk • Twilio • Dialog • Mobitel Driver"]
    end

    subgraph StorageLayer["Data Persistence & Queues"]
        MasterMySQL[("MySQL 8+ Primary Database\n25 Core Migrations • UUIDs")]
        RedisQueue[("Redis Cache, Sessions & Queues")]
    end

    CustomerWeb --> CentralEngine
    CustomerMobile <-->|REST API (/api/v1)| APIGateway
    DesktopPOS <-->|Bidirectional Offline Sync| APIGateway

    APIGateway --> BillingEngine
    APIGateway --> InventoryLedger
    APIGateway --> CustomerCRM
    FilamentAdmin --> InventoryLedger
    FilamentAdmin --> BillingEngine

    BillingEngine --> SmsEngine
    SmsEngine -.->|Verified SMS E-Receipt| Consumers
    SmsEngine -.->|SMS Bill Link| InStoreStaff

    CentralEngine --> MasterMySQL
    CentralEngine --> RedisQueue
```

---

## 3. Detailed Architecture of Each Application

### 3.1 Consumer Mobile Shopping App (`apps/mobile-pos`)
* **Technology**: Flutter 3.27+ with Dart 3.6, Flutter Riverpod state management.
* **Architecture Pattern**: Feature-driven clean architecture with reactive StateNotifiers (`CartNotifier`, `CatalogNotifier`, `AuthNotifier`, `SyncNotifier`).
* **Persistence**: Local SQLite database via `sqflite` for offline catalog caching, bag state, and completed order history.
* **Key Persona**: Online luxury shopper & VIP member.
* **Key Features**:
  * 5-Tab flagship shopping layout (`Home`, `Explore`, `Bag`, `Orders`, `VIP Club`).
  * Hero lifestyle lookbook carousel & premier brand spotlights (Apple, Nike, Toyota, Studio Ceylon, Zara).
  * Gold-foil **OmniLuxe Privilege** digital loyalty card.
  * Instant SMS order confirmation & public receipt links.

### 3.2 Flagship Web Storefront (`backend/laravel-api` & `apps/web-store`)
* **Technology**: Laravel 11 Blade templates, Alpine.js reactive components, TailwindCSS with Obsidian Dark Luxury styling tokens.
* **Architecture Pattern**: Server-side rendered luxury storefront with micro-reactive Alpine.js drawers (slide-over bag, login modal, search).
* **Key Persona**: Web visitors, corporate clients, and online VIP shoppers.
* **Key Features**:
  * Multi-vertical flagship lookbook and department filters.
  * Customer registration with **100 Welcome Loyalty Points**.
  * Member hub at `/account` displaying order ledger and digital VIP privilege card.
  * Verifiable public e-receipt lookup at `/receipt/{invoice}` with phone number privacy protection (`077 •••• 567`).

### 3.3 Dedicated In-Store Cashier POS (`apps/windows-pos`)
* **Technology**: Electron, React 18, TypeScript, TailwindCSS, Vite.
* **Architecture Pattern**: Context-isolated dual-process architecture:
  * **Renderer Process**: High-throughput cashier UI, Zustand state store, Web Audio synthesizer chimes.
  * **Main Process**: `better-sqlite3` native database, raw ESC/POS thermal raster driver, USB/Bluetooth barcode scanner wedge listener, serial scale parser.
* **Key Persona**: Store cashiers and counter supervisors.
* **Key Features**:
  * Numeric PIN pad authentication (`1234`) tied to counter device codes (`COUNTER-01`).
  * Instant sub-60ms barcode gun input detection.
  * ESC/POS 80mm & 58mm thermal receipts with warranty serial numbers.
  * RJ11 cash drawer kickout pulse on cash finalization.
  * Multi-lane cloud held bills for high-traffic queues.

### 3.4 Central ERP & REST API Engine (`backend/laravel-api`)
* **Technology**: Laravel 11, Filament v3 Admin Panel, MySQL 8, Redis, Spatie Permissions.
* **Architecture Pattern**: Domain-driven service layer with immutable audit ledgers.
* **Key Persona**: Super Admins (`admin@omniluxe.store`), Store Managers (`manager@smartshop.com`), and System Auditors.
* **Key Features**:
  * Complete control room at `http://127.0.0.1:8000/admin`.
  * Multi-store catalog and serialized inventory ledger (`stock_movements`).
  * Atomic inventory reservation guaranteeing zero overselling across web, mobile, and counter channels.
  * Pluggable SMS gateway dispatching tamper-evident digital bill links.

---

## 4. Omnichannel Data Flow: Real-Time Stock Sync

```mermaid
sequenceDiagram
    autonumber
    actor Shopper as Mobile / Web Customer
    participant MobileApp as OmniLuxe Mobile App
    participant CentralERP as Central Laravel ERP (Port 8000)
    participant DesktopPOS as Counter Cashier POS
    actor Cashier as Store Cashier

    Note over Shopper,CentralERP: Online Purchase
    Shopper->>MobileApp: Add Nike Pegasus 40 (UK 9) to Bag & Checkout
    MobileApp->>CentralERP: POST /api/v1/sales (Order submission)
    CentralERP->>CentralERP: Atomically decrement stock in inventories table
    CentralERP->>CentralERP: Record immutable entry in stock_movements ledger
    CentralERP-->>MobileApp: Return 201 Created (Order ORD-2026-001)

    Note over DesktopPOS,Cashier: Real-Time In-Store Stock Sync
    Cashier->>DesktopPOS: Cashier scans barcode on counter terminal
    DesktopPOS->>CentralERP: Query real-time available stock
    CentralERP-->>DesktopPOS: Return current stock (reflecting online purchase)
    DesktopPOS->>Cashier: Display verified live inventory
```
