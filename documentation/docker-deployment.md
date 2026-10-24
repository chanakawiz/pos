# SmartShop POS — Docker Deployment Runbook

> **Version**: 1.0.0
> **Target**: Local Development & Production Containerization
> **Compose Services**: `app` (PHP 8.2-FPM), `web` (Nginx), `mysql` (MySQL 8.0), `queue` (Worker)

---

## 1. Quick Start

Ensure Docker Desktop is running on your machine, then from the repository root:

```bash
# Build and start all containers in background
docker compose up -d --build
```

The stack will:
1. Boot MySQL 8.0 on container port `3306` (mapped to host port `33060` to avoid host port collisions).
2. Wait for MySQL healthcheck to pass.
3. Build the PHP 8.2-FPM Alpine container with `pdo_mysql`, `bcmath`, `gd`, `zip`, `intl`, `exif`, and `opcache`.
4. Run automatic database migrations via the container entrypoint.
5. Create storage symlink (`storage:link`).
6. Launch Nginx on `http://localhost:8000`.

---

## 2. Access Endpoints

- **Laravel REST API**: [http://localhost:8000/api/v1](http://localhost:8000/api/v1)
- **Filament Admin ERP**: [http://localhost:8000/admin](http://localhost:8000/admin)
- **MySQL Direct Access**: `127.0.0.1:33060` (User: `smartshop`, Password: `secret`, Database: `smartshop_pos`)

---

## 3. Useful Commands

```bash
# View live container logs
docker compose logs -f

# View logs for a specific service
docker compose logs -f app
docker compose logs -f web
docker compose logs -f mysql

# Seed demo data (Products, Categories, Brands, Stores, Users)
docker compose exec app php artisan db:seed

# Run database migrations manually
docker compose exec app php artisan migrate

# Run test suite inside container
docker compose exec app php artisan test

# Open bash shell in application container
docker compose exec app bash

# Stop all containers
docker compose down

# Stop and wipe database volume (clean state)
docker compose down -v
```

---

## 4. Environment Variables

You can override defaults by setting environment variables in your host shell or a root `.env`:

| Variable | Default | Purpose |
| :--- | :--- | :--- |
| `WEB_PORT` | `8000` | Host port mapped to Nginx web server |
| `DB_PORT` | `33060` | Host port mapped to MySQL database |
