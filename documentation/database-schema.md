# SmartShop POS — Database Schema & Data Dictionary

This document defines the schema for the central MySQL 8+ database and the corresponding local SQLite schemas used on Windows Desktop and Mobile POS clients.

---

## 1. Schema Conventions
- **Identifiers**: All business entities include a standard auto-incrementing `id` (bigint unsigned) for optimal internal relational indexing and a globally unique `uuid` (UUIDv4) for distributed generation on offline clients.
- **Timestamps**: Standard `created_at` and `updated_at`. Transactional tables also store `sold_at` / `opened_at` to preserve exact local device event times.
- **Soft Deletes**: Used for products, categories, stores, and users to preserve historical references in sales audits.

---

## 2. Table Specifications

### 2.1 Stores & Hardware Devices
#### `stores`
Stores represent physical retail branches.
```sql
CREATE TABLE `stores` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) UNIQUE NOT NULL,
  `code` VARCHAR(50) UNIQUE NOT NULL,
  `name` VARCHAR(191) NOT NULL,
  `phone` VARCHAR(50) NULL,
  `email` VARCHAR(191) NULL,
  `address` TEXT NULL,
  `tax_number` VARCHAR(100) NULL,
  `currency_code` VARCHAR(10) DEFAULT 'USD',
  `currency_symbol` VARCHAR(10) DEFAULT '$',
  `receipt_header` TEXT NULL,
  `receipt_footer` TEXT NULL,
  `is_active` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP NULL,
  `updated_at` TIMESTAMP NULL,
  `deleted_at` TIMESTAMP NULL
);
```

#### `devices`
Physical POS terminals (Windows desktop, iPad, iPhone).
```sql
CREATE TABLE `devices` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) UNIQUE NOT NULL,
  `store_id` BIGINT UNSIGNED NOT NULL,
  `device_name` VARCHAR(191) NOT NULL,
  `device_type` ENUM('windows', 'ios', 'android') NOT NULL,
  `mac_address` VARCHAR(100) NULL,
  `app_version` VARCHAR(50) NULL,
  `is_active` TINYINT(1) DEFAULT 1,
  `last_sync_at` TIMESTAMP NULL,
  `created_at` TIMESTAMP NULL,
  `updated_at` TIMESTAMP NULL,
  FOREIGN KEY (`store_id`) REFERENCES `stores`(`id`) ON DELETE CASCADE
);
```

### 2.2 User Management & Roles
#### `users`
System operators: Super Admins, Managers, and Cashiers.
```sql
CREATE TABLE `users` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) UNIQUE NOT NULL,
  `store_id` BIGINT UNSIGNED NULL,
  `name` VARCHAR(191) NOT NULL,
  `email` VARCHAR(191) UNIQUE NOT NULL,
  `pin_code_hash` VARCHAR(255) NULL,
  `password` VARCHAR(255) NOT NULL,
  `role` ENUM('super_admin', 'admin', 'manager', 'cashier') DEFAULT 'cashier',
  `is_active` TINYINT(1) DEFAULT 1,
  `remember_token` VARCHAR(100) NULL,
  `created_at` TIMESTAMP NULL,
  `updated_at` TIMESTAMP NULL,
  `deleted_at` TIMESTAMP NULL,
  FOREIGN KEY (`store_id`) REFERENCES `stores`(`id`) ON DELETE SET NULL
);
```

### 2.3 Product Catalog & Categories
#### `categories`
```sql
CREATE TABLE `categories` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) UNIQUE NOT NULL,
  `parent_id` BIGINT UNSIGNED NULL,
  `name` VARCHAR(191) NOT NULL,
  `slug` VARCHAR(191) UNIQUE NOT NULL,
  `image_path` VARCHAR(255) NULL,
  `display_order` INT DEFAULT 0,
  `is_active` TINYINT(1) DEFAULT 1,
  `version` BIGINT UNSIGNED DEFAULT 1,
  `created_at` TIMESTAMP NULL,
  `updated_at` TIMESTAMP NULL,
  `deleted_at` TIMESTAMP NULL,
  FOREIGN KEY (`parent_id`) REFERENCES `categories`(`id`) ON DELETE SET NULL
);
```

