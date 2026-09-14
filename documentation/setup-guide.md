# SmartShop POS — Setup & Installation Guide

This guide details setting up the entire SmartShop POS environment on macOS, Linux, and Windows development machines.

---

## 1. Prerequisites
- **PHP**: 8.3 or 8.4 with extensions: `pdo_mysql`, `pdo_sqlite`, `bcmath`, `curl`, `mbstring`, `xml`, `zip`, `intl`.
- **Composer**: 2.6+
- **Node.js**: 20 LTS or higher, with `npm`
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
   ```

4. Launch in development mode:
   ```bash
   npm run dev
   ```

5. Build Windows Distribution Installer:
   ```bash
   npm run build
   npm run electron:build
   ```
   The `.exe` installer will be generated in `apps/windows-pos/dist/`.
