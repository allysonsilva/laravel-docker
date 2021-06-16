ARG LOCAL_APP_FOLDER=./src
ARG LOCAL_DOCKER_FOLDER=./docker
ARG PHP_BASE_IMAGE_VERSION=8.0-fpm-alpine

#####
## COMPOSER
#####

FROM composer:2.0 as vendor

WORKDIR /app

# https://getcomposer.org/doc/03-cli.md#composer-home
ENV COMPOSER_HOME /composer

ARG LOCAL_APP_FOLDER

# Copy only the files needed to download dependencies to avoid redownloading them when our code changes
COPY $LOCAL_APP_FOLDER/composer.json composer.json
COPY $LOCAL_APP_FOLDER/composer.lock composer.lock

RUN set -xe \
    &&  composer install \
            --optimize-autoloader \
            --ignore-platform-reqs \
            --prefer-dist \
            --ansi \
            --no-dev \
            --profile \
            --no-cache \
            --no-scripts \
            --no-interaction

#####
## FRONTEND
#####

FROM node:16-alpine as frontend

WORKDIR /app

ARG LOCAL_APP_FOLDER

# COPY package-lock.json package-lock.json
COPY $LOCAL_APP_FOLDER/package.json $LOCAL_APP_FOLDER/webpack.mix.js ./
COPY $LOCAL_APP_FOLDER/resources/js resources/js/
COPY $LOCAL_APP_FOLDER/resources/css resources/css/
# COPY $LOCAL_APP_FOLDER/resources/images/ public/images/
COPY $LOCAL_APP_FOLDER/public/ public/

RUN set -xe \
    && npm install && npm run production

#####
## APP CONTAINER
#####

FROM php:$PHP_BASE_IMAGE_VERSION

ARG LOCAL_APP_FOLDER
ARG LOCAL_DOCKER_FOLDER

# = /usr/local/etc/php
ENV PHP_INI_DIR ${PHP_INI_DIR:-/usr/local/etc/php}
# = /usr/local/etc/php/conf.d
ENV PHP_INI_SCAN_DIR ${PHP_INI_DIR}/conf.d
# = /usr/local/etc/php-fpm.d
ENV PHP_FPM_POOL_DIR ${PHP_INI_DIR}-fpm.d
# Default PATH LOG
ENV LOG_PATH=/usr/local/var/log
# Path logs PHP/PHP-FPM
ENV PHP_LOG_PATH=$LOG_PATH/php

# Default directory for application deployment
# Location of the folder in the container, path of the folder inside the container
ARG REMOTE_SRC=/var/www/app
ENV REMOTE_SRC $REMOTE_SRC

# Image user
ARG USER_NAME=app
ENV USER_NAME $USER_NAME

ARG USER_UID=1000
ARG USER_GID=1000

# Path docker PHP/APP folder
# Path Config/Dockerfile PHP/APP
ARG LOCAL_DOCKER_PHP_PATH=$LOCAL_DOCKER_FOLDER/php
ENV LOCAL_DOCKER_PHP_PATH $LOCAL_DOCKER_PHP_PATH

ARG LOCAL_APP_FOLDER
ENV LOCAL_APP_FOLDER $LOCAL_APP_FOLDER

# app || queue || scheduler
ARG CONTAINER_ROLE=app
ENV CONTAINER_ROLE $CONTAINER_ROLE

# worker or horizon {Variables applied when $CONTAINER_ROLE=queue}
ARG LARAVEL_QUEUE_MANAGER
ENV LARAVEL_QUEUE_MANAGER ${LARAVEL_QUEUE_MANAGER:-worker}

ARG APP_ENV=production
ENV APP_ENV ${APP_ENV:-production}

