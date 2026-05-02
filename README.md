# 🐳 Docker Laravel Development Environment

Docker-based development environment untuk project **Laravel** menggunakan Laravel, PHP, Nginx, dan MySQL.

---

## 📁 Struktur Project

```
NAMA_PROJECT/
├── docker/
│   ├── nginx/
│   │   └── default.conf          # Konfigurasi Nginx
│   └── php/
│       └── Dockerfile            # PHP 8.4 FPM image
├── docker-compose.yml            # Orchestration semua services
├── .env                          # Environment variables
├── README.md                     # Dokumentasi (file ini)
└── Laravel                       # Tinggal install Laravel (Belum ada)
```

---

## 🏗️ Step-by-Step Pembuatan

### Step 1 — Dockerfile PHP 8.4 FPM

**📄 Output:** `docker/php/Dockerfile`

**💬 Prompt yang digunakan:**

> Buatkan Dockerfile untuk Laravel 12 dengan PHP 8.4 FPM.
>
> Requirements:
> - Base image: php:8.4-fpm
> - Install extensions: pdo_mysql, mbstring, exif, pcntl, bcmath, gd, zip, intl, opcache
> - Install Composer dari official image
> - Set working directory /var/www
> - Create user 'www' dengan uid 1000 untuk permission yang proper
> - Copy php.ini configuration untuk development
> - Expose port 9000
>
> Output: docker/php/Dockerfile

**📋 Detail konfigurasi:**

| Konfigurasi | Nilai |
|---|---|
| Base image | `php:8.4-fpm` |
| System dependencies | git, curl, libpng-dev, libjpeg62-turbo-dev, libfreetype6-dev, libonig-dev, libxml2-dev, libzip-dev, libicu-dev, zip, unzip |
| PHP Extensions | pdo_mysql, mbstring, exif, pcntl, bcmath, gd (freetype+jpeg), zip, intl, opcache |
| Composer | Multi-stage copy dari `composer:latest` |
| PHP Config | `php.ini-development` → `php.ini` |
| User | `www` (uid: 1000, gid: 1000) |
| Working directory | `/var/www` |
| Port | 9000 |

**📝 Isi file:**

```dockerfile
# ==============================================================================
# PHP 8.4 FPM - Laravel 12 Development Environment
# ==============================================================================
FROM php:8.4-fpm

# Set maintainer label
LABEL maintainer="developer"
LABEL description="PHP 8.4 FPM for Laravel 12"

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
# Create system user 'www' for proper permissions
# ==============================================================================
RUN groupadd -g 1000 www \
    && useradd -u 1000 -ms /bin/bash -g www www

# ==============================================================================
# Set working directory
# ==============================================================================
WORKDIR /var/www

# ==============================================================================
# Set ownership and switch to non-root user
# ==============================================================================
RUN chown -R www:www /var/www
USER www

# ==============================================================================
# Expose PHP-FPM port
# ==============================================================================
EXPOSE 9000

CMD ["php-fpm"]
```

---

### Step 2 — Nginx Configuration

**📄 Output:** `docker/nginx/default.conf`

**💬 Prompt yang digunakan:**

> Buatkan Nginx configuration untuk Laravel.
>
> Requirements:
> - Listen port 80
> - Server name localhost
> - Root directory /var/www/public
> - Index files: index.php, index.html
> - Handle static files dengan try_files
> - PHP processing via FastCGI ke container 'app' port 9000
> - Proper location block untuk Laravel routing (semua request ke index.php)
> - Deny access ke .htaccess dan hidden files
> - Gzip compression enabled
> - Client max body size 100M (untuk upload)
>
> Output: docker/nginx/default.conf

**📋 Detail konfigurasi:**

