#!/bin/bash
set -e

# Set system timezone
if [ ! -z "$SYSTEM_TIMEZONE" ]; then
    echo "Setting timezone to $SYSTEM_TIMEZONE"
    ln -sf /usr/share/zoneinfo/$SYSTEM_TIMEZONE /etc/localtime
    echo $SYSTEM_TIMEZONE > /etc/timezone
fi

# Replace environment variables in NGINX configuration files using sed
sed -i "s/\${NGINX_CLIENT_MAX_BODY_SIZE}/$NGINX_CLIENT_MAX_BODY_SIZE/g" /etc/nginx/conf.d/default.conf
sed -i "s/\${NGINX_WORKER_PROCESSES}/$NGINX_WORKER_PROCESSES/g" /etc/nginx/nginx.conf
sed -i "s/\${NGINX_WORKER_CONNECTIONS}/$NGINX_WORKER_CONNECTIONS/g" /etc/nginx/nginx.conf
sed -i "s/\${NGINX_KEEPALIVE_TIMEOUT}/$NGINX_KEEPALIVE_TIMEOUT/g" /etc/nginx/nginx.conf
sed -i "s/\${NGINX_GZIP}/$NGINX_GZIP/g" /etc/nginx/nginx.conf
sed -i "s|\${NGINX_ACCESS_LOG}|$NGINX_ACCESS_LOG|g" /etc/nginx/nginx.conf
sed -i "s|\${NGINX_ERROR_LOG}|$NGINX_ERROR_LOG|g" /etc/nginx/nginx.conf
sed -i "s/\${NGINX_ERROR_LOG_LEVEL}/$NGINX_ERROR_LOG_LEVEL/g" /etc/nginx/nginx.conf

# Replace PHP-FPM environment variables using sed
sed -i "s/\${PHP_MEMORY_LIMIT}/$PHP_MEMORY_LIMIT/g" /etc/php81/php-fpm.d/www.conf
sed -i "s/\${PHP_UPLOAD_MAX_FILESIZE}/$PHP_UPLOAD_MAX_FILESIZE/g" /etc/php81/php-fpm.d/www.conf
sed -i "s/\${PHP_POST_MAX_SIZE}/$PHP_POST_MAX_SIZE/g" /etc/php81/php-fpm.d/www.conf
sed -i "s/\${PHP_MAX_EXECUTION_TIME}/$PHP_MAX_EXECUTION_TIME/g" /etc/php81/php-fpm.d/www.conf
sed -i "s/\${PHP_MAX_INPUT_VARS}/$PHP_MAX_INPUT_VARS/g" /etc/php81/php-fpm.d/www.conf

# Replace PHP environment variables using sed
sed -i "s/\${PHP_MEMORY_LIMIT}/$PHP_MEMORY_LIMIT/g" /etc/php81/conf.d/custom.ini
sed -i "s/\${PHP_UPLOAD_MAX_FILESIZE}/$PHP_UPLOAD_MAX_FILESIZE/g" /etc/php81/conf.d/custom.ini
sed -i "s/\${PHP_POST_MAX_SIZE}/$PHP_POST_MAX_SIZE/g" /etc/php81/conf.d/custom.ini
sed -i "s/\${PHP_MAX_EXECUTION_TIME}/$PHP_MAX_EXECUTION_TIME/g" /etc/php81/conf.d/custom.ini
sed -i "s/\${PHP_MAX_INPUT_VARS}/$PHP_MAX_INPUT_VARS/g" /etc/php81/conf.d/custom.ini
sed -i "s/\${PHP_OPCACHE_ENABLE}/$PHP_OPCACHE_ENABLE/g" /etc/php81/conf.d/custom.ini
sed -i "s/\${PHP_OPCACHE_MEMORY}/$PHP_OPCACHE_MEMORY/g" /etc/php81/conf.d/custom.ini
sed -i "s/\${PHP_ERROR_REPORTING}/$PHP_ERROR_REPORTING/g" /etc/php81/conf.d/custom.ini
sed -i "s/\${PHP_DISPLAY_ERRORS}/$PHP_DISPLAY_ERRORS/g" /etc/php81/conf.d/custom.ini
sed -i "s/\${PHP_LOG_ERRORS}/$PHP_LOG_ERRORS/g" /etc/php81/conf.d/custom.ini
sed -i "s|\${PHP_ERROR_LOG}|$PHP_ERROR_LOG|g" /etc/php81/conf.d/custom.ini
sed -i "s/\${SYSTEM_TIMEZONE}/$SYSTEM_TIMEZONE/g" /etc/php81/conf.d/custom.ini