RUN set -xe; \
    \
    echo "---> Installing PHP Extensions"; \
    \
    apk update; \
    \
    apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        curl-dev \
        pcre-dev \
        libressl-dev \
        # Mbstring
        oniguruma-dev \
        # SQLite3
        sqlite-dev \
        # for intl extension
        icu-dev \
        # for GD
        freetype-dev \
        libpng-dev \
        libjpeg-turbo-dev \
        libwebp-dev \
        # for zip extension
        zlib-dev \
        libzip-dev \
        gnutls-dev \
        # for xslt
        libxslt-dev \
        libgcrypt-dev \
        # for gpm extension
        gmp-dev \
        # for soap
        libxml2-dev \
    ; \
    apk add --no-cache --virtual .persistent-deps \
        vim \
        # for intl
        icu-libs \
        # for mongodb
        libssl1.1 \
        # for zip
        libzip \
        # for xslt
        libxslt \
        # for gpm
        gmp \
    ; \
    docker-php-ext-configure gd \
        --enable-gd \
        --with-jpeg \
        --with-webp \
        --with-freetype \
    ; \
    docker-php-ext-configure mysqli --with-mysqli=mysqlnd && \
    docker-php-ext-configure pdo_mysql --with-pdo-mysql=mysqlnd && \
    docker-php-ext-configure zip --with-zip && \
    docker-php-ext-install -j $(nproc) \
        exif \
        calendar \
        xsl \
        intl \
        gd \
        bcmath \
        mbstring \
        gmp \
        pcntl \
        mysqli \
        pdo_mysql \
        soap \
        sockets \
        opcache \
        zip \
    ; \
    pecl install -o -f \
        ds-1.3.0 \
        mongodb-1.9.1 \
        xdebug-3.0.4 \
    ; \
    # Igbinary: Is a drop in replacement for the standard php serializer.
    # MessagePack: Is an efficient binary serialization format.
    pecl install -o -f \
        igbinary-3.2.2 \
        msgpack-2.1.2 \
    ; \
    # redis/configure \
    #       --with-php-config=/usr/local/bin/php-config \
    #       --enable-redis-igbinary=yes \
    #       --enable-redis-lzf=no \
    #       --enable-redis-zstd=no
    printf "yes \n no \n no \n" | pecl install redis-5.3.4 \
    ; \
    docker-php-ext-enable \
        ds \
        igbinary \
        msgpack \
        redis \
        mongodb \
        xdebug \
    ; \
    php --version \
    ; \
    runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )"; \
    apk add --no-cache $runDeps; \
    apk del --no-network .build-deps; \
    rm -rf /tmp/* /var/cache/apk/*

RUN set -xe; \
    \
    echo "---> Installing Packages Dependencies"; \
    \
    apk update; \
    \
    apk add --update --no-cache \
        fd \
        exa \
        git \
        sudo \
        curl \
        wget \
        fcgi \
        make \
        bash \
        tini \
        logrotate \
        bind-tools \
        supervisor \
        mysql-client \
        busybox-suid \
        openssh-client \
        bash-completion; \
    \
    rm -rf /tmp/* /var/cache/apk/*

# TODO: Remove when https://pecl.php.net/package/amqp have support for php 8
# @see https://github.com/mlocati/docker-php-extension-installer/blob/master/install-php-extensions#L1322
RUN set -xe; \
    \
    echo "---> Installing PHP AMQP"; \
    \
    apk update; \
    \
    apk add --no-cache \
        rabbitmq-c \
    ; \
    \
    apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        rabbitmq-c-dev \
    ; \
    wget -c https://codeload.github.com/php-amqp/php-amqp/tar.gz/df1241852b359cf12c346beaa68de202257efdf1 -O"php-amqp.tar.gz"; \
    gzip -dc php-amqp*.tar.gz | tar xf -; \
    \
    cd php-amqp-* && phpize && ./configure; \
    \
    make -j $(nproc) && make install; \
    docker-php-ext-enable amqp; \
    \
    # Cleanup
    cd .. && rm -Rf php-amqp*; \
    \
    runDeps="$( \
            scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
                | tr ',' '\n' \
                | sort -u \
                | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
        )" \
    \
    && apk add --no-cache $runDeps \
    && apk del --no-network .build-deps \
    && rm -rf /tmp/* /var/cache/apk/*

# NewRelic
# Variables for enabling NewRelic
ENV FRAMEWORK=laravel \
    NEW_RELIC_ENABLED=false \
    NEW_RELIC_APPNAME="" \
    NEW_RELIC_LICENSE_KEY=""

ARG NEWRELIC_VERSION=9.17.1.301
ENV NEWRELIC_VERSION $NEWRELIC_VERSION

ENV NEWRELIC_NAME newrelic-php5-${NEWRELIC_VERSION}-linux-musl
ENV NEWRELIC_AGENT_URL https://download.newrelic.com/php_agent/archive/${NEWRELIC_VERSION}/${NEWRELIC_NAME}.tar.gz

RUN set -xe; \
    \
    echo "---> Adding Support for NewRelic"; \
    \
    apk update \
    \
    && cd /tmp/ \
    && wget -O /tmp/${NEWRELIC_NAME}.tar.gz ${NEWRELIC_AGENT_URL} \
    && tar -C /tmp -xzf ${NEWRELIC_NAME}.tar.gz \
    && export NR_INSTALL_USE_CP_NOT_LN=1 \
    && export NR_INSTALL_SILENT=1 \
    && /tmp/newrelic-php5-*/newrelic-install install \
    && rm -rf /tmp/newrelic /tmp/nrinstall*

#####
## CONFIGURATIONS
#####

COPY $LOCAL_DOCKER_PHP_PATH/configs/conf.d/xdebug.ini $PHP_INI_SCAN_DIR/docker-php-ext-xdebug.ini
COPY $LOCAL_DOCKER_PHP_PATH/configs/conf.d/opcache.ini $PHP_INI_SCAN_DIR/docker-php-ext-opcache.ini

