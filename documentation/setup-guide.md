# SmartShop POS — Setup & Installation Guide

This guide details setting up the entire SmartShop POS environment on macOS, Linux, and Windows development machines.

---

## 1. Prerequisites
- **PHP**: 8.3 or 8.4 with extensions: `pdo_mysql`, `pdo_sqlite`, `bcmath`, `curl`, `mbstring`, `xml`, `zip`, `intl`.
- **Composer**: 2.6+
- **Node.js**: 24 LTS recommended (minimum 22.12), with `npm`
- **MySQL**: 8.0+
- **Electron**: Windows 10/11 or macOS / Linux cross-compilation environment

---

## 2. Backend Installation (Laravel 11 + Filament Admin)

1. Navigate to the backend directory:
   ```bash
   cd backend/laravel-api
   ```

2. Install Composer dependencies:
   ```bash
   composer install
   ```

3. Configure Environment:
   ```bash
   cp .env.example .env
   php artisan key:generate
   ```
   Set your MySQL credentials in `.env`:
   ```env
   DB_CONNECTION=mysql
   DB_HOST=127.0.0.1
   DB_PORT=3306
   DB_DATABASE=smartshop_pos
   DB_USERNAME=root
   DB_PASSWORD=your_password
   ```

4. Run Database Migrations and Seeders:
   ```bash
   php artisan migrate --seed
   ```
   Default seeded credentials:
   - **Super Admin**: `admin@smartshop.com` / `password`
   - **Cashier**: `cashier1@smartshop.com` / `password` (PIN: `1234`)

5. Start the backend server:
   ```bash
   php artisan serve --port=8000
   ```
   Access:
   - REST API: `http://127.0.0.1:8000/api/v1`
   - Filament Admin Panel: `http://127.0.0.1:8000/admin`

---

## 3. Windows Desktop POS Setup (Electron + React)

1. Navigate to the desktop app directory:
   ```bash
   cd apps/windows-pos
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Configure Local Environment:
   ```env
   VITE_API_BASE_URL=http://127.0.0.1:8000/api/v1
   VITE_DEVICE_UUID=<active-device-uuid-from-filament>
   ```

   Register an active device under the cashier’s store in Filament and use its UUID above. A previously stored `pos_device_uuid` takes precedence. `npm ci` rebuilds native SQLite for Electron; run `npm run rebuild:native` after changing Electron or CPU architecture.

4. Launch in development mode:
   ```bash
   npm run dev
   ```
   In a second terminal, start the native app:
   ```bash
   npm run build:electron
   npm run electron:start
   ```
   The browser preview uses online checkout; SQLite/offline checkout requires Electron.

5. Build Windows Distribution Installer:
   ```bash
   npm run dist:win
   ```
   Build on a Windows machine. The `.exe` installer is generated under `apps/windows-pos/release/<version>/`. Use `npm run dist:mac` for macOS.

6. Verify changes:
   ```bash
   npm run build:all
   npm test
   npm run test:smoke
   npm run lint
   ```
   See [the desktop README](../apps/windows-pos/README.md) for database backup, legacy JSON migration, offline session behavior, and native test details. Apply the new sync-revision backend migration before updating desktop terminals.


## 4. Receipt printer and cash drawer setup

Configure the terminal’s user-data `printer.json` using the [receipt printing guide](receipt-printing.md) and [sample profile](../apps/windows-pos/printer.example.json). No output is sent until a valid target is configured. TCP delivery and Windows RAW queues are supported; actual Windows/printer/cutter/drawer behavior must be checked on deployment hardware.


## 5. Customer-facing monitor setup

Connect the second screen in OS **Extend** mode and keep the cashier window on one monitor. The customer window starts automatically; use **F1 → Customer display** for status and persistent pause/resume. See [customer-display.md](customer-display.md) for behavior, isolation, verification, and required physical Windows acceptance checks.


## 6. RS-232 weighing-scale setup

Apply `2026_10_17_000002_preserve_three_decimal_stock_quantities.php` before deploying the updated terminal. Configure an explicit port/protocol in user-data `scale.json`, set weighed product units to `kg` or `g`, and verify the actual equipment using [weighing-scales.md](weighing-scales.md). The example serial settings must be replaced with those in the device manual.