#### `brands`
```sql
CREATE TABLE `brands` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) UNIQUE NOT NULL,
  `name` VARCHAR(191) NOT NULL,
  `slug` VARCHAR(191) UNIQUE NOT NULL,
  `logo_path` VARCHAR(255) NULL,
  `is_active` TINYINT(1) DEFAULT 1,
  `version` BIGINT UNSIGNED DEFAULT 1,
  `created_at` TIMESTAMP NULL,
  `updated_at` TIMESTAMP NULL,
  `deleted_at` TIMESTAMP NULL
);
```

#### `products`
```sql
CREATE TABLE `products` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) UNIQUE NOT NULL,
  `category_id` BIGINT UNSIGNED NULL,
  `brand_id` BIGINT UNSIGNED NULL,
  `name` VARCHAR(191) NOT NULL,
  `sku` VARCHAR(100) UNIQUE NOT NULL,
  `barcode` VARCHAR(100) UNIQUE NULL,
  `description` TEXT NULL,
  `unit` VARCHAR(50) DEFAULT 'piece',
  `cost_price` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  `selling_price` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  `tax_rate` DECIMAL(5, 2) NOT NULL DEFAULT 0.00,
  `min_stock_level` INT NOT NULL DEFAULT 5,
  `image_path` VARCHAR(255) NULL,
  `has_variants` TINYINT(1) DEFAULT 0,
  `is_active` TINYINT(1) DEFAULT 1,
  `version` BIGINT UNSIGNED DEFAULT 1,
  `created_at` TIMESTAMP NULL,
  `updated_at` TIMESTAMP NULL,
  `deleted_at` TIMESTAMP NULL,
  FOREIGN KEY (`category_id`) REFERENCES `categories`(`id`) ON DELETE SET NULL,
  FOREIGN KEY (`brand_id`) REFERENCES `brands`(`id`) ON DELETE SET NULL
);
```

#### `product_variants`
```sql
CREATE TABLE `product_variants` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) UNIQUE NOT NULL,
  `product_id` BIGINT UNSIGNED NOT NULL,
  `sku` VARCHAR(100) UNIQUE NOT NULL,
  `barcode` VARCHAR(100) UNIQUE NULL,
  `name` VARCHAR(191) NOT NULL,
  `cost_price` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  `selling_price` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  `version` BIGINT UNSIGNED DEFAULT 1,
  `created_at` TIMESTAMP NULL,
  `updated_at` TIMESTAMP NULL,
  FOREIGN KEY (`product_id`) REFERENCES `products`(`id`) ON DELETE CASCADE
);
```

### 2.4 Inventory & Stock Tracking
#### `inventory`
Tracks active stock levels per store and product/variant.
```sql
CREATE TABLE `inventory` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) UNIQUE NOT NULL,
  `store_id` BIGINT UNSIGNED NOT NULL,
  `product_id` BIGINT UNSIGNED NOT NULL,
  `variant_id` BIGINT UNSIGNED NULL,
  `quantity_on_hand` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  `quantity_reserved` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  `created_at` TIMESTAMP NULL,
  `updated_at` TIMESTAMP NULL,
  UNIQUE KEY `store_product_variant_unique` (`store_id`, `product_id`, `variant_id`),
  FOREIGN KEY (`store_id`) REFERENCES `stores`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`product_id`) REFERENCES `products`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`variant_id`) REFERENCES `product_variants`(`id`) ON DELETE CASCADE
);
```

#### `stock_movements`
Audited ledger for every stock change.
```sql
CREATE TABLE `stock_movements` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) UNIQUE NOT NULL,
  `store_id` BIGINT UNSIGNED NOT NULL,
  `product_id` BIGINT UNSIGNED NOT NULL,
  `variant_id` BIGINT UNSIGNED NULL,
  `user_id` BIGINT UNSIGNED NULL,
  `type` ENUM('sale', 'refund', 'purchase', 'adjustment', 'transfer_in', 'transfer_out', 'damaged') NOT NULL,
  `quantity` DECIMAL(12, 2) NOT NULL,
  `before_quantity` DECIMAL(12, 2) NOT NULL,
  `after_quantity` DECIMAL(12, 2) NOT NULL,
  `reference_uuid` VARCHAR(100) NULL,
  `notes` TEXT NULL,
  `created_at` TIMESTAMP NULL,
  FOREIGN KEY (`store_id`) REFERENCES `stores`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`product_id`) REFERENCES `products`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`variant_id`) REFERENCES `product_variants`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE SET NULL
);
```