# Create wp-config.php if it doesn't exist
if [ ! -f /var/www/html/wp-config.php ]; then
    echo "WordPress config file not found, creating..."
    
    # Check for required database password
    if [ -z "$WORDPRESS_DB_PASSWORD" ]; then
        echo "ERROR: WORDPRESS_DB_PASSWORD environment variable is required but not set."
        echo "For security reasons, you must explicitly set a password and not rely on defaults."
        exit 1
    fi
    
    # Use PHP to generate config
    php81 /usr/local/bin/wp-config-generator.php
fi

# Set proper permissions
chown -R www-data:www-data /var/www/html
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;

# Create log directories with proper permissions
mkdir -p /var/log/nginx /var/log/php
chown -R www-data:www-data /var/log/php
chmod -R 755 /var/log/nginx /var/log/php

# Ensure PHP socket directory exists with correct permissions
mkdir -p /run/php
chown -R www-data:www-data /run/php
chmod -R 755 /run/php

# Define custom path for wp-content
WORDPRESS_CONTENT_REL_DIR=${WORDPRESS_CONTENT_DIR:-/wp-content}

# Convert to absolute path if necessary
if [[ "$WORDPRESS_CONTENT_REL_DIR" != /* ]]; then
    WORDPRESS_CONTENT_ABS_DIR="/var/www/html$WORDPRESS_CONTENT_REL_DIR"
else
    WORDPRESS_CONTENT_ABS_DIR="$WORDPRESS_CONTENT_REL_DIR"
fi

# Check if custom directory exists (mounted volume)
if [ -d "$WORDPRESS_CONTENT_ABS_DIR" ]; then
    echo "Custom wp-content directory detected at $WORDPRESS_CONTENT_ABS_DIR"
    
    # Check if it's empty
    if [ -z "$(ls -A $WORDPRESS_CONTENT_ABS_DIR)" ]; then
        echo "Custom directory is empty, copying original content..."
        
        # Copy original content
        cp -r /var/www/html/wp-content/* $WORDPRESS_CONTENT_ABS_DIR/
        
        echo "Content copied successfully."
    else
        echo "Custom directory already contains files, using existing content."
    fi
    
    # Configure WordPress to use custom directory
    if [ -f /var/www/html/wp-config.php ]; then
        # Check if configuration is already present
        if ! grep -q "WP_CONTENT_DIR" /var/www/html/wp-config.php; then
            # Add configuration before the ABSPATH line
            SITE_URL=$(grep "WP_HOME" /var/www/html/wp-config.php | grep -o "'[^']*'" | tail -1 | tr -d "'")
            if [ -z "$SITE_URL" ]; then
                SITE_URL=""
            fi
            CONTENT_URL="${SITE_URL}${WORDPRESS_CONTENT_REL_DIR}"
            
            sed -i "/ABSPATH/i \/** Custom content directory *\/\ndefine('WP_CONTENT_DIR', '$WORDPRESS_CONTENT_ABS_DIR');\ndefine('WP_CONTENT_URL', '$CONTENT_URL');" /var/www/html/wp-config.php
            
            echo "WordPress configured to use custom content directory."
        fi
    fi
    
    # Create symbolic link for compatibility
    if [ -d "/var/www/html/wp-content" ] && [ ! -L "/var/www/html/wp-content" ]; then
        mv /var/www/html/wp-content /var/www/html/wp-content-original
        ln -sf $WORDPRESS_CONTENT_ABS_DIR /var/www/html/wp-content
        echo "Symbolic link created for compatibility."
    fi
else
    echo "ERROR: Custom directory $WORDPRESS_CONTENT_ABS_DIR does not exist."
    echo "Please ensure you mount a volume at this location."
    exit 1
fi

exec "$@"