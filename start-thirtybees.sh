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

# Set proper permissions
chown -R www-data:www-data /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;

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
echo "Starting Apache..."
exec apache2-foreground