| Konfigurasi | Nilai |
|---|---|
| Listen | Port 80 |
| Server name | `localhost` |
| Root | `/var/www/public` |
| Index | `index.php`, `index.html` |
| Max body size | `100M` |
| Gzip | Enabled, level 6, berbagai MIME types |
| Laravel routing | `try_files $uri $uri/ /index.php?$query_string` |
| PHP-FPM | FastCGI proxy ke `app:9000` |
| Hidden files | Deny all (kecuali `.well-known`) |
| Static assets | Cache 30 hari |
| FastCGI timeout | 300s |

**📝 Isi file:**

```nginx
# ==============================================================================
# Nginx Configuration for Laravel 12
# ==============================================================================

server {
    listen 80;
    server_name localhost;

    # Root directory (Laravel public folder)
    root /var/www/public;
    index index.php index.html;

    # Max upload size
    client_max_body_size 100M;

    # =========================================================================
    # Gzip Compression
    # =========================================================================
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_min_length 256;
    gzip_types
        application/atom+xml
        application/javascript
        application/json
        application/ld+json
        application/manifest+json
        application/rss+xml
        application/vnd.geo+json
        application/vnd.ms-fontobject
        application/x-font-ttf
        application/x-web-app-manifest+json
        application/xhtml+xml
        application/xml
        font/opentype
        image/bmp
        image/svg+xml
        image/x-icon
        text/cache-manifest
        text/css
        text/plain
        text/vcard
        text/vnd.rim.location.xloc
        text/vtt
        text/x-component
        text/x-cross-domain-policy
        text/xml;

    # =========================================================================
    # Laravel Routing - Send all requests to index.php
    # =========================================================================
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    # =========================================================================
    # PHP Processing via FastCGI
    # =========================================================================
    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass app:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        include fastcgi_params;

        # FastCGI buffering & timeout
        fastcgi_buffering on;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 16 16k;
        fastcgi_read_timeout 300;
    }

    # =========================================================================
    # Deny access to hidden files (.htaccess, .env, .git, etc.)
    # =========================================================================
    location ~ /\.(?!well-known).* {
        deny all;
        access_log off;
        log_not_found off;
    }

    # =========================================================================
    # Static files caching
    # =========================================================================
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 30d;
        access_log off;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }

    # Logging
    error_log  /var/log/nginx/error.log;
    access_log /var/log/nginx/access.log;
}
```

---

### Step 3 — Docker Compose

**📄 Output:** `docker-compose.yml`

**💬 Prompt yang digunakan:**

> Buatkan docker-compose.yml untuk Laravel development environment.
>
> Services yang dibutuhkan:
>
> 1. app (PHP-FPM)
>    - Build dari ./docker/php dengan args user dan uid
>    - Container name: laravel-app
>    - Restart: unless-stopped
>    - Volume: current directory ke /var/www
>    - Network: laravel-network
>    - Depends on: mysql
>
> 2. webserver (Nginx)
>    - Image: nginx:alpine
>    - Container name: laravel-nginx
>    - Restart: unless-stopped
>    - Ports: 8000:80
>    - Volumes:
>      - current directory ke /var/www
>      - nginx config ke /etc/nginx/conf.d/default.conf
>    - Network: laravel-network
>    - Depends on: app
>
> 3. mysql
>    - Image: mysql:8.0
>    - Container name: laravel-mysql
>    - Restart: unless-stopped
>    - Environment dari .env file:
>      - MYSQL_DATABASE
>      - MYSQL_ROOT_PASSWORD
>      - MYSQL_USER
>      - MYSQL_PASSWORD
>    - Ports: 3306:3306
>    - Volume: mysql-data untuk persistence
>    - Network: laravel-network
>    - Health check untuk memastikan MySQL ready
>
> Include:
> - Named volume 'mysql-data'
> - Custom network 'laravel-network' dengan bridge driver
>
> Output: docker-compose.yml

**📋 Detail konfigurasi:**

| Service | Image / Build | Container | Port | Depends On |
|---|---|---|---|---|
| **app** | Build `docker/php/Dockerfile` | `laravel-app` | — | `mysql` (healthy) |
| **webserver** | `nginx:alpine` | `laravel-nginx` | `8000:80` | `app` |
| **mysql** | `mysql:8.0` | `laravel-mysql` | `3306:3306` | — |

