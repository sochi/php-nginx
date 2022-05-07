# based on alpine:3.15
FROM trafex/php-nginx:2.5.0

USER root
RUN apk add --no-cache \
  php8-fileinfo \
  php8-pdo_mysql \
  php8-simplexml \
  php8-tokenizer \
  php8-xmlwriter \
  php8-zlib

# setting log rotation to keep last 2 weeks
RUN sed -ie -- "/rotate/s/[0-9]\+/14/g" /etc/logrotate.d/nginx

# copy the default configuration that uses public_html
COPY config/nginx.conf /etc/nginx/nginx.conf
# set process supervisor
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# switch user again
USER nobody

EXPOSE 8080

ENTRYPOINT ["/usr/bin/supervisord"]
CMD ["-nc", "/etc/supervisor/conf.d/supervisord.conf"]