### 2.5 Customers
#### `customers`
```sql
CREATE TABLE `customers` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) UNIQUE NOT NULL,
  `name` VARCHAR(191) NOT NULL,
  `phone` VARCHAR(50) NULL,
  `email` VARCHAR(191) NULL,
  `address` TEXT NULL,
  `loyalty_points` INT DEFAULT 0,
  `credit_limit` DECIMAL(12, 2) DEFAULT 0.00,
  `balance` DECIMAL(12, 2) DEFAULT 0.00,
  `version` BIGINT UNSIGNED DEFAULT 1,
  `created_at` TIMESTAMP NULL,
  `updated_at` TIMESTAMP NULL,
  `deleted_at` TIMESTAMP NULL
);
```

### 2.6 Sales, Items & Payments
#### `sales`
```sql
CREATE TABLE `sales` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) UNIQUE NOT NULL,
  `invoice_number` VARCHAR(100) UNIQUE NOT NULL,
  `transaction_uuid` CHAR(36) UNIQUE NOT NULL,
  `store_id` BIGINT UNSIGNED NOT NULL,
  `device_id` BIGINT UNSIGNED NULL,
  `cashier_id` BIGINT UNSIGNED NOT NULL,
  `customer_id` BIGINT UNSIGNED NULL,
  `subtotal` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  `discount_amount` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  `tax_amount` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  `total_amount` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  `paid_amount` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  `change_amount` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  `payment_status` ENUM('paid', 'partial', 'unpaid', 'refunded') DEFAULT 'paid',
  `sale_status` ENUM('completed', 'cancelled', 'held') DEFAULT 'completed',
  `source` ENUM('online', 'offline') DEFAULT 'online',
  `sync_status` ENUM('synced', 'pending', 'failed') DEFAULT 'synced',
  `notes` TEXT NULL,
  `sold_at` TIMESTAMP NOT NULL,
  `created_at` TIMESTAMP NULL,
  `updated_at` TIMESTAMP NULL,
  FOREIGN KEY (`store_id`) REFERENCES `stores`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`device_id`) REFERENCES `devices`(`id`) ON DELETE SET NULL,
  FOREIGN KEY (`cashier_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`customer_id`) REFERENCES `customers`(`id`) ON DELETE SET NULL
);
```

#### `sale_items`
```sql
CREATE TABLE `sale_items` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) UNIQUE NOT NULL,
  `sale_id` BIGINT UNSIGNED NOT NULL,
  `product_id` BIGINT UNSIGNED NOT NULL,
  `variant_id` BIGINT UNSIGNED NULL,
  `quantity` DECIMAL(12, 2) NOT NULL,
  `unit_cost` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  `unit_price` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  `discount_amount` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  `tax_amount` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  `subtotal` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  `total` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  `created_at` TIMESTAMP NULL,
  `updated_at` TIMESTAMP NULL,
  FOREIGN KEY (`sale_id`) REFERENCES `sales`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`product_id`) REFERENCES `products`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`variant_id`) REFERENCES `product_variants`(`id`) ON DELETE SET NULL
);
```

#### `payments`
```sql
CREATE TABLE `payments` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) UNIQUE NOT NULL,
  `sale_id` BIGINT UNSIGNED NOT NULL,
  `payment_method` ENUM('cash', 'card', 'bank_transfer', 'credit') NOT NULL,
  `amount` DECIMAL(12, 2) NOT NULL,
  `reference_number` VARCHAR(100) NULL,
  `paid_at` TIMESTAMP NOT NULL,
  `created_at` TIMESTAMP NULL,
  `updated_at` TIMESTAMP NULL,
  FOREIGN KEY (`sale_id`) REFERENCES `sales`(`id`) ON DELETE CASCADE
);
```

### 2.7 Refunds
#### `refunds` & `refund_items`
```sql
CREATE TABLE `refunds` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) UNIQUE NOT NULL,
  `refund_number` VARCHAR(100) UNIQUE NOT NULL,
  `sale_id` BIGINT UNSIGNED NOT NULL,
  `store_id` BIGINT UNSIGNED NOT NULL,
  `cashier_id` BIGINT UNSIGNED NOT NULL,
  `amount` DECIMAL(12, 2) NOT NULL,
  `reason` TEXT NULL,
  `created_at` TIMESTAMP NULL,
  `updated_at` TIMESTAMP NULL,
  FOREIGN KEY (`sale_id`) REFERENCES `sales`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`store_id`) REFERENCES `stores`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`cashier_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
);

CREATE TABLE `refund_items` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) UNIQUE NOT NULL,
  `refund_id` BIGINT UNSIGNED NOT NULL,
  `sale_item_id` BIGINT UNSIGNED NOT NULL,
  `quantity` DECIMAL(12, 2) NOT NULL,
  `amount` DECIMAL(12, 2) NOT NULL,
  `restock` TINYINT(1) DEFAULT 1,
  `created_at` TIMESTAMP NULL,
  `updated_at` TIMESTAMP NULL,
  FOREIGN KEY (`refund_id`) REFERENCES `refunds`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`sale_item_id`) REFERENCES `sale_items`(`id`) ON DELETE CASCADE
);
```

