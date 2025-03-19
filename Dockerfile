FROM alpine:3.19

# Instalar PHP, NGINX y dependencias
RUN apk add --no-cache \
    php81 \
    php81-fpm \
    php81-mysqli \
    php81-pdo_mysql \
    php81-gd \
    php81-xml \
    php81-mbstring \
    php81-json \
    php81-curl \
    php81-zip \
    php81-opcache \
    php81-exif \
    php81-intl \
    php81-dom \
    php81-fileinfo \
    php81-ctype \
    php81-session \
    php81-simplexml \
    php81-xmlreader \
    php81-xmlwriter \
    php81-phar \
    php81-openssl \
    php81-iconv \
    php81-sqlite3 \
    php81-tokenizer \
    php81-posix \
    nginx \
    supervisor \
    bash \
    tzdata \
    curl \
    ca-certificates \
    tar && \
    # Verificar instalación
    echo "Versiones instaladas:" && \
    php81 -v && \
    nginx -v && \
    # Crear directorios necesarios
    mkdir -p /run/php

# Crear usuario y grupo www-data
RUN addgroup -g 82 -S www-data 2>/dev/null || true && \
    adduser -u 82 -S -D -H -h /var/www -s /bin/bash -G www-data www-data 2>/dev/null || true && \
    # Crear directorios
    mkdir -p /var/www/html /run/php /var/log/php /var/log/nginx /var/cache/nginx && \
    chown -R www-data:www-data /var/www/html /run/php /var/log/php

# Copiar WordPress desde archivo local
COPY wordpress-6.7.2-es_MX.tar.gz /tmp/
WORKDIR /tmp
RUN tar -xzf wordpress-6.7.2-es_MX.tar.gz -C /var/www/html --strip-components=1 && \
    rm wordpress-6.7.2-es_MX.tar.gz && \
    chown -R www-data:www-data /var/www/html

# Configurar directorios de NGINX
RUN mkdir -p /etc/nginx/conf.d

# Copiar archivos de configuración
COPY nginx.conf /etc/nginx/nginx.conf
COPY wordpress.conf /etc/nginx/conf.d/default.conf
COPY php-fpm.conf /etc/php81/php-fpm.d/www.conf
COPY php.ini /etc/php81/conf.d/custom.ini

# Añadir archivos de configuración y scripts
COPY supervisord.conf /etc/supervisord.conf
COPY docker-entrypoint.sh /usr/local/bin/
COPY wp-config-generator.php /usr/local/bin/

# Hacer ejecutable el script de entrada
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Definir volúmenes
VOLUME ["/var/www/html", "/etc/nginx/conf.d", "/etc/php81/conf.d"]

# Exponer puertos
EXPOSE 80 443

# Variables de entorno
ENV WORDPRESS_DB_HOST=mysql \
    WORDPRESS_DB_NAME=wordpress \
    WORDPRESS_DB_USER=wordpress \
    WORDPRESS_DB_PASSWORD="" \
    WORDPRESS_DB_PREFIX=wp_ \
    WORDPRESS_DB_PORT=3306 \
    WORDPRESS_DB_SSL=false \
    WORDPRESS_DEBUG=false \
    WORDPRESS_BEHIND_PROXY=false \
    WORDPRESS_PROXY_SSL=false \
    WORDPRESS_AUTO_UPDATE=false \
    WORDPRESS_LANGUAGE=es_MX \
    WORDPRESS_SITE_URL="" \
    PHP_MEMORY_LIMIT=128M \
    PHP_UPLOAD_MAX_FILESIZE=64M \
    PHP_POST_MAX_SIZE=64M \
    PHP_MAX_EXECUTION_TIME=30 \
    PHP_MAX_INPUT_VARS=1000 \
    PHP_OPCACHE_ENABLE=1 \
    PHP_OPCACHE_MEMORY=128 \
    PHP_ERROR_REPORTING=E_ALL \
    PHP_DISPLAY_ERRORS=Off \
    PHP_LOG_ERRORS=On \
    PHP_ERROR_LOG=/var/log/php/error.log \
    NGINX_CLIENT_MAX_BODY_SIZE=64m \
    NGINX_WORKER_PROCESSES=auto \
    NGINX_WORKER_CONNECTIONS=1024 \
    NGINX_KEEPALIVE_TIMEOUT=65 \
    NGINX_GZIP=on \
    NGINX_ACCESS_LOG=/var/log/nginx/access.log \
    NGINX_ERROR_LOG=/var/log/nginx/error.log \
    NGINX_ERROR_LOG_LEVEL=error \
    SYSTEM_TIMEZONE=UTC

# Directorio de trabajo
WORKDIR /var/www/html

# Punto de entrada y comando
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["supervisord", "-c", "/etc/supervisord.conf"]