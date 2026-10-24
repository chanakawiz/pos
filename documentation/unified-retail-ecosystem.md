# SmartShop Omnichannel Retail Ecosystem — Master Architectural Blueprint

> **System Scope**: Consumer E-Commerce Web Store + Consumer Mobile App (Flutter) + Dedicated Desktop Cashier POS (Windows/Mac) + Central ERP & Filament v3 Admin + Real-Time Omnichannel Inventory + SMS Digital E-Receipts
> **Document Version**: 3.0.0
> **Target Business Profile**: High-End Flagship Multi-Department & Lifestyle Retailers (Smartphones & Tech, Designer Fashion & Apparel, Footwear & Sneakers, Luxury Automobili & High-Value Assets)
> **Commercial Readiness**: Turnkey Solution Ready for Commercial Licensing & Deployment to Established Retail Enterprises

---

## 1. Executive Summary & Commercial Positioning

SmartShop is an enterprise-grade omnichannel retail platform designed for **premier multi-department retail chains, luxury fashion houses, flagship electronics stores, and high-value asset dealers**.

Unlike basic point-of-sale systems built for small corner groceries or simple kiosks, SmartShop delivers a unified multi-channel retail infrastructure that connects:
1. **Consumer Mobile Shopping App (Flutter iOS & Android)**: An editorial, dark luxury mobile store mirroring the web experience. Shoppers discover collections, review variant matrices (sizes, storage, colors), manage their bag, checkout with online card/COD, and receive verified SMS digital e-receipts and warranty cards.
2. **Customizable E-Commerce Web Storefront (`apps/web-store` & Central Web Store)**: High-converting luxury web storefront providing instant island-wide ordering, real-time stock availability, and automated sync with central ERP inventory.
3. **Dedicated In-Store Cashier POS (Windows & macOS Desktop)**: A counter checkout terminal designed exclusively for store cashiers and staff, featuring barcode gun scanning, thermal ESC/POS receipt printing, cash drawer kickout, customer-facing pole display, staff shifts (X/Z reports), and offline SQLite durability.
4. **Central Cloud ERP & Filament v3 Admin (`/admin`)**: Unified multi-branch control panel for catalog management, stock movement ledgers, purchase orders, vendor procurement, role-based permissions, and commercial analytics.
5. **Customer Protection & Verified SMS E-Receipts Gateway**: Modular driver interface (supporting Notify.lk, Twilio, Dialog, Mobitel, and Mock modes) that dispatches instant digital bill summaries and tamper-evident warranty links to customers via SMS.

---

## 2. Omnichannel Architecture Diagram

