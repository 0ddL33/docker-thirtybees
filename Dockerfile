FROM php:8.2-apache

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV THIRTYBEES_VERSION=1.6.0

# Install system dependencies
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    unzip \
    git \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libwebp-dev \
    libxpm-dev \
    libzip-dev \
    libicu-dev \
    libxml2-dev \
    libxslt1-dev \
    libmcrypt-dev \
    libmagickwand-dev \
    libonig-dev \
    libc-client-dev \
    libkrb5-dev \
    libssl-dev \
    zlib1g-dev \
    libmemcached-dev \
    libcurl4-openssl-dev \
    pkg-config \
    libssl-dev \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# Configure and install PHP extensions
RUN docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg \
    --with-webp \
    --with-xpm

RUN docker-php-ext-configure imap --with-kerberos --with-imap-ssl

# Install PHP extensions required by Thirty Bees
RUN docker-php-ext-install -j$(nproc) \
    bcmath \
    calendar \
    exif \
    gd \
    gettext \
    imap \
    intl \
    mbstring \
    mysqli \
    opcache \
    pdo_mysql \
    soap \
    sockets \
    xsl \
    zip

# Install additional useful extensions
RUN pecl install redis-5.3.7 \
    && docker-php-ext-enable redis

RUN pecl install imagick \
    && docker-php-ext-enable imagick

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Configure PHP
COPY <<EOF /usr/local/etc/php/conf.d/thirtybees.ini
; PHP Configuration for Thirty Bees
memory_limit = 512M
max_execution_time = 300
max_input_vars = 5000
post_max_size = 64M
upload_max_filesize = 64M
max_file_uploads = 20

; OpCache settings
opcache.enable = 1
opcache.enable_cli = 1
opcache.memory_consumption = 128
opcache.interned_strings_buffer = 8
opcache.max_accelerated_files = 4000
opcache.revalidate_freq = 2
opcache.fast_shutdown = 1

; Session settings
session.cookie_httponly = 1
session.use_strict_mode = 1
session.cookie_secure = 0

; Error reporting
display_errors = Off
log_errors = On
error_log = /var/log/apache2/php_errors.log

; Date timezone
date.timezone = UTC
EOF

# Enable Apache modules
RUN a2enmod rewrite ssl headers expires deflate

# Configure Apache
COPY <<EOF /etc/apache2/sites-available/000-default.conf
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
    
    <Directory /var/www/html>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
        
        # Security headers
        Header always set X-Content-Type-Options nosniff
        Header always set X-Frame-Options DENY
        Header always set X-XSS-Protection "1; mode=block"
        
        # Cache static files
        <FilesMatch "\.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$">
            ExpiresActive On
            ExpiresDefault "access plus 1 month"
        </FilesMatch>
    </Directory>
    
    # Deny access to sensitive files
    <Files ~ "\.(tpl|yaml|yml|txt|log|twig)$">
        Require all denied
    </Files>
    
    # Deny access to config and cache directories
    <DirectoryMatch "/(config|cache|upload|download|log|mails|translations|tools)/">
        Require all denied
    </DirectoryMatch>
</VirtualHost>
EOF

# Set working directory
WORKDIR /var/www/html

# Download and extract Thirty Bees
RUN wget -O thirtybees.zip "https://github.com/thirtybees/thirtybees/releases/download/1.6.0/thirtybees-v1.6.0-php7.4.zip" \
    && unzip thirtybees.zip -d ./thirtybees/ \
    && rm thirtybees.zip \
    && mv thirtybees/* . \
    && mv thirtybees/.* . 2>/dev/null || true \
    && rmdir thirtybees \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html \
    && chmod -R 777 /var/www/html/cache \
    && chmod -R 777 /var/www/html/log \
    && chmod -R 777 /var/www/html/img \
    && chmod -R 777 /var/www/html/mails \
    && chmod -R 777 /var/www/html/modules \
    && chmod -R 777 /var/www/html/themes \
    && chmod -R 777 /var/www/html/translations \
    && chmod -R 777 /var/www/html/upload \
    && chmod -R 777 /var/www/html/download \
    && chmod -R 777 /var/www/html/config

# Install Composer dependencies
RUN if [ -f composer.json ]; then \
        composer install --no-dev --optimize-autoloader --no-interaction; \
    fi

# Create startup script
COPY <<EOF /usr/local/bin/start-thirtybees.sh
#!/bin/bash
set -e

# Create startup script
COPY <<EOF /usr/local/bin/start-thirtybees.sh
#!/bin/bash
set -e

# Create ALL necessary directories if they don't exist
mkdir -p /var/www/html/cache
mkdir -p /var/www/html/log
mkdir -p /var/www/html/img
mkdir -p /var/www/html/mails
mkdir -p /var/www/html/modules
mkdir -p /var/www/html/themes
mkdir -p /var/www/html/translations
mkdir -p /var/www/html/upload
mkdir -p /var/www/html/download
mkdir -p /var/www/html/config

# Set proper permissions (with escaped backslash)
chown -R www-data:www-data /var/www/html
find /var/www/html -type d -exec chmod 755 {} \\;
find /var/www/html -type f -exec chmod 644 {} \\;

# Set writable permissions for specific directories
chmod -R 777 /var/www/html/cache
chmod -R 777 /var/www/html/log
chmod -R 777 /var/www/html/img
chmod -R 777 /var/www/html/mails
chmod -R 777 /var/www/html/modules
chmod -R 777 /var/www/html/themes
chmod -R 777 /var/www/html/translations
chmod -R 777 /var/www/html/upload
chmod -R 777 /var/www/html/download
chmod -R 777 /var/www/html/config

# Start Apache
exec apache2-foreground
EOF

RUN chmod +x /usr/local/bin/start-thirtybees.sh

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# Expose port
EXPOSE 80

# Start the application
CMD ["/usr/local/bin/start-thirtybees.sh"]