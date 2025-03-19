# Imagen Docker para WordPress con PHP 8.4 y NGINX 1.26

Esta imagen Docker proporciona un entorno optimizado para ejecutar WordPress 6.7.2 con PHP 8.4 y NGINX 1.26. Está diseñada para ser altamente configurable a través de variables de entorno y optimizada para minimizar el tamaño de la imagen.

## Características

- WordPress 6.7.2 en español de México
- PHP 8.4.5 compilado desde la fuente con optimizaciones
- NGINX 1.26.3 compilado desde la fuente
- Soporte para proxy inverso con o sin terminación SSL
- Conexión a bases de datos MySQL o MariaDB con o sin SSL
- Volúmenes para persistencia de datos
- Imagen optimizada con compilación multi-stage
- Configuración completa mediante variables de entorno

## Uso rápido

```bash
docker run -d -p 80:80 \
  -e WORDPRESS_DB_HOST=mysql \
  -e WORDPRESS_DB_NAME=wordpress \
  -e WORDPRESS_DB_USER=wordpress \
  -e WORDPRESS_DB_PASSWORD=secreto \
  -v wp_data:/var/www/html \
  nombre-de-tu-imagen
```

## Variables de entorno disponibles

### Variables de WordPress

| Variable | Descripción | Valor por defecto |
|----------|-------------|-------------------|
| `WORDPRESS_DB_HOST` | Host de la base de datos | `mysql` |
| `WORDPRESS_DB_NAME` | Nombre de la base de datos | `wordpress` |
| `WORDPRESS_DB_USER` | Usuario de la base de datos | `wordpress` |
| `WORDPRESS_DB_PASSWORD` | Contraseña de la base de datos | `""` (Requerido) |
| `WORDPRESS_DB_PREFIX` | Prefijo de las tablas | `wp_` |
| `WORDPRESS_DB_PORT` | Puerto de la base de datos | `3306` |
| `WORDPRESS_DB_SSL` | Usar SSL para la conexión a la BD | `false` |
| `WORDPRESS_DEBUG` | Activar modo de depuración | `false` |
| `WORDPRESS_BEHIND_PROXY` | Si WordPress está detrás de un proxy | `false` |
| `WORDPRESS_PROXY_SSL` | Si el proxy maneja SSL | `false` |
| `WORDPRESS_AUTO_UPDATE` | Habilitar actualizaciones automáticas | `false` |
| `WORDPRESS_LANGUAGE` | Idioma de WordPress | `es_MX` |
| `WORDPRESS_SITE_URL` | URL del sitio (opcional) | `""` |

### Variables de PHP

| Variable | Descripción | Valor por defecto |
|----------|-------------|-------------------|
| `PHP_MEMORY_LIMIT` | Límite de memoria para PHP | `128M` |
| `PHP_UPLOAD_MAX_FILESIZE` | Tamaño máximo de archivos para subir | `64M` |
| `PHP_POST_MAX_SIZE` | Tamaño máximo de datos POST | `64M` |
| `PHP_MAX_EXECUTION_TIME` | Tiempo máximo de ejecución (segundos) | `30` |
| `PHP_MAX_INPUT_VARS` | Número máximo de variables de entrada | `1000` |
| `PHP_OPCACHE_ENABLE` | Habilitar OpCache | `1` |
| `PHP_OPCACHE_MEMORY` | Memoria para OpCache (MB) | `128` |
| `PHP_ERROR_REPORTING` | Nivel de reporte de errores | `E_ALL` |
| `PHP_DISPLAY_ERRORS` | Mostrar errores | `Off` |
| `PHP_LOG_ERRORS` | Registrar errores en log | `On` |
| `PHP_ERROR_LOG` | Ruta del archivo de log de errores | `/var/log/php/error.log` |

### Variables de NGINX

| Variable | Descripción | Valor por defecto |
|----------|-------------|-------------------|
| `NGINX_CLIENT_MAX_BODY_SIZE` | Tamaño máximo del cuerpo de la petición | `64m` |
| `NGINX_WORKER_PROCESSES` | Número de procesos worker | `auto` |
| `NGINX_WORKER_CONNECTIONS` | Conexiones por worker | `1024` |
| `NGINX_KEEPALIVE_TIMEOUT` | Tiempo de keepalive | `65` |
| `NGINX_GZIP` | Habilitar compresión gzip | `on` |
| `NGINX_ACCESS_LOG` | Ruta del log de acceso | `/var/log/nginx/access.log` |
| `NGINX_ERROR_LOG` | Ruta del log de errores | `/var/log/nginx/error.log` |
| `NGINX_ERROR_LOG_LEVEL` | Nivel de log de errores | `error` |

