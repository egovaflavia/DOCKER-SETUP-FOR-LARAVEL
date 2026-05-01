#!/bin/bash
# ==============================================================================
# Entrypoint Script - Fix permissions sebelum menjalankan PHP-FPM
# ==============================================================================

# Fix ownership untuk direktori yang perlu writable oleh PHP-FPM
# PHP-FPM worker berjalan sebagai www-data, jadi direktori ini
# harus dimiliki oleh www-data agar Laravel bisa menulis log, cache, dll.
chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache 2>/dev/null || true

# Set permission yang tepat
chmod -R 775 /var/www/storage /var/www/bootstrap/cache 2>/dev/null || true

# Jalankan command yang diberikan (default: php-fpm)
exec "$@"
