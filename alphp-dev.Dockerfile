
FROM swoft/alphp:cli
LABEL maintainer="liyuzhao <562405704@qq.com>" version="1.0"

ENV FILEBEAT_VERSION=6.4.2 \
    FILEBEAT_SHA1=ee4e98fe5e3bfa31d40069912755a7396f7d570c973c6e9f7d0ff56f514db1cb15467cdaac17ef01f05fea1258bed3d511c569e0b716d44365fba2f9ebb42dd0

WORKDIR /var/www

RUN set -ex \
        && php -m \
        # install some tools
        && apk update \
        && apk add --no-cache \
            php7-fpm php7-pcntl \
            nginx vim wget net-tools git zip unzip apache2-utils mysql-client redis \
        && apk del --purge *-dev \
        && rm -rf /var/cache/apk/* /tmp/* /usr/share/man \
        # && rm /etc/nginx/conf.d/default.conf /etc/nginx/nginx.conf \
        # install latest composer
        && wget https://getcomposer.org/composer.phar \
        && mv composer.phar /usr/local/bin/composer \
        # - config nginx
        && mkdir /run/nginx \
        # - config PHP-FPM
        && cd /etc/php7 \
        && { \
            echo "[global]"; \
            echo "pid = /var/run/php-fpm.pid"; \
            echo "[www]"; \
            echo "user = www-data"; \
            echo "group = www-data"; \
        } | tee php-fpm.d/custom.conf \
        # config site
        && chown -R www-data:www-data /var/www \
        && { \
            echo "#!/bin/sh"; \
            echo "nginx -g 'daemon on;'"; \
            # echo "php /var/www/uem.phar taskServer:start -d"; \
            echo "php-fpm7 -F"; \
        } | tee /run.sh \
        && chmod 755 /run.sh && \
          wget https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-${FILEBEAT_VERSION}-linux-x86_64.tar.gz -O /home/filebeat.tar.gz && \
          cd /home && \
          echo "${FILEBEAT_SHA1}  filebeat.tar.gz" | sha512sum -c - && \
          tar xzvf filebeat.tar.gz && \
          cd filebeat-* && \
          cp filebeat /bin && \
          cd /home && \
          rm -rf filebeat* && \
          apt-get purge -y wget && \
          apt-get autoremove -y && \
          apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

VOLUME ["/var/www", "/data"]

EXPOSE 9501 80

# COPY docker/config/nginx.conf /etc/nginx/nginx.conf
# COPY docker/config/app-vhost.conf /etc/nginx/conf.d/app-vhost.conf

CMD /run.sh