# /usr/local/etc/php/php.ini
COPY $LOCAL_DOCKER_PHP_PATH/configs/php-$APP_ENV.ini $PHP_INI_DIR/php.ini
# /usr/local/etc/php-fpm.conf
COPY $LOCAL_DOCKER_PHP_PATH/configs/fpm/global.conf $PHP_INI_DIR-fpm.conf
# /usr/local/etc/php-fpm.d/(www.conf|*)
COPY $LOCAL_DOCKER_PHP_PATH/configs/fpm/pools/ $PHP_FPM_POOL_DIR/

# SUPERVISOR CONF's
COPY $LOCAL_DOCKER_PHP_PATH/queue/supervisord.conf /etc/supervisor/supervisord.conf
COPY $LOCAL_DOCKER_PHP_PATH/queue/templates/* /etc/supervisor/conf.d/

RUN set -xe \
    && echo "---> Forward request and error logs to docker log collector" \
    && mkdir -p $PHP_LOG_PATH $PHP_LOG_PATH/rotate $LOG_PATH/supervisor \
    \
    && touch $PHP_LOG_PATH/php-fpm.access.log \
    && touch $PHP_LOG_PATH/php-fpm.errors.log \
    && touch $PHP_LOG_PATH/php-fpm.slow.log \
    && touch $PHP_LOG_PATH/php.errors.log

RUN set -xe \
    && /usr/local/sbin/php-fpm --test \
    && PHP_ERROR="$( php -v 2>&1 1>/dev/null )" \
    && if [ -n "$PHP_ERROR" ]; then echo "$PHP_ERROR"; false; fi \
    && php -m; php -v; php --ini \
    && php -i | grep -E '^opcache\.(enable_cli|jit|jit_buffer_size) '

RUN if [ "$USER_UID" != 1000 ]; then \
        set -xe \
        # && echo "---> Adding USER docker(1000) to IMAGE" \
        # && addgroup -g 1000 docker \
        # && adduser -D -u 1000 -G docker docker \
        # && echo "docker ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers \
        && echo "---> Adding the www-data(1000) user" \
        && deluser --remove-home www-data \
        && delgroup www-data || true \
        && addgroup --gid 1000 www-data \
        && adduser --gecos "" --disabled-password --uid 1000 --ingroup www-data --shell /bin/bash www-data \
        && echo "www-data ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers \
        && chown -R www-data:www-data /home/www-data \
    ;fi

RUN set -xe \
    && echo "---> Adding USER to IMAGE" \
    && addgroup --gid ${USER_GID:-1000} $USER_NAME \
    && adduser --gecos "" --disabled-password --uid ${USER_UID:-1000} --ingroup $USER_NAME --shell /bin/bash $USER_NAME \
    && echo "$USER_NAME ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers \
    # Replace it with /bin/bash:
    && sed -i "/root/s/bin\/ash/bin\/bash/g" /etc/passwd

RUN if [ ! -d "$REMOTE_SRC" ]; then \
        mkdir -p /tmp/php /tmp/php/sessions /tmp/php/uploads $REMOTE_SRC \
        && chown -R $USER_NAME:$USER_NAME $REMOTE_SRC /var/www \
    ;fi

RUN set -xe \
    && echo "---> Remove default files PHP-FPM" \
    # /usr/local/etc/php-fpm.conf.default
    && rm $PHP_INI_DIR-fpm.conf.default \
    # /usr/local/etc/php-fpm.d/www.conf.default
    && rm $PHP_FPM_POOL_DIR/www.conf.default \
    # /usr/local/etc/php-fpm.d/docker.conf
    && rm $PHP_FPM_POOL_DIR/docker.conf \
    # /usr/local/etc/php-fpm.d/zz-docker.conf
    && rm $PHP_FPM_POOL_DIR/zz-docker.conf \
    && rm -rf /tmp/pear ~/.pearrc \
    && rm -rf /var/www/html

COPY $LOCAL_DOCKER_PHP_PATH/logrotate/cronjob /home/${USER_NAME}/logrotate/
COPY $LOCAL_DOCKER_PHP_PATH/logrotate/logrotate.conf /home/${USER_NAME}/logrotate/
COPY $LOCAL_DOCKER_PHP_PATH/logrotate/conf.d/* /home/${USER_NAME}/logrotate/conf.d/

RUN set -xe; \
    \
    # ps -ef | grep cron | grep -v grep
    echo "---> Create Cron Files"; \
    \
    touch /var/log/cron.log; \
    \
    mkdir -p /var/spool/cron/crontabs; \
    \
    touch /var/spool/cron/crontabs/$USER_NAME

# CRON LOGROTATE
RUN set -xe; \
    \
    echo "---> Logrotate Config"; \
    \
    LOGROTATE_PATH=/home/$USER_NAME/logrotate; \
    mkdir -p $LOGROTATE_PATH/conf.d; \
    touch $LOGROTATE_PATH/status; \
    \
    mkdir -p /var/log/rotate; \
    touch /var/log/logrotate.log; \
    \
    rm -f /etc/periodic/daily/logrotate; \
    rm -rf /etc/logrotate.*

RUN set -xe \
    && echo "---> Changing Permissions" \
    && chown -R $USER_NAME:$USER_NAME \
        /usr/local/etc \
        /var/run /var/run/ \
        /usr/local/var/run \
        /home/${USER_NAME} \
        $LOG_PATH \
        /var/log \
        /tmp/php

# ENTRYPOINT
COPY $LOCAL_DOCKER_PHP_PATH/docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

#####
## APPLICATION
#####

# Application directory
WORKDIR $REMOTE_SRC

# Define the running USER
USER $USER_NAME

# Remove folder docker
RUN     if [ -d ${LOCAL_DOCKER_FOLDER} ]; then \
            rm -rf ${LOCAL_DOCKER_FOLDER} \
        ;fi

# Files APP
# Copy our application
COPY $LOCAL_APP_FOLDER $REMOTE_SRC

## Copy the downloaded dependencies from the {vendor} stage
COPY --from=vendor /app/vendor/ ./vendor/
COPY --from=vendor /app/composer.json ./composer.json
COPY --from=vendor /app/composer.lock ./composer.lock

## Copy the downloaded dependencies from the {frontend} stage
COPY --from=frontend /app/public/ ./public/

RUN sudo mkdir -p   storage/logs \
                    storage/logs/rotate \
                    storage/app/public \
                    storage/framework/cache \
                    storage/framework/sessions \
                    storage/framework/views

RUN sudo chown -R $USER_NAME:$USER_NAME $REMOTE_SRC /var/www

RUN set -xe \
    && echo "---> Installing Composer" \
    && COMPOSER_HOME="/home/${USER_NAME}/.composer/" \
    && curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer --version=2.0.8 \
    && composer clear-cache \
    && composer --ansi

# Environment variables
# Default: /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV PATH="$PATH:/home/${USER_NAME}/.composer/vendor/bin"

RUN set -xe \
    && php artisan optimize:clear --ansi || true \
    \
    && composer run-script post-root-package-install || true \
    && composer run-script post-create-project-cmd || true \
    && composer dump-autoload --optimize --classmap-authoritative --no-dev --ansi || true \
    && composer run-script post-autoload-dump || true

RUN set -xe \
    && DEFAULT_PARAMETERS_FD="--threads $(nproc) --hidden --no-ignore --ignore-case --show-errors" \
    && DEFAULT_EXCLUDE_FD='--exclude public -E .git -E vendor' \
    # -E, --exclude <pattern>... Exclude files/directories that match the given glob pattern
    # -E "{**/fileX,**/fileY}"
    # -E "{folderX,folderY}"
    && sudo fd $DEFAULT_EXCLUDE_FD $DEFAULT_PARAMETERS_FD --type directory --exec chmod 755 {} \; . $REMOTE_SRC \
    && sudo fd $DEFAULT_EXCLUDE_FD $DEFAULT_PARAMETERS_FD --type file --exec chmod 644 {} \; . $REMOTE_SRC \
    && sudo chgrp -R $USER_NAME storage bootstrap/cache \
    && sudo chmod -R ug+rwx storage bootstrap/cache \
    && sudo chown -R $USER_NAME:$USER_NAME $REMOTE_SRC \
    && sudo chmod a+x artisan \
    && php artisan view:clear \
    && php artisan route:clear \
    && php artisan config:clear \
    && php artisan storage:link \
    && php artisan clear-compiled \
    && exa --all --group --header --links --long --accessed --modified --git --icons --color=always

VOLUME ${LOG_PATH}

# Let INIT PID 1 handle all the zombies
ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]
# As non daemon and single base image, it may be used as cli container
CMD ["/bin/bash"]

# Override stop signal to stop process gracefully
# https://github.com/php/php-src/blob/php-8.0.1/sapi/fpm/php-fpm.8.in#L163
STOPSIGNAL SIGQUIT

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
        echo 'session.use_strict_mode = 1'; \
        echo 'session.use_cookies = 1'; \
        echo 'session.cookie_secure = 1'; \
        echo 'session.use_only_cookies = 1'; \
        echo 'session.cookie_httponly = 1'; \
        echo 'session.cookie_samesite = "Strict"'; \
    } > /usr/local/etc/php/conf.d/zz-session-strict.ini

# PHP-FPM
EXPOSE 9000 9001 9003 8080 8000

# vim:set ft=dockerfile:
