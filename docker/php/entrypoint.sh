#!/bin/bash
set -e

cd /var/www/html

# Copy Docker environment file if .env is missing
if [ ! -f .env ]; then
    if [ -f .env.docker ]; then
        echo "Creating .env from .env.docker..."
        cp .env.docker .env
    elif [ -f .env.example ]; then
        echo "Creating .env from .env.example..."
        cp .env.example .env
    fi
fi

# Ensure storage and cache directories exist and have proper permissions
mkdir -p storage/framework/{sessions,views,cache} storage/logs bootstrap/cache
chmod -R 775 storage bootstrap/cache || true
chown -R www-data:www-data storage bootstrap/cache || true

# Wait for database if DB_HOST is configured
if [ -n "$DB_HOST" ] && [ "$DB_CONNECTION" = "mysql" ]; then
    echo "Waiting for MySQL database at $DB_HOST:${DB_PORT:-3306}..."
    until nc -z -v -w30 "$DB_HOST" "${DB_PORT:-3306}" > /dev/null 2>&1; do
        echo "Waiting for database connection..."
        sleep 2
    done
    echo "Database is ready!"
fi

# Generate application key if missing
if ! grep -q "^APP_KEY=base64:" .env; then
    echo "Generating application key..."
    php artisan key:generate --force
fi

# If starting web app, run migrations and link storage
if [ "$1" = "php-fpm" ]; then
    echo "Running database migrations..."
    php artisan migrate --force || true

    echo "Ensuring storage symlink..."
    php artisan storage:link || true
fi

echo "SmartShop POS Container initialized. Executing command: $@"
exec "$@"