**Startup Order:** MySQL (health check) → App → Webserver

**📝 Isi file:**

```yaml
# ==============================================================================
# Docker Compose - Laravel 12 Development Environment
# ==============================================================================

services:
  # ============================================================================
  # PHP-FPM Application
  # ============================================================================
  app:
    build:
      context: .
      dockerfile: docker/php/Dockerfile
      args:
        user: www
        uid: 1000
    container_name: laravel-app
    restart: unless-stopped
    working_dir: /var/www
    volumes:
      - ./:/var/www
    networks:
      - laravel-network
    depends_on:
      mysql:
        condition: service_healthy

  # ============================================================================
  # Nginx Webserver
  # ============================================================================
  webserver:
    image: nginx:alpine
    container_name: laravel-nginx
    restart: unless-stopped
    ports:
      - "8000:80"
    volumes:
      - ./:/var/www
      - ./docker/nginx/default.conf:/etc/nginx/conf.d/default.conf
    networks:
      - laravel-network
    depends_on:
      - app

  # ============================================================================
  # MySQL Database
  # ============================================================================
  mysql:
    image: mysql:8.0
    container_name: laravel-mysql
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    ports:
      - "3306:3306"
    volumes:
      - mysql-data:/var/lib/mysql
    networks:
      - laravel-network
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-p${MYSQL_ROOT_PASSWORD}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s

# ==============================================================================
# Volumes
# ==============================================================================
volumes:
  mysql-data:
    driver: local

# ==============================================================================
# Networks
# ==============================================================================
networks:
  laravel-network:
    driver: bridge
```

---

## 🚀 Cara Penggunaan

### Prerequisites
- Docker & Docker Compose terinstall
- Port 8000 dan 3306 tersedia

### 1. Siapkan Environment Variables

Buat file `.env` di root project:

```env
# Application
APP_NAME=LaravelDocker
APP_ENV=local
APP_DEBUG=true
APP_TIMEZONE=Asia/Jakarta
APP_URL=http://localhost:8000
APP_LOCALE=id

# MySQL Configuration
MYSQL_DATABASE=laravel_docker
MYSQL_ROOT_PASSWORD=root_password
MYSQL_USER=laravel
MYSQL_PASSWORD=laravel_password

# Database (Laravel)
DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=laravel_docker
DB_USERNAME=laravel
DB_PASSWORD=laravel_password
```

### 2. Build dan Jalankan Containers

```bash
# Build images dan start semua services
docker-compose up -d --build

# Cek status containers
docker-compose ps
```

### 3. Install Laravel & Dependencies

```bash
# Install dependencies
docker-compose exec app composer install

# Generate application key
docker-compose exec app php artisan key:generate

# Set permissions
docker-compose exec app chmod -R 775 storage bootstrap/cache
```

Atau jika project baru, jalankan:

```bash
# Install Laravel via Composer
docker-compose exec app composer create-project laravel/laravel .
```

### 4. Jalankan Database Migrations (jika ada)

```bash
docker-compose exec app php artisan migrate
```

### 5. Akses Aplikasi

| Service | URL / Akses |
|---|---|
| **Web Application** | http://localhost:8000 |
| **MySQL CLI** | `docker-compose exec mysql mysql -u root -p` |

---

## 🛠️ Command Berguna

```bash
# Lifecycle
docker-compose up -d              # Start semua services
docker-compose down               # Stop semua services
docker-compose down -v            # Stop dan hapus volumes (reset DB)
docker-compose up -d --build      # Rebuild setelah perubahan Dockerfile

# Container Access
docker-compose exec app bash              # Masuk ke container PHP
docker-compose exec mysql mysql -u root -p  # Masuk ke MySQL CLI

# Laravel Commands
docker-compose exec app php artisan migrate         # Run migrations
docker-compose exec app php artisan tinker          # Artisan tinker
docker-compose exec app php artisan key:generate    # Generate APP_KEY

# Composer
docker-compose exec app composer install   # Install dependencies
docker-compose exec app composer update    # Update dependencies

# Logs
docker-compose logs -f              # Lihat semua logs
docker-compose logs -f app          # Logs container app saja
docker-compose logs -f webserver    # Logs container nginx saja
docker-compose logs -f mysql        # Logs container mysql saja
```

