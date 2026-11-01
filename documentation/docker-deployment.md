# OmniLuxe Store — Docker Production Runbook & Deployment Guide

> **Version**: 2.0.0  
> **Target**: Local Development & Production Containerization  
> **Compose Stack**: `omniluxe-app` (PHP 8.3-FPM), `omniluxe-web` (Nginx), `omniluxe-mysql` (MySQL 8.0), `omniluxe-reverb` (WebSockets), `omniluxe-queue` (Worker)  
> **Network**: `omniluxe-net` (Isolated Bridge)  

---

## 1. Quick Start

Ensure Docker Desktop or the Docker Engine is running on your host machine, then run from the repository root:

```bash
# Build and start all 5 containers in the background
docker compose up -d --build
```

The stack orchestrates the following sequence:
1. Boot **MySQL 8.0** on container port `3306` (mapped to host port `33060` to avoid local host port collisions).
2. The MySQL healthcheck runs `mysqladmin ping` every 5 seconds until healthy.
3. Builds the **PHP 8.3-FPM Alpine** container with `pdo_mysql`, `bcmath`, `gd`, `zip`, `intl`, `exif`, and `opcache`.
4. Executes the entrypoint script: ensures `.env`, sets up storage and cache folders, and runs database migrations (`migrate --force`).
5. Boots **Nginx** reverse proxy on `http://localhost:8000` with automated `/health/live` HTTP healthcheck.
6. Boots **Laravel Reverb** WebSocket server (`php artisan reverb:start`) on port `8080` for real-time inventory and dispatch alerts.
7. Boots **Queue Worker** (`php artisan queue:work`) for background email receipts and push notification handling.

---

## 2. Health Check & Auditing Probes

The container stack exposes two production probes for load balancers (AWS ALB, Cloudflare, Traefik, Kubernetes):

### 2.1 Process Liveness Probe
- **Endpoint**: `GET http://localhost:8000/health/live`
- **Purpose**: High-frequency ping verifying the web server and PHP execution runtime are viable.
- **Sample Output**:
  ```json
  {
    "status": "ok",
    "service": "omniluxe-api",
    "timestamp": "2026-11-01T09:45:00+00:00",
    "php_version": "8.3.14"
  }
  ```

### 2.2 Deep Readiness Audit
- **Endpoint**: `GET http://localhost:8000/health/ready`
- **Purpose**: Deep telemetry verifying database connectivity (with latency telemetry), cache read/write responsiveness, storage permissions, and Reverb WebSocket configuration.
- **Sample Output**:
  ```json
  {
    "status": "healthy",
    "service": "omniluxe-api",
    "environment": "production",
    "checks": {
      "database": {
        "status": "up",
        "latency_ms": 1.45,
        "driver": "mysql",
        "database": "smartshop_pos"
      },
      "cache": {
        "status": "up",
        "driver": "file"
      },
      "storage": {
        "status": "up",
        "writable": true
      },
      "reverb": {
        "status": "configured",
        "host": "0.0.0.0",
        "port": 8080
      }
    },
    "timestamp": "2026-11-01T09:45:00+00:00"
  }
  ```

---

## 3. Access Endpoints

- **Web Storefront**: [http://localhost:8000/](http://localhost:8000/)
- **Order Tracking & Returns**: [http://localhost:8000/track](http://localhost:8000/track)
- **Filament Admin ERP**: [http://localhost:8000/admin](http://localhost:8000/admin)
- **Branch Performance Analytics**: [http://localhost:8000/admin/branch-performance](http://localhost:8000/admin/branch-performance)
- **Reverb WebSocket Gateway**: `ws://localhost:8080/app/omniluxe_key`
- **MySQL Direct Access**: `127.0.0.1:33060` (User: `smartshop`, Password: `secret`, Database: `smartshop_pos`)

---

## 4. Useful Operations Commands

```bash
# View live container logs across all services
docker compose logs -f

# View logs for a specific service
docker compose logs -f app
docker compose logs -f web
docker compose logs -f reverb
docker compose logs -f queue
docker compose logs -f mysql

# Seed master multi-branch demo data (Colombo, Kandy, Galle)
docker compose exec app php artisan db:seed

# Run database migrations manually
docker compose exec app php artisan migrate

# Run the 70-test backend suite inside the container
docker compose exec app php artisan test

# Open a shell in the application container
docker compose exec app bash

# Gracefully stop all containers
docker compose down

# Stop and wipe database volume (clean reset)
docker compose down -v
```
