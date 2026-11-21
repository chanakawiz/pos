# OmniLuxe Store — REST API Specification (`/api/v1`)

> **Platform**: OmniLuxe Store Omnichannel Engine  
> **Base URL**: `http://localhost:8000/api/v1`  
> **Headers**:  
> `Accept: application/json`  
> `Content-Type: application/json`  
> Authenticated requests require: `Authorization: Bearer <sanctum_token>` and `X-Device-UUID: <device_uuid>` (for POS terminals).

---

## 1. Authentication & Device Endpoints

### 1.1 Cashier / User Login
- **Endpoint**: `POST /api/v1/auth/login`
- **Request Body**:
  ```json
  {
    "email": "cashier1@smartshop.com",
    "password": "password",
    "pin_code": "1234",
    "device_uuid": "550e8400-e29b-41d4-a716-446655440000"
  }
  ```
- **Response (200 OK)**:
  ```json
  {
    "status": "success",
    "token": "1|q7X9z0...bearer_token",
    "user": {
      "uuid": "2b2a6f23-6447-49f0-b5ec-8f43c3325c89",
      "name": "Sarah Connor",
      "email": "cashier1@smartshop.com",
      "role": "cashier",
      "store": {
        "uuid": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
        "name": "OmniLuxe Store Flagship",
        "currency_symbol": "Rs."
      }
    }
  }
  ```

### 1.2 Device Registration
- **Endpoint**: `POST /api/v1/devices/register`
- **Request Body**:
  ```json
  {
    "pairing_code": "COUNTER-01",
    "device_name": "Counter Lane 01 - Flagship POS",
    "device_type": "windows",
    "mac_address": "00:1B:44:11:3A:B7",
    "app_version": "1.0.0"
  }
  ```
- **Response (201 Created)**: Returns registered device UUID and store association.

---

## 2. Catalog & Cross-Branch Stock

### 2.1 List Products
- **Endpoint**: `GET /api/v1/products`
- **Query Parameters**: `search`, `category_id`, `brand_id`, `per_page`

### 2.2 Cross-Branch Stock Inquiry
- **Endpoint**: `GET /api/v1/products/{id}/cross-store-stock`
- **Purpose**: Cashier POS and mobile apps query inventory levels across all physical boutiques.
- **Response (200 OK)**:
  ```json
  {
    "status": "success",
    "product": {
      "id": 23,
      "name": "Apple iPhone 16 Pro Max 256GB (Space Black)",
      "sku": "TECH-IPH-16PM"
    },
    "stores": [
      {
        "store_id": 35,
        "store_code": "STORE-001",
        "store_name": "OmniLuxe Store Flagship",
        "quantity_on_hand": 55,
        "quantity_reserved": 0,
        "quantity_available": 55
      },
      {
        "store_id": 176,
        "store_code": "STORE-002",
        "store_name": "OmniLuxe Kandy Galleria",
        "quantity_on_hand": 20,
        "quantity_reserved": 0,
        "quantity_available": 20
      },
      {
        "store_id": 177,
        "store_code": "STORE-003",
        "store_name": "OmniLuxe Galle Fort Boutique",
        "quantity_on_hand": 12,
        "quantity_reserved": 0,
        "quantity_available": 12
      }
    ]
  }
  ```

### 2.3 Inter-Branch Stock Transfers
- **Endpoint**: `POST /api/v1/stock-transfers`
- **Request Body**:
  ```json
  {
    "source_store_id": 176,
    "destination_store_id": 35,
    "items": [
      { "product_id": 23, "quantity": 5 }
    ],
    "notes": "Inter-branch balance transfer to Colombo Flagship"
  }
  ```

---

## 3. VIP Gift Cards & Store Credit Engine

### 3.1 Public Balance Verification
- **Endpoint**: `POST /api/v1/gift-cards/verify`
- **Request Body**:
  ```json
  { "code": "GC-ABCD-1234-EFGH" }
  ```
- **Response (200 OK)**:
  ```json
  {
    "status": "success",
    "data": {
      "code": "GC-ABCD-1234-EFGH",
      "balance": 25000.00,
      "status": "active",
      "expires_at": "2027-11-01"
    }
  }
  ```

### 3.2 Cashier Gift Card Tender Redemption
- **Endpoint**: `POST /api/v1/gift-cards/redeem` (Authenticated)
- **Request Body**:
  ```json
  {
    "code": "GC-ABCD-1234-EFGH",
    "amount": 10000.00,
    "sale_id": 102
  }
  ```
- **Concurrency Protection**: Uses `lockForUpdate` database transaction ensuring zero race conditions or double deductions.

---

## 4. VIP Loyalty Tiers & Privilege Perks

### 4.1 Loyalty Tiers Breakdown
- **Endpoint**: `GET /api/v1/loyalty/tiers` (Public)
- **Response (200 OK)**:
  ```json
  {
    "status": "success",
    "data": {
      "silver": {
        "title": "Silver Privilege",
        "spend_threshold": 0,
        "points_multiplier": 1.0,
        "discount_percent": 0
      },
      "gold": {
        "title": "Gold Elite",
        "spend_threshold": 100000,
        "points_multiplier": 1.5,
        "discount_percent": 5
      },
      "black": {
        "title": "Black Diamond",
        "spend_threshold": 250000,
        "points_multiplier": 2.0,
        "discount_percent": 10
      }
    }
  }
  ```

---

## 5. Order Tracking & Returns Portal

