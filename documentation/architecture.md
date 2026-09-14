# SmartShop POS — System Architecture Specification

## 1. Architectural Overview

SmartShop POS is architected as an **offline-first, distributed retail system** with centralized cloud management. The system is designed to provide high reliability, ensuring that store checkout lanes never stop operating even during prolonged internet outages, while maintaining complete data integrity and inventory accuracy at the central backend.

```mermaid
flowchart TD
    subgraph StoreLevel["Store / Branch Environment"]
        subgraph Terminal1["Lane 1: Windows Desktop POS"]
            W1_UI["React 18 + Tailwind POS UI"]
            W1_State["Zustand Store (Cart, Cashier, Sync)"]
            W1_Bridge["Preload IPC Bridge (Context Isolation)"]
            W1_Main["Electron Main Process"]
            W1_DB[("Local SQLite Database")]
            W1_Sync["Background Sync Worker"]
            W1_UI --> W1_State
            W1_State --> W1_Bridge
            W1_Bridge --> W1_Main
            W1_Main --> W1_DB
            W1_Main --> W1_Sync
        end

        subgraph Terminal2["Mobile POS: iPad / iPhone"]
            F1_UI["Flutter Material 3 UI"]
            F1_State["Riverpod State Controller"]
            F1_DB[("Mobile SQLite (sqflite)")]
            F1_Sync["Dio Sync Engine"]
            F1_UI --> F1_State
            F1_State --> F1_DB
            F1_State --> F1_Sync
        end

        subgraph Hardware["Peripherals"]
            ThermalPrinter["Thermal Receipt Printer (80mm/58mm)"]
            BarcodeScanner["Barcode / 2D Scanner (HID/Serial)"]
            CashDrawer["Cash Drawer (RJ11 Kickout)"]
            W1_Main -.-> ThermalPrinter
            W1_Main -.-> CashDrawer
            BarcodeScanner -.-> W1_UI
        end
    end

    subgraph CloudLevel["Central Cloud / Data Center"]
        subgraph LaravelApp["Laravel 11 Enterprise Backend"]
            API_Gateway["REST API Gateway (/api/v1)"]
            Auth_Guard["Sanctum Auth & Device Verification"]
            Sync_Service["Idempotent Sync Service"]
            Billing_Service["Billing & Payment Engine"]
            Inventory_Service["Stock Movement & Locking Engine"]
            Filament_Admin["Filament 3 Admin Dashboard"]
        end

        subgraph Databases["Data Persistence & Queues"]
            MySQL_Master[("MySQL 8+ Primary Database")]
            Redis_Broker[("Redis Cache, Queues & Reverb")]
        end

        API_Gateway --> Auth_Guard
        Auth_Guard --> Sync_Service
        Auth_Guard --> Billing_Service
        Billing_Service --> Inventory_Service
        Filament_Admin --> MySQL_Master
        Sync_Service --> MySQL_Master
        Billing_Service --> MySQL_Master
        Inventory_Service --> MySQL_Master
        Sync_Service --> Redis_Broker
    end

    W1_Sync <===>|"HTTPS / JSON (Token + Device UUID)"| API_Gateway
    F1_Sync <===>|"HTTPS / JSON (Token + Device UUID)"| API_Gateway
```

---

## 2. Component Design & Responsibilities

### 2.1 Windows Desktop POS Application
- **Runtime**: Electron with Vite, React 18, and TypeScript.
- **Security Boundary**:
  - `contextIsolation: true`
  - `nodeIntegration: false`
  - All hardware access (printers, cash drawers, SQLite database) is encapsulated in Electron's Main process and exposed to the Renderer process strictly via typed `contextBridge.exposeInMainWorld('posApi', {...})`.
- **Local Persistence**: Embedded SQLite (`better-sqlite3`) in the Main process. Stores cached catalogs, offline transactions, and local sync queue.
- **State Management**: Zustand stores decoupled into `useCartStore`, `useAuthStore`, `useCatalogStore`, and `useSyncStore`.

### 2.2 Mobile POS (iPad / iPhone)
- **Runtime**: Flutter 3.x with Dart.
- **UI Framework**: Material 3 responsive layout adapting seamlessly between tablet landscape split-view and mobile portrait view.
- **Local Persistence**: `sqflite` for offline catalog and transaction queuing.
- **API Client**: `dio` with interceptors for automatic Bearer token injection, device UUID headers, and network retry handling.

### 2.3 Shared Backend & Admin System
- **Framework**: Laravel 11 on PHP 8.3+ / 8.4+.
- **Authentication**: Laravel Sanctum supporting both user sessions and cryptographically tied device tokens.
- **Authorization**: Spatie Laravel Permission with 4 core roles:
  - `Super Admin`: Full system access across all stores and configurations.
  - `Admin`: Regional or store-group management.
  - `Manager`: Store-specific management, inventory receiving, adjustments, refunds.
  - `Cashier`: Billing, register open/close, and customer lookups.
- **Admin Panel**: Filament v3 with reactive forms, data tables, metrics widgets, and CSV/PDF export.

---

## 3. Reliability & Non-Functional Requirements

1. **Sub-second Checkout**:
   - Product scanning and cart addition occurs in `< 10ms` in local memory and SQLite.
   - Offline checkout completes in `< 100ms` with local receipt generation.
2. **Zero Data Loss Guarantee**:
   - Every transaction written to local SQLite before triggering receipt printing.
   - Idempotent API guards prevent duplicate sales on server reconnection.
3. **Audit Compliance**:
   - Every stock level change generates an immutable `StockMovement` row with movement type, delta, before/after values, and originating transaction UUID.