### Variables del Sistema

| Variable | Descripción | Valor por defecto |
|----------|-------------|-------------------|
| `SYSTEM_TIMEZONE` | Zona horaria | `UTC` |

## Configuración de logs

Los niveles de log se pueden configurar mediante las siguientes variables:

- `NGINX_ERROR_LOG_LEVEL`: Controla el nivel de detalle en los logs de error de NGINX.
  - Valores posibles: `debug`, `info`, `notice`, `warn`, `error`, `crit`, `alert`, `emerg`
  - Por defecto: `error`

- `PHP_ERROR_REPORTING`: Controla qué tipos de errores de PHP se registran.
  - Valores comunes: `E_ALL`, `E_ALL & ~E_NOTICE`, `E_ERROR | E_WARNING | E_PARSE`
  - Por defecto: `E_ALL`

- `PHP_DISPLAY_ERRORS`: Controla si los errores de PHP se muestran en la salida.
  - Valores: `On`, `Off`
  - Por defecto: `Off`

- `PHP_LOG_ERRORS`: Controla si los errores de PHP se registran en el archivo de log.
  - Valores: `On`, `Off`
  - Por defecto: `On`

## Volúmenes

Esta imagen define tres volúmenes principales:

- `/var/www/html`: Archivos de WordPress
- `/etc/nginx/conf.d`: Configuraciones personalizadas de NGINX
- `/etc/php/conf.d`: Configuraciones personalizadas de PHP

## Ejemplos de uso

### Configuración básica con MySQL

```bash
docker run -d --name wordpress \
  -p 80:80 \
  -e WORDPRESS_DB_HOST=mysql \
  -e WORDPRESS_DB_NAME=wordpress \
  -e WORDPRESS_DB_USER=wordpress \
  -e WORDPRESS_DB_PASSWORD=secreto \
  -v wp_data:/var/www/html \
  nombre-de-tu-imagen
```

### Configuración con SSL detrás de un proxy

```bash
docker run -d --name wordpress \
  -p 80:80 \
  -e WORDPRESS_BEHIND_PROXY=true \
  -e WORDPRESS_PROXY_SSL=true \
  -e WORDPRESS_DB_HOST=mysql \
  -e WORDPRESS_DB_NAME=wordpress \
  -e WORDPRESS_DB_USER=wordpress \
  -e WORDPRESS_DB_PASSWORD=secreto \
  -v wp_data:/var/www/html \
  nombre-de-tu-imagen
```

### Configuración con bases de datos MySQL con SSL

```bash
docker run -d --name wordpress \
  -p 80:80 \
  -e WORDPRESS_DB_HOST=mysql.example.com \
  -e WORDPRESS_DB_NAME=wordpress \
  -e WORDPRESS_DB_USER=wordpress \
  -e WORDPRESS_DB_PASSWORD=secreto \
  -e WORDPRESS_DB_SSL=true \
  -v wp_data:/var/www/html \
  nombre-de-tu-imagen
```

### Configuración con ajustes de rendimiento optimizados

```bash
docker run -d --name wordpress \
  -p 80:80 \
  -e WORDPRESS_DB_HOST=mysql \
  -e PHP_MEMORY_LIMIT=256M \
  -e PHP_MAX_EXECUTION_TIME=60 \
  -e PHP_OPCACHE_MEMORY=256 \
  -e NGINX_WORKER_PROCESSES=4 \
  -e NGINX_WORKER_CONNECTIONS=2048 \
  -v wp_data:/var/www/html \
  nombre-de-tu-imagen
```

### Configuración para desarrollo con debugging habilitado

```bash
docker run -d --name wordpress-dev \
  -p 8080:80 \
  -e WORDPRESS_DEBUG=true \
  -e PHP_DISPLAY_ERRORS=On \
  -e PHP_ERROR_REPORTING=E_ALL \
  -e NGINX_ERROR_LOG_LEVEL=debug \
  -v $(pwd)/wordpress:/var/www/html \
  nombre-de-tu-imagen
```

## Construcción de la imagen

Para construir la imagen desde el Dockerfile:

```bash
docker build -t nombre-de-tu-imagen .
```

## Consideraciones de seguridad

- En producción, siempre cambia las contraseñas predeterminadas
- Considera usar secretos de Docker para las credenciales de la base de datos
- Desactiva el modo de depuración (`WORDPRESS_DEBUG=false`) en entornos de producción
- Para producción, utiliza `PHP_DISPLAY_ERRORS=Off` para evitar exponer información sensible

## Información de versiones

- WordPress: 6.7.2 (español de México)
- PHP: 8.4.5
- NGINX: 1.26.3
- Alpine Linux: 3.19