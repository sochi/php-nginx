# based on alpine:3.17
FROM trafex/php-nginx:3.0.0

USER root
RUN apk add --no-cache \
  php81-fileinfo \
  php81-pdo_mysql \
  php81-simplexml \
  php81-tokenizer \
  php81-xmlwriter

# setting log rotation to keep last 2 weeks
RUN sed -ie -- "/rotate/s/[0-9]\+/14/g" /etc/logrotate.d/nginx

COPY config/nginx.conf /etc/nginx/nginx.conf
# copy the modified configuration that uses public_html
COPY config/conf.d /etc/nginx/conf.d/

# set process supervisor
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# switch user again
USER nobody

EXPOSE 8080

ENTRYPOINT ["/usr/bin/supervisord"]
CMD ["-nc", "/etc/supervisor/conf.d/supervisord.conf"]
