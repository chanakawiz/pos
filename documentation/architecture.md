# SmartShop Enterprise Omnichannel Platform — System Architecture Specification

## 1. Architectural Overview

SmartShop is an **enterprise-grade, distributed retail & e-commerce platform** engineered for high-end multi-department retail enterprises. The platform is designed around four primary components:

1. **Consumer Mobile Shopping App (Flutter iOS/Android)**: Editorial lifestyle mobile store with catalog discovery, department filters, variant selectors, interactive bag, online card/COD checkout, and verified digital SMS receipts.
2. **Dedicated In-Store Cashier POS (Electron Windows/Mac)**: High-speed counter checkout terminal for retail cashiers, supporting barcode guns, thermal receipt printers, cash drawers, staff shifts (X/Z reports), and offline SQLite WAL durability.
3. **Customizable E-Commerce Web Storefront (`apps/web-store`)**: Public e-commerce website with real-time stock availability, luxury dark branding, and online card payments.
4. **Central Cloud ERP & Core Engine (Laravel 11 + Filament v3)**: Unified cloud administrative system managing inventory ledgers, purchase orders, multi-branch operations, customer privacy, and the SMS notification engine.

```mermaid
flowchart TD
    subgraph ConsumerLayer["Consumer Channels"]
        CustomerWeb["E-Commerce Web Storefront\n(apps/web-store • Port 8010 / Port 8000)"]
        CustomerMobile["Consumer Mobile App\n(apps/mobile-pos • Flutter iOS/Android)"]
    end

    subgraph StoreTerminalLayer["In-Store Staff Terminal Layer"]
        subgraph Terminal1["Lane 1: Windows / macOS Desktop POS (apps/windows-pos)"]
            W1_UI["React 18 + Tailwind POS UI"]
            W1_State["Zustand Store (Cart, Cashier, Sync)"]
            W1_Bridge["Preload IPC Bridge (Context Isolation)"]
            W1_Main["Electron Main Process"]
            W1_DB[("Local SQLite Database (better-sqlite3)")]
            W1_Sync["Background Sync Worker"]
            W1_UI --> W1_State
            W1_State --> W1_Bridge
            W1_Bridge --> W1_Main
            W1_Main --> W1_DB
            W1_Main --> W1_Sync
        end

        subgraph Hardware["Counter Peripherals"]
            ThermalPrinter["Thermal Receipt Printer (80mm/58mm ESC/POS)"]
            BarcodeScanner["Barcode / 2D Scanner (HID/Serial Gun)"]
            CashDrawer["Cash Drawer (RJ11 Kickout)"]
            W1_Main -.-> ThermalPrinter
            W1_Main -.-> CashDrawer
            BarcodeScanner -.-> W1_UI
        end
    end

    subgraph CloudLevel["Central Cloud / Data Center (backend/laravel-api)"]
        subgraph LaravelApp["Laravel 11 Enterprise Core Engine"]
            API_Gateway["REST API Gateway (/api/v1)"]
            Auth_Guard["Sanctum Auth & Device Verification"]
            Sync_Service["Idempotent Bidirectional Sync Engine"]
            Billing_Service["Billing & Invoicing Engine"]
            Inventory_Service["Stock Movement & Locking Ledger"]
            Filament_Admin["Filament 3 ERP Dashboard (/admin)"]
            Sms_Gateway["SMS E-Receipt Engine (Notify.lk / Twilio)"]
        end

        subgraph Databases["Data Persistence & Queues"]
            MySQL_Master[("MySQL 8+ Primary Database")]
            Redis_Broker[("Redis Cache & Background Queues")]
        end

        API_Gateway --> Auth_Guard
        Auth_Guard --> Sync_Service
        Sync_Service --> Inventory_Service
        Sync_Service --> Billing_Service
        Billing_Service --> Sms_Gateway
        Filament_Admin --> Inventory_Service
        Filament_Admin --> Billing_Service

        Inventory_Service --> MySQL_Master
        Billing_Service --> MySQL_Master
        LaravelApp --> Redis_Broker
    end

    CustomerWeb --> LaravelApp
    CustomerMobile <-->|REST API & Local SQLite| API_Gateway
    W1_Sync <-->|Bidirectional Offline Sync| API_Gateway
```

---

## 2. Component Directory Structure

```text
pos/
├── apps/
│   ├── mobile-pos/        # Consumer Mobile App (Flutter iOS/Android)
│   │   ├── lib/
│   │   │   ├── screens/store/  # Consumer Home, Catalog, Bag, Checkout, Orders
│   │   │   ├── providers/      # Riverpod Cart, Catalog, Auth
│   │   │   ├── data/           # Repositories & Models
│   │   │   └── core/           # DatabaseHelper (SQLite), AppColors, AppTheme
│   │   └── test/               # Automated unit & widget tests (21/21 passing)
│   ├── web-store/         # Public E-Commerce Web Storefront (Laravel / Blade)
│   │   └── resources/views/store/ # Home, Shop, Product, Cart, Checkout
│   └── windows-pos/       # Dedicated Desktop Cashier POS (Electron / React)
│       └── src/                # Cart, Barcode gun, Thermal printer, Cashier shifts
├── backend/
│   └── laravel-api/       # Central Cloud ERP & API Engine (Laravel 11)
│       ├── app/Filament/       # Filament v3 ERP Admin Resources
│       ├── app/Http/Controllers/
│       │   ├── Api/V1/         # POS REST API & Sync endpoints
│       │   └── WebStoreController.php # Integrated Storefront & Public E-Receipts
│       ├── database/seeders/   # Multi-Vertical Lifestyle & Department Seeders
│       └── routes/             # web.php (Storefront & /receipt), api.php
└── documentation/         # System specifications, architecture, and guides
```

---

## 3. Real-Time Inventory & Concurrency Management

- **Atomic Stock Reservation**: Online orders placed via the consumer mobile app or web storefront decrement central inventory immediately.
- **In-Store Over-the-Counter Priority**: Counter cashiers on Desktop POS query real-time stock balances; if offline, local SQLite stock counts are decremented and reconciled upon reconnection with revision versioning.
- **Serial & VIN Tracking**: Tech items (IMEI/Serial) and high-value vehicles (VIN/Chassis) capture unique identifiers at point of sale, preventing duplicate warranty registrations.
- **Public Verified E-Receipts**: All sales generate a cryptographic or unique reference (`/receipt/{invoice}`) accessible publicly with customer phone privacy masking.
