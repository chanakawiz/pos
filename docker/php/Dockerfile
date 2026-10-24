FROM php:8.2-fpm-alpine

# Set working directory
WORKDIR /var/www/html

# Install system dependencies
RUN apk update && apk add --no-cache \
    bash \
    curl \
    git \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    libzip-dev \
    icu-dev \
    oniguruma-dev \
    mysql-client \
    su-exec \
    shadow

# Configure and install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        pdo_mysql \
        bcmath \
        gd \
        zip \
        intl \
        exif \
        opcache

# Install Composer
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

# Copy custom php.ini
COPY docker/php/php.ini /usr/local/etc/php/conf.d/custom.ini

# Copy entrypoint script
COPY docker/php/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose PHP-FPM default port
EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php-fpm"]