```mermaid
flowchart TB
    subgraph Consumers["Customer Channels (Omnichannel Shoppers)"]
        CustomerWeb["Luxury E-Commerce Web Store\n(Next-Gen Dark Storefront • Real-Time Stock)"]
        CustomerMobile["Consumer Mobile App (Flutter)\n(iOS / Android • Discover • Bag • Orders • E-Receipts)"]
        InStoreCustomer["In-Store Boutique Shopper\n(SMS Verified Bill • Warranty Link • Click & Collect)"]
    end

    subgraph Frontends["Frontend Experience Layer"]
        WebStoreApp["Web Storefront (Blade / Alpine / Tailwind)\nEditorial Lookbook • Cart • PayHere / COD"]
        FlutterApp["Consumer Mobile App (Flutter Riverpod)\nDark Luxury Theme • Variant Picker • Offline Orders"]
        DesktopPOS["Dedicated In-Store Cashier POS (Electron / React)\nWindows / Mac • Barcode Gun • Thermal Slip • Cash Drawer"]
    end

    subgraph CentralBackend["Central ERP & Core Engine (Laravel 11)"]
        APIGateway["REST API Gateway (/api/v1)"]
        FilamentAdmin["Filament v3 ERP Admin Panel (/admin)\nCatalog • Multi-Store Inventory • POs • Shifts • Audit"]
        InventoryLedger["Real-Time Inventory & Movement Ledger\nAtomic Reservation • Low-Stock Alerts • Serial Tracking"]
        BillingEngine["Billing, Invoicing & Digital E-Receipt Engine"]
        CustomerEngine["Customer CRM, Loyalty & Privacy Protection\nPhone Masking • Encrypted Ledgers"]
        SmsEngine["SMS E-Receipt Gateway Engine\nNotify.lk • Twilio • Dialog • Mobitel Driver"]
    end

    subgraph Persistence["Storage & Queues"]
        MasterDB[("MySQL 8+ Primary Database")]
        RedisCache[("Redis Cache, Queues & Events")]
    end

    CustomerWeb --> WebStoreApp
    CustomerMobile --> FlutterApp
    InStoreCustomer <--> DesktopPOS

    WebStoreApp --> CentralBackend
    FlutterApp <-->|REST API & Mobile Sync| APIGateway
    DesktopPOS <-->|Bidirectional Offline Sync| APIGateway

    APIGateway --> BillingEngine
    APIGateway --> InventoryLedger
    APIGateway --> CustomerEngine
    FilamentAdmin --> InventoryLedger
    FilamentAdmin --> BillingEngine

    BillingEngine --> SmsEngine
    SmsEngine -.->|Verified SMS Bill & Warranty Link| InStoreCustomer
    SmsEngine -.->|Mobile Order Confirmation SMS| CustomerMobile
    SmsEngine -.->|Web Order SMS Confirmation| CustomerWeb

    BillingEngine --> MasterDB
    InventoryLedger --> MasterDB
    CustomerEngine --> MasterDB
    CentralBackend --> RedisCache
```

---

## 3. High-End Retail Department Capabilities