### 5.1 Track Order by Invoice or Courier Number
- **Endpoint**: `GET /api/v1/orders/track/{identifier}` (Public)
- **Response (200 OK)**:
  ```json
  {
    "status": "success",
    "data": {
      "invoice_number": "INV-20261101-001",
      "fulfillment_status": "dispatched",
      "courier_name": "Pronto Luxury Logistics",
      "tracking_number": "PRONTO-LK-89412",
      "estimated_delivery_at": "2026-11-03",
      "items": [ ... ]
    }
  }
  ```

### 5.2 Submit Return Request (RMA)
- **Endpoint**: `POST /api/v1/orders/returns` (Public)
- **Request Body**:
  ```json
  {
    "invoice_number": "INV-20261101-001",
    "customer_phone": "0771234567",
    "customer_name": "Kasun Fernando",
    "items": [
      {
        "product_id": 23,
        "quantity": 1,
        "reason": "Size exchange for Colombo flagship"
      }
    ]
  }
  ```

---

## 6. Executive & Multi-Branch Analytics

### 6.1 Multi-Branch Performance Telemetry
- **Endpoint**: `GET /api/v1/reports/branch-performance` (Authenticated)
- **Response**: Aggregated revenue, COGS, gross margin %, orders count, AOV, and cashier reconciliation accuracy across all branches.

### 6.2 Stock Aging & Transfer Advisories
- **Endpoint**: `GET /api/v1/reports/stock-aging?limit=50` (Authenticated)
- **Response**: Products classified by turnover velocity (`Fast Mover`, `Steady`, `Slow Moving`, `Stagnant`) with inter-branch transfer recommendations.

---

## 7. Production Health & Liveness Audits

### 7.1 Liveness Probe
- **Endpoint**: `GET /health/live` (or `/api/v1/health/live`)
- **Status Code**: `200 OK`

### 7.2 Deep Readiness Audit
- **Endpoint**: `GET /health/ready` (or `/api/v1/health/ready`)
- **Status Code**: `200 OK` (Healthy) or `503 Service Unavailable` (Degraded)
- **Audited Components**: Database latency (ms), cache read/write, storage writeability, Reverb WebSockets configuration.

---

## 8. Cash Register Drawer Movements (Safe Drops, Petty Cash & Pay-Ins)

### 8.1 Record Drawer Cash Movement
- **Endpoint**: `POST /api/v1/cash-sessions/movements` (Authenticated)
- **Request Body**:
  ```json
  {
    "type": "cash_out",
    "amount": 10000.00,
    "reason": "Mid-Shift Safe Cash Drop",
    "reference": "DRP-8A2C1F",
    "notes": "Handed over to floor supervisor"
  }
  ```
- **Allowed `type` values**: `cash_in` (Float Pay-In), `cash_out` (Safe Cash Drop), `petty_cash` (Petty Cash Expense).
- **Response (201 Created)**: Returns the persisted `movement` record and recalculated shift `summary` (`cash_in_total`, `cash_drop_total`, `expected_cash`).

### 8.2 List Active Shift Cash Movements
- **Endpoint**: `GET /api/v1/cash-sessions/movements` (Authenticated)
- **Response (200 OK)**: Returns chronological movements for the cashier's open cash session alongside the live shift summary.

---

## 9. Omnichannel Promotions, Coupons & Seasonal Campaigns

### 9.1 List Live Active Campaigns
- **Endpoint**: `GET /api/v1/promotions/active?channel=web|mobile|pos` (Public)
- **Response (200 OK)**: Returns currently active, non-expired, non-exhausted promotions eligible for the requested channel.

### 9.2 Validate Coupon & Calculate Basket Discount
- **Endpoint**: `POST /api/v1/promotions/validate` (Public)
- **Request Body**:
  ```json
  {
    "code": "LUXE15",
    "subtotal": 50000.00,
    "channel": "web",
    "vip_tier": "gold",
    "items": [
      { "quantity": 2, "unit_price": 25000.00 }
    ]
  }
  ```
- **Response (200 OK)**: Returns validated `discount_amount`, `discount_label`, and `final_total` (supports `percentage` with optional cap, `fixed_amount`, and `buy_x_get_y`).

### 9.3 ERP Campaign Management
- `GET /api/v1/promotions` (Authenticated) — Paginated list of all promotion campaigns and usage metrics.
- `POST /api/v1/promotions` (Authenticated) — Create a new promotion rule (`percentage`, `fixed_amount`, `buy_x_get_y`).
- `PATCH /api/v1/promotions/{uuid}/toggle` (Authenticated) — Pause or reactivate a campaign immediately.

---

## 10. Mobile Inventory Stocktake & Barcode PO Receiving

### 10.1 Stocktake & Cycle Count Audits
- `GET /api/v1/stocktakes` (Authenticated) — Paginated list of branch stocktake audits.
- `POST /api/v1/stocktakes` (Authenticated) — Start a new stocktake session, optionally passing `items` and `finalize: true` for 1-shot mobile barcode audit sync.
- `POST /api/v1/stocktakes/{uuid}/counts` (Authenticated) — Record or update barcode-scanned counted quantities and calculate expected vs. counted variances.
- `POST /api/v1/stocktakes/{uuid}/finalize` (Authenticated) — Commit non-zero variances to `inventories` and `stock_movements` (`adjustment`) and broadcast updates via Reverb.

### 10.2 Verified Barcode PO Receiving
- `POST /api/v1/purchases/{uuid}/receive` (Authenticated) — Accepts optional `received_items: [{ product_id, quantity }]` barcode-verified quantity overrides from handheld terminals (defaults to ordered quantities if omitted).