---

## 📐 Arsitektur

```
Browser (localhost:8000)
        │
        ▼
┌───────────────┐
│    Nginx      │  ← laravel-nginx
│  (port 80)    │
└───────┬───────┘
        │ FastCGI (:9000)
        ▼
┌───────────────┐
│   PHP-FPM     │  ← laravel-app
│  (PHP 8.4)    │
└───────┬───────┘
        │ PDO MySQL (:3306)
        ▼
┌───────────────┐
│   MySQL 8.0   │  ← laravel-mysql
│  (persistent) │
└───────────────┘
```

**Network:** Semua services terhubung melalui custom bridge network `laravel-network`.

**Volumes:**
- Source code di-mount dari host ke `/var/www` (app & webserver)
- Data MySQL disimpan di named volume `mysql-data` untuk persistence

---

## 🐛 Troubleshooting

### Container tidak bisa start
```bash
# Cek logs untuk error details
docker-compose logs app
docker-compose logs mysql

# Restart services
docker-compose restart
```

### MySQL connection error
- Pastikan `DB_HOST=mysql` (bukan localhost)
- Cek environment variables di `.env` file
- Pastikan MySQL container sudah fully started: `docker-compose logs mysql`

### Permission denied di storage folder
```bash
docker-compose exec app chmod -R 775 storage bootstrap/cache
```

### Port 8000/3306 sudah terpakai
Ganti port di `docker-compose.yml`:
```yaml
ports:
  - "8001:80"        # Ubah 8000 ke port lain
```

### Reset database sepenuhnya
```bash
docker-compose down -v
docker-compose up -d --build
```

---

## ⚠️ Catatan Penting

1. **Port conflict**: Pastikan port `8000` dan `3306` tidak digunakan oleh service lain di host.
2. **DB_HOST**: Di dalam Docker network, gunakan nama service `mysql` bukan `localhost` atau IP address.
3. **Permissions**: User `www` (uid 1000) di container disesuaikan agar match dengan user di host.
4. **Development only**: Konfigurasi ini menggunakan `php.ini-development`. Untuk production, gunakan `php.ini-production` dan sesuaikan konfigurasi keamanan.
5. **MySQL health check**: Service `app` menunggu MySQL ready sebelum start, menghindari connection error saat startup.
6. **Storage permissions**: Pastikan folder `storage/` dan `bootstrap/cache/` memiliki permission yang tepat untuk write access.

### Error: "Class not found"
Autoload Composer belum di-generate:
```bash
docker-compose exec app composer dump-autoload
```

### Error: "Connection refused" ke MySQL
- Pastikan MySQL sudah fully started (tunggu 30 detik)
- Cek dengan: `docker-compose logs mysql`
- Restart jika perlu: `docker-compose restart mysql`

### COMMON ISSUES
```bash
❌ "Connection refused" ke MySQL
├── Cause: MySQL belum fully started
└── Solution: Tunggu 30 detik, atau restart containers
    docker-compose restart

❌ Permission denied di storage/
├── Cause: File ownership mismatch
└── Solution:
    docker-compose exec app chmod -R 775 storage bootstrap/cache
    docker-compose exec app chown -R www:www storage bootstrap/cache

❌ Port 8000 already in use
├── Cause: Ada service lain di port 8000
└── Solution: Ganti port di docker-compose.yml
    ports:
      - "8080:80"  # Ganti 8000 ke 8080

❌ "Class not found" error
├── Cause: Autoload belum di-generate
└── Solution:
    docker-compose exec app composer dump-autoload
```
