# ==============================================================================
# PHP 8.4 FPM - Laravel 13 Development Environment
# ==============================================================================
FROM php:8.4-fpm

# Set maintainer label
LABEL maintainer="developer"
LABEL description="PHP 8.4 FPM for Laravel 13"

# ==============================================================================
# Install system dependencies
# ==============================================================================
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    libicu-dev \
    zip \
    unzip \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure intl \
    && rm -rf /var/lib/apt/lists/*

# ==============================================================================
# Install PHP extensions
# ==============================================================================
RUN docker-php-ext-install \
    pdo_mysql \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    zip \
    intl \
    opcache

# ==============================================================================
# Install Composer from official image
# ==============================================================================
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# ==============================================================================
# Copy PHP configuration
# ==============================================================================
RUN cp /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini

# ==============================================================================
# Set working directory
# ==============================================================================
WORKDIR /var/www

# ==============================================================================
# Copy entrypoint script
# Container berjalan sebagai root agar entrypoint bisa fix permission
# pada volume mount dari Windows host. PHP-FPM worker processes tetap
# berjalan sebagai www-data (default dari php:8.4-fpm image).
# ==============================================================================
COPY docker/php/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# ==============================================================================
# Expose PHP-FPM port
# ==============================================================================
EXPOSE 9000

ENTRYPOINT ["entrypoint.sh"]
CMD ["php-fpm"]