### 2.8 Cash Sessions & Held Bills
#### `cash_sessions`
```sql
CREATE TABLE `cash_sessions` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) UNIQUE NOT NULL,
  `store_id` BIGINT UNSIGNED NOT NULL,
  `device_id` BIGINT UNSIGNED NULL,
  `cashier_id` BIGINT UNSIGNED NOT NULL,
  `opened_at` TIMESTAMP NOT NULL,
  `closed_at` TIMESTAMP NULL,
  `opening_balance` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  `closing_balance` DECIMAL(12, 2) NULL,
  `expected_balance` DECIMAL(12, 2) NULL,
  `discrepancy` DECIMAL(12, 2) NULL,
  `notes` TEXT NULL,
  `status` ENUM('open', 'closed') DEFAULT 'open',
  `created_at` TIMESTAMP NULL,
  `updated_at` TIMESTAMP NULL,
  FOREIGN KEY (`store_id`) REFERENCES `stores`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`device_id`) REFERENCES `devices`(`id`) ON DELETE SET NULL,
  FOREIGN KEY (`cashier_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
);
```

#### `held_bills`
```sql
CREATE TABLE `held_bills` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) UNIQUE NOT NULL,
  `store_id` BIGINT UNSIGNED NOT NULL,
  `device_id` BIGINT UNSIGNED NULL,
  `cashier_id` BIGINT UNSIGNED NOT NULL,
  `customer_id` BIGINT UNSIGNED NULL,
  `hold_reference` VARCHAR(100) NOT NULL,
  `cart_items_json` LONGTEXT NOT NULL,
  `subtotal` DECIMAL(12, 2) NOT NULL DEFAULT 0.00,
  `held_at` TIMESTAMP NOT NULL,
  `created_at` TIMESTAMP NULL,
  `updated_at` TIMESTAMP NULL,
  FOREIGN KEY (`store_id`) REFERENCES `stores`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`device_id`) REFERENCES `devices`(`id`) ON DELETE SET NULL,
  FOREIGN KEY (`cashier_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`customer_id`) REFERENCES `customers`(`id`) ON DELETE SET NULL
);
```

### 2.9 Synchronization & Auditing
#### `sync_logs`
```sql
CREATE TABLE `sync_logs` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `uuid` CHAR(36) UNIQUE NOT NULL,
  `device_id` BIGINT UNSIGNED NOT NULL,
  `sync_type` ENUM('push', 'pull', 'retry') NOT NULL,
  `batch_size` INT DEFAULT 0,
  `status` ENUM('success', 'partial_failure', 'failed') NOT NULL,
  `error_details` LONGTEXT NULL,
  `synced_at` TIMESTAMP NOT NULL,
  FOREIGN KEY (`device_id`) REFERENCES `devices`(`id`) ON DELETE CASCADE
);
```

#### `settings`
```sql
CREATE TABLE `settings` (
  `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `store_id` BIGINT UNSIGNED NULL,
  `group` VARCHAR(50) DEFAULT 'general',
  `key` VARCHAR(100) NOT NULL,
  `value` TEXT NULL,
  `is_public` TINYINT(1) DEFAULT 0,
  `created_at` TIMESTAMP NULL,
  `updated_at` TIMESTAMP NULL,
  UNIQUE KEY `store_group_key` (`store_id`, `group`, `key`),
  FOREIGN KEY (`store_id`) REFERENCES `stores`(`id`) ON DELETE CASCADE
);
```
