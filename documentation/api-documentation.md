# SmartShop POS — REST API Specification (`/api/v1`)

All endpoints accept and return `application/json`. Authenticated requests require the HTTP header:
`Authorization: Bearer <sanctum_token>`
Along with terminal identification:
`X-Device-UUID: <device_uuid>`

---

## 1. Authentication Endpoints

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
      "name": "Sarah Miller",
      "email": "cashier1@smartshop.com",
      "role": "cashier",
      "store": {
        "uuid": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
        "name": "Main Downtown Store",
        "currency_symbol": "$"
      }
    }
  }
  ```

### 1.2 Device Registration
- **Endpoint**: `POST /api/v1/devices/register`
- **Request Body**:
  ```json
  {
    "pairing_code": "STORE-9921",
    "device_name": "Lane 01 - Windows POS",
    "device_type": "windows",
    "mac_address": "00:1B:44:11:3A:B7",
    "app_version": "1.0.0"
  }
  ```
- **Response (201 Created)**:
  ```json
  {
    "status": "success",
    "device": {
      "uuid": "550e8400-e29b-41d4-a716-446655440000",
      "device_name": "Lane 01 - Windows POS",
      "store_name": "Main Downtown Store"
    }
  }
  ```

---

## 2. Catalog & Products Endpoints

### 2.1 List Products
- **Endpoint**: `GET /api/v1/products`
- **Query Parameters**:
  - `search`: Filter by name, barcode, or SKU
  - `category_id`: Category filter
  - `page`: Page index
  - `per_page`: Page size (default: 50)
- **Response (200 OK)**:
  ```json
  {
    "data": [
      {
        "uuid": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
        "name": "Organic Roasted Coffee Beans 1kg",
        "sku": "BEV-COF-001",
        "barcode": "8901234567890",
        "category": "Beverages",
        "unit": "pack",
        "cost_price": 14.00,
        "selling_price": 22.50,
        "tax_rate": 8.00,
        "min_stock_level": 10,
        "stock_quantity": 48.00,
        "image_url": "/storage/products/coffee.jpg"
      }
    ],
    "meta": {
      "current_page": 1,
      "total": 120
    }
  }
  ```

### 2.2 Barcode Quick Lookup
- **Endpoint**: `GET /api/v1/products/barcode/{barcode}`
- **Response (200 OK)**: Returns the matching product or 404 if not found.

---

## 3. Direct Online Billing Endpoints

### 3.1 Create Sale
- **Endpoint**: `POST /api/v1/sales`
- **Request Body**:
  ```json
  {
    "transaction_uuid": "7c9e6679-7425-40de-944b-e07fc1f90ae7",
    "customer_id": null,
    "items": [
      {
        "product_id": 1,
        "quantity": 2,
        "unit_price": 22.50,
        "discount_amount": 0.00
      }
    ],
    "payments": [
      {
        "payment_method": "cash",
        "amount": 50.00
      }
    ],
    "discount_amount": 0.00,
    "notes": "Fast checkout"
  }
  ```
- **Response (201 Created)**: Returns the completed sale object, receipt printable payload, and updated inventory counts.

---

## 4. Register Cash Sessions

### 4.1 Open Cash Register Session
- **Endpoint**: `POST /api/v1/cash-sessions/open`
- **Request Body**:
  ```json
  {
    "opening_balance": 150.00,
    "notes": "Morning float verified"
  }
  ```

### 4.2 Close Cash Register Session
- **Endpoint**: `POST /api/v1/cash-sessions/close`
- **Request Body**:
  ```json
  {
    "closing_balance": 890.50,
    "notes": "Shift ended cleanly"
  }
  ```
- **Response (200 OK)**:
  ```json
  {
    "session": {
      "uuid": "8b9e6679-...",
      "opening_balance": 150.00,
      "total_sales_cash": 740.50,
      "expected_balance": 890.50,
      "closing_balance": 890.50,
      "discrepancy": 0.00,
      "status": "closed"
    }
  }
  ```

---

## 5. Synchronization Endpoints
- `POST /api/v1/sync/push`: Batch push of offline sales and payments (idempotent).
- `GET /api/v1/sync/pull`: Delta pull of catalog and customers based on version.
- `GET /api/v1/sync/status`: Returns server health, active version, and device sync log.

## Quantity precision (2026-10-18)

Sale, refund, purchase, and offline-sync item quantities accept a positive numeric value of at least `0.001` with up to three decimal places. Excess precision is rejected rather than silently rounded. Deploy `2026_10_17_000002_preserve_three_decimal_stock_quantities.php` first; inventory/reservations and stock movements also retain three decimals. Money remains two decimals. See [weighing-scales.md](weighing-scales.md) for kg/g capture and rollout details.