| Department Vertical | Customer Mobile & Web Storefront | In-Store Desktop Cashier POS | Central ERP & Inventory Governance |
| :--- | :--- | :--- | :--- |
| **Smartphones & Flagship Tech**<br>*(Apple, Samsung, Sony, Anker)* | • Storage & color variant matrix<br>• Real-time stock status at flagship branch<br>• Technical specs & Apple Care warranty badges<br>• Verified SMS e-receipt with IMEI warranty link | • Mandatory IMEI / Serial capture per piece<br>• High-speed barcode / QR gun scan<br>• Multi-tender (Card + Cash + Installments)<br>• Warranty terms printed on 80mm thermal slip | • Serialized stock movement tracking<br>• Supplier warranty return logs<br>• Reorder point alerts for high-demand devices<br>• Margin analysis across brand tiers |
| **Designer Fashion & Apparel**<br>*(Studio Ceylon, Zara, Ralph Lauren, Levi's)* | • High-resolution lifestyle imagery & lookbook<br>• Size selector (XS, S, M, L, XL, XXL)<br>• Fitting room guide & fabric composition<br>• Express courier or click-and-collect at boutique | • Fast size & color lookup<br>• Fitting room Held Bills with multi-lane recall<br>• Exchange refunds & credit vouchers<br>• Customer loyalty tier discounts | • Size $\times$ Color variant matrix generator<br>• Seasonal markdown & collection promotion engine<br>• Category hierarchy (Haute Couture, Casual, Accessories) |
| **Footwear & Sneakers**<br>*(Nike, Adidas, Clarks, Puma)* | • UK / US / EU sizing matrix with fit notes<br>• Pair availability badge per shoe model<br>• Quick-add to bag with size confirmation<br>• Return & exchange policy FAQs | • Pair barcode scanning with box SKU validation<br>• Shoe size breakdown on receipt<br>• In-store try-on hold bills<br>• Split tender payment | • Per-size safety stock buffers<br>• Automatic purchase order drafting when key sizes hit low levels<br>• Supplier defect tracking |
| **Luxury Automobili & High-Value Assets**<br>*(Toyota, Land Rover, BYD, Honda)* | • Vehicle showcase with battery & engine specs<br>• Multi-million rupee price handling (`Rs. 48,500,000.00`)<br>• Reserve online with bank transfer or boutique deposit<br>• Official manufacturer warranty badges (3-8 yrs) | • Chassis / VIN number capture<br>• High-value split tenders (Bank Transfer + Card + Cash)<br>• Formal legal sales invoice generation<br>• Manager override authorization | • Chassis & VIN ledger with inspection history<br>• High-value asset insurance and warranty logs<br>• Detailed financial revenue analytics |

---

## 4. UI Design System & Aesthetics (Matching `store_web`)

The entire ecosystem adheres to an editorial, modern luxury aesthetic:

* **Obsidian Palette**:
  * Base Background: `#0A0E17` (Obsidian black)
  * Surface Container: `#111827` (Deep slate)
  * Card Background: `#162032` (Elevated dark card with subtle rounded radius)
  * Hairline Borders: `#223048` (1px subtle luxury borders, no harsh drop shadows)
  * Primary Accent: `#10B981` (Refined emerald for live stock and success states)
  * Luxury Gold Accent: `#D4AF37` (Champagne gold for brand badges, VIP tiers, and verified warranties)
  * Tech Accent: `#06B6D4` (Cyan for tech specifications and digital links)
* **Typography**:
  * Primary Headings: Outfit / Google Fonts sans-serif, bold, elegant letter-spacing
  * Body & Metadata: Inter, crisp, clean silver `#94A3B8` and white `#F8FAFC`
  * Sinhala Support: Noto Sans Sinhala for authentic bilingual representation

---

## 5. Omnichannel Workflow: E-Commerce Mobile App to Central Inventory

```mermaid
sequenceDiagram
    autonumber
    actor Customer as Mobile Shopper
    participant MobileApp as Consumer Mobile App (Flutter)
    participant CentralAPI as Central ERP API (Laravel 11)
    participant DesktopPOS as Desktop Cashier Terminal
    participant SMSGateway as SMS Digital Receipt Engine
    actor InStoreCustomer as In-Store Shopper

    Note over Customer,MobileApp: Mobile E-Commerce Journey
    Customer->>MobileApp: Browse Flagship Catalog & Select Size/Spec
    Customer->>MobileApp: Add Item to Bag (e.g. Nike Pegasus 40 - UK 9)
    Customer->>MobileApp: Proceed to Checkout (Enter Name & 077 123 4567)
    MobileApp->>CentralAPI: Submit Order (POST /api/v1/sales or /orders)
    CentralAPI->>CentralAPI: Atomically Decrement Inventory in Ledger
    CentralAPI->>SMSGateway: Dispatch SMS E-Receipt with Verified Link
    SMSGateway-->>Customer: SMS: "SmartShop: Order ORD-2026-981 Confirmed. Receipt: http://127.0.0.1:8000/receipt/ORD-2026-981"
    MobileApp->>Customer: Display OrderConfirmationScreen with QR Code

    Note over InStoreCustomer,DesktopPOS: Real-Time In-Store Synchronization
    InStoreCustomer->>DesktopPOS: In-Store Cashier Scans Barcode at Counter
    DesktopPOS->>CentralAPI: Query Real-Time Available Stock
    CentralAPI-->>DesktopPOS: Return Stock Updated Reflecting Online Order
    DesktopPOS->>CentralAPI: Settle Cashier Sale & Print Thermal Slip
    CentralAPI->>SMSGateway: Dispatch In-Store SMS Receipt to Customer
```

---

## 6. Commercial Turnkey Deployment Package

When delivering this system to a commercial enterprise, the deployment package includes:
1. **Cloud Central ERP & Admin**: Hosted on AWS / DigitalOcean / On-Premise Docker stack (`backend/laravel-api`).
2. **Branded Web Storefront**: Configured with custom domain, merchant logo, PayHere / Stripe payment keys, and cloud storage.
3. **Consumer Mobile Apps**: Distributed via Apple App Store & Google Play Store, branded for the enterprise.
4. **Lane Cashier Terminals**: Packaged Electron executable for Windows / macOS POS hardware (touchscreen POS, barcode gun, 80mm ESC/POS printer, RJ11 cash drawer).
5. **SMS Provider Integration**: Live API keys for Notify.lk, Dialog, or Twilio with custom sender ID (e.g., `SMARTSHOP`).
