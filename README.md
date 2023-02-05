# Dockerize a PHP Application

This is extending image from https://github.com/trafex/docker-php-nginx with
changes to ease containerising a PHP application, by using this image as base.

The main points still apply. The image is:

* based on Alpine Linux distribution
* running unprivileged Nginx and PHP-FPM from supervisord

The respective changes include installing of `pdo_mysql` extentsion instead of
MySQLi. And setting the default public directory differently to keep it closer
to other images, such as `composer`.

## Extend Server

The repository already contains a default server configuration that might be
sufficient in most cases. When necessary it can be extended (rather than
replaced completely) by providing one or more `.default_conf` files.

The default server only uses HTTP and listens on port 8080. This is done to ease
the server configuration. HTTPS can be terminated before the requests are
proxied to the service; for details see below.

## Configure Nginx Public Root

The public root in Nginx is not set by default. Instead the configuration
contains `/app/public_html` placeholder which can be replaced with the desired
directory.

The file that contains the placeholder is `/etc/nginx/conf.d/default.conf`.

It can be replaced using, e.g., `sed`, as shown in the following `Dockerfile`
and `docker-compose.yaml` example.

```dockerfile
FROM soch1/php-nginx

# change the user to allow modification or files owned by root
USER root

# then replace the variable placeholder
RUN sed -i -- "s/public_html/your\/public\/dir/g" /etc/nginx/conf.d/default.conf

# use non-root user again
USER nobody

```

```yaml
services:
  app:
    build: .
    volumes:
      - ./local/path/to/www:/app
```

The example above sets the public root to `/app/your/public/dir`.

### Use as Base Image

The image defined in this repository is also expected to be used as base when
defining other images.

```Dockerfile
FROM soch1/php-nginx

# update directory with publicly available content
USER root
RUN sed -i -- "s/public_html/<your_directory>/g" /etc/nginx/conf.d/default.conf
USER nobody

WORKDIR /app
COPY --chown=nobody <your_directory>/ /app

# append other configuration to the server if necessary
#
# for instance we can set expiration headers for cache, or to disable access
# logging on favicon.ico and robots.txt
#
# note the custom file extension used, this is to higlight the configuration is
# extending the default rather than adding a new server block
COPY <your_configuration_file>.conf /etc/nginx/conf.d/custom.default_conf
```

### Use with Composer

With dependencies managed with [Composer](https://getcomposer.org/) the build
definition could be changed to use a multi-stage build.

Note that only the downloaded dependencies should be copied over and not the
composer itself.

```Dockerfile
FROM composer AS composer

# copying the source directory and install the dependencies with composer
COPY <your_directory>/ /app
RUN composer install \
  --no-dev \
  --optimize-autoloader \
  --no-interaction \
  --no-progress

# continue stage build with the desired image and copy the source including the
# dependencies downloaded by composer
FROM soch1/php-nginx

# update directory with publicly available content
USER root
RUN sed -i -- "s/public_html/<your_directory>/g" /etc/nginx/conf.d/default.conf
USER nobody

COPY --chown=nginx --from=composer /app /app

# make logging and cache directories needed by the application,
# building using nginx user therefore ownership setup is unnecessary as the
# directories are created for current user
WORKDIR /app
RUN mkdir log temp

# append other configuration to the server if necessary
#
# for instance we can set expiration headers for cache, or to disable access
# logging on favicon.ico and robots.txt
#
# note the custom file extension used, this is to higlight the configuration is
# extending the default rather than adding a new server block
COPY <your_configuration_file>.conf /etc/nginx/conf.d/custom.default_conf
```

## Run with HTTPS

A docker image containing both the PHP application and the HTTP server can be
then started as service using `docker-compose`.

```yaml
version: '3'

services:
  app:
    image: image-that-you-built-above
    restart: unless-stopped
```

In cases When HTTP is sufficient the server can be then exposed directly by
mapping the ports.

```yaml
    ports:
      - 80:8080
```

### Proxy Requests

With any advanced configuration needed, such as terminating HTTPS, a load
balancer server should be started to terminate HTTPS, and to proxy the requests
to the service.

```
location /api/ {
  proxy_pass http://<container_name>;
  proxy_set_header Host $http_host;
  proxy_set_header X-Real-IP $remote_addr;
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Proto $scheme;
  proxy_read_timeout 900;
}
```

## Availability

The image can be downloaded from [Docker Hub](https://hub.docker.com/r/soch1/php-nginx).

### Build Locally

If necessary the respective image can be build locally, instead of downloading
it from the Docker Hub.

```bash
docker build -t php-nginx .
```
