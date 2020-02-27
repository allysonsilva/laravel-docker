FROM php:7.4-fpm

# Add label for documentation
LABEL   maintainer="Allyson Silva <support@allyson.tech>" \
        description="Base image for PHP applications" \
        version="base"

####
## DEFAULT CONFIGURATIONS
####

# If an ARG instruction has a default value and if there is no value passed at build-time, the builder uses the default
ARG DEFAULT_USER=app
# Unlike an ARG instruction, ENV values are always persisted in the built image
ENV DEFAULT_USER ${DEFAULT_USER}

ARG DEFAULT_USER_UID=1000
ENV DEFAULT_USER_UID ${DEFAULT_USER_UID}

ARG DEFAULT_USER_GID=1000
ENV DEFAULT_USER_GID ${DEFAULT_USER_GID}

# Default directory for application deployment
# Location of the folder in the container, path of the folder inside the container
ARG REMOTE_SRC=/var/www/app/
ENV REMOTE_SRC $REMOTE_SRC

# = /usr/local/etc/php || (./configure --with-config-file-path="$PHP_INI_DIR")
ENV PHP_INI_DIR ${PHP_INI_DIR:-/usr/local/etc/php}
# = /usr/local/etc/php/conf.d || (./configure --with-config-file-scan-dir="$PHP_INI_DIR/conf.d")
ENV PHP_INI_SCAN_DIR ${PHP_INI_DIR}/conf.d
# = /usr/local/etc/php-fpm.d || Pool Definitions (docker.conf | www.conf | zz-docker.conf)
ENV PHP_FPM_POOL_DIR ${PHP_INI_DIR}-fpm.d
# Path logs PHP/PHP-FPM
ENV PHP_LOG_PREFIX=/usr/local/var/log/php

####
## PHP
####

## AMQP EXT
# https://github.com/pdezwart/php-amqp
ARG INSTALL_PHP_AMQP=false
ENV PHP_AMQP_VERSION 1.9.4

## SWOOLE
# Event-driven asynchronous and concurrent networking engine with high performance for PHP.
# https://github.com/swoole/swoole-src
ARG INSTALL_PHP_SWOOLE=false
ENV PHP_SWOOLE_VERSION 4.4.5

# Install the PHP EXTENSIONS
RUN set -eux; \
        \
        echo "---> Preparing and Installing PHP"; \
        \
        # Print the list of manually installed packages
        savedAptMark="$(apt-mark showmanual)"; \
        \
        apt-get update; \
        # Dependencies required for PHP EXTENSIONS
        apt-get install --no-install-recommends -y \
                # for GD extension
                libjpeg-dev \
                libpng-dev \
                libwebp-dev \
                # for intl extension
                icu-devtools \
                libicu-dev \
                # for soap extension
                libxml2-dev \
                # for amqp extension
                librabbitmq-dev \
                # for gmp extension
                libgmp-dev \
                # for swoole extension
                libssl-dev \
                libnghttp2-dev \
                libhiredis-dev \
                # for zip extension
                libzip-dev \
                zlib1g-dev \
        ; \
        \
        docker-php-ext-configure gd \
                --with-gd \
                --with-jpeg-dir=/usr/include/ \
                --with-png-dir=/usr/include/ \
                --with-webp-dir=/usr/include/ \
        ; \
        \
        docker-php-ext-configure zip --with-libzip; \
        docker-php-ext-configure mysqli --with-mysqli=mysqlnd; \
        docker-php-ext-configure pdo_mysql --with-pdo-mysql=mysqlnd; \
        docker-php-ext-install -j $(nproc) \
                gd \
                bcmath \
                gmp \
                intl \
                pcntl \
                mysqli \
                pdo_mysql \
                soap \
                sockets \
                opcache \
                zip \
        ; \
        \
        # Communicate with any AMQP compliant server
        if [ $INSTALL_PHP_AMQP = true ]; then \
                pecl install amqp-${PHP_AMQP_VERSION}; \
                docker-php-ext-enable amqp; \
        fi; \
        \
        if [ $INSTALL_PHP_SWOOLE = true ]; then \
                # enable sockets supports? [no] : yes
                # enable openssl support? [no] : yes
                # enable http2 support? [no] : yes
                # enable mysqlnd support? [no] : yes
                # enable postgresql coroutine client support? [no] : no
                printf "yes \n yes \n yes \n yes \n no \n" | pecl install swoole-${PHP_SWOOLE_VERSION}; \
                docker-php-ext-enable swoole; \
        fi; \
        \
        echo "---> Cleaning up"; \
        \
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
        apt-mark auto '.*' > /dev/null; \
        apt-mark manual $savedAptMark; \
        ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
                | awk '/=>/ { print $3 }' \
                | sort -u \
                | xargs -r dpkg-query -S \
                | cut -d: -f1 \
                | sort -u \
                | xargs -rt apt-mark manual; \
        \
        apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
        rm -rf /var/lib/apt/lists/*; \
        rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin; \
        \
        php --version; \
        \
        # https://github.com/docker-library/php/issues/443
        pecl update-channels; \
        rm -rf /tmp/pear ~/.pearrc

####
## SUPPORT PACKAGES
####

RUN set -ex \
        && apt-get update \
        && apt-get install --no-install-recommends -y \
                sudo \
                git \
                apt-transport-https \
                gnupg \
                openssh-client \
                autoconf \
                pkg-config \
                libssl-dev \
                wget \
                unzip \
        && apt-get purge -y --auto-remove && rm -rf /var/lib/apt/lists/* \
        && rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin

####
## NEW USER
####

RUN set -ex \
        && echo "---> Adding user to IMAGE" \
        && addgroup --system --gid ${DEFAULT_USER_GID} ${DEFAULT_USER} \
        && adduser --system --disabled-password -uid ${DEFAULT_USER_UID} -gid ${DEFAULT_USER_GID} --force-badname ${DEFAULT_USER} \
        && echo "${DEFAULT_USER} ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers

########
## MONGODB
# https://docs.mongodb.com/php-library/current
# https://github.com/mongodb/mongo-php-library && composer require mongodb/mongodb
########

ARG INSTALL_PHP_MONGO=false
ENV PHP_MONGO_VERSION 1.7.3
RUN if [ $INSTALL_PHP_MONGO = true ]; then \
            pecl install mongodb-${PHP_MONGO_VERSION} \
            && docker-php-ext-enable mongodb \
    ;fi

########
## IGBINARY
# Igbinary is a drop in replacement for the standard php serializer.
# https://github.com/igbinary/igbinary
########

ARG INSTALL_PHP_IGBINARY=true
ENV PHP_IGBINARY_VERSION 3.0.1
RUN if [ $INSTALL_PHP_IGBINARY = true ]; then \
            pecl install igbinary-${PHP_IGBINARY_VERSION} \
            && docker-php-ext-enable igbinary \
    ;fi

########
## LZF
# This package handles LZF de/compression.
# http://php.net/lzf
########

ARG INSTALL_PHP_LZF=true
ENV PHP_LZF_VERSION 1.6.7
RUN if [ $INSTALL_PHP_LZF = true ]; then \
           pecl install lzf-${PHP_LZF_VERSION} \
            && docker-php-ext-enable lzf \
    ;fi

########
## MESSAGEPACK
# MessagePack is an efficient binary serialization format
# https://msgpack.org/
########

ARG INSTALL_PHP_MESSAGEPACK=true
ENV PHP_MESSAGEPACK_VERSION 2.0.3
RUN if [ $INSTALL_PHP_MESSAGEPACK = true ]; then \
            pecl install msgpack-${PHP_MESSAGEPACK_VERSION} \
            && docker-php-ext-enable msgpack \
    ;fi

########
## REDIS
# https://github.com/phpredis/phpredis
########

ARG INSTALL_PHP_REDIS=true
ENV PHP_REDIS_VERSION 5.0.2
RUN if [ $INSTALL_PHP_REDIS = true ]; then \
            # /configure --with-php-config=/usr/local/bin/php-config \
            #            --enable-redis-igbinary=yes \
            #            --enable-redis-lzf=yes
            printf "yes \n yes \n" | pecl install -o -f redis-${PHP_REDIS_VERSION} \
            && docker-php-ext-enable redis \
    ;fi

########
## DATA STRUCTURES (DS)
# Data Structures (https://medium.com/p/9dda7af674cd)
# https://github.com/php-ds/extension
########

ARG INSTALL_PHP_DS=true
ENV PHP_DS_VERSION 1.2.9
RUN if [ $INSTALL_PHP_DS = true ]; then \
            pecl install ds-${PHP_DS_VERSION} && \
            docker-php-ext-enable ds \
    ;fi

########
## SQLSRV + PDO_SQLSRV
# Microsoft Drivers for PHP for SQL Server (SQLSRV + PDO_SQLSRV)
# @see https://docs.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server#debian-8-and-9
########

ARG INSTALL_PHP_SQLSRV=false
ENV PHP_SQLSRV_VERSION 5.6.1

RUN set -eux; \
        \
        if [ $INSTALL_PHP_SQLSRV = true ]; then \
                \
                # Installing the Microsoft ODBC Driver for SQL Server on Linux (DEBIAN)
                curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -; \
                curl https://packages.microsoft.com/config/debian/9/prod.list | tee /etc/apt/sources.list.d/mssql-release.list; \
                apt-get update; \
                \
                ACCEPT_EULA=Y apt-get install msodbcsql17 --no-install-recommends -y; \
                \
                # @see https://stackoverflow.com/questions/15447386/sql-h-header-file-missing-though-unixodbc-is-installed
                apt-get install unixodbc-dev --no-install-recommends -y; \
                \
                ## SQLSRV + PDO_SQLSRV
                pecl install sqlsrv-${PHP_SQLSRV_VERSION} pdo_sqlsrv-${PHP_SQLSRV_VERSION}; \
                \
                docker-php-ext-enable sqlsrv pdo_sqlsrv; \
                \
                apt-get purge -y --auto-remove && rm -rf /var/lib/apt/lists/*; \
                rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin; \
        fi;

#####
## XDEBUG
#####

ARG INSTALL_PHP_XDEBUG=true
ENV PHP_XDEBUG_VERSION 2.7.2
RUN if [ $INSTALL_PHP_XDEBUG = true ]; then \
            yes | pecl install xdebug-$PHP_XDEBUG_VERSION && \
            docker-php-ext-enable xdebug \
    ;fi

###
## [FD]
## A simple, fast and user-friendly alternative to 'find'
###

ENV DEFAULT_PARAMETERS_FD -j $(nproc) --hidden --no-ignore --ignore-case

RUN set -ex \
        && echo "---> Adding [FD]" \
        && wget -O /tmp/fd.deb $(curl -s https://api.github.com/repos/sharkdp/fd/releases/latest | grep -Po '"browser_download_url":\s*"\K[^"]+/fd_.*_amd64.deb(?=")') \
        && dpkg -i /tmp/fd.deb \
        && rm /tmp/fd.deb \
        && which fd; fd --version

###
## [EXA]
## Replacement for 'ls' written in Rust. https://the.exa.website/
###

RUN set -ex \
        && echo "---> Adding [EXA]" \
        && wget -O /tmp/exa.zip $(curl -s https://api.github.com/repos/ogham/exa/releases/latest | grep -Po '"browser_download_url":\s*"\K[^"]+/exa-linux-x86_64-.*.zip(?=")') \
        && unzip /tmp/exa.zip -d /usr/local/bin/ \
        && mv /usr/local/bin/exa-linux-x86_64 /usr/local/bin/exa \
        && rm /tmp/exa.zip \
        && which exa; exa --version

###
## php.ini PRODUCTION
###

RUN set -ex \
        && echo "---> Move PHP.INI(PRODUCTION)" \
        && rm ${PHP_INI_DIR}/php.ini-development \
        && mv ${PHP_INI_DIR}/php.ini-production ${PHP_INI_DIR}/php.ini

###
## Verify PHP
###

RUN set -ex \
        && /usr/local/sbin/php-fpm --test \
        && PHP_ERROR="$( php -v 2>&1 1>/dev/null )" \
        && if [ -n "$PHP_ERROR" ]; then echo "$PHP_ERROR"; false; fi \
        && php -m; php -v; php --ini

###
## PERMISSION
###

RUN set -ex \
        && echo "---> Changing permissions" \
        && mkdir -p $REMOTE_SRC \
        && chown -R $DEFAULT_USER:$DEFAULT_USER /usr/local/lib/php \
                                                /usr/local/var/log \
                                                /usr/local/var/run \
                                                /usr/local/etc \
                                                /var/www \
                                                /home/${DEFAULT_USER}
        # && fd . /var/www $DEFAULT_PARAMETERS_FD --exec chown $DEFAULT_USER:$DEFAULT_USER {} \; \
        # && fd . /usr/local/lib/php $DEFAULT_PARAMETERS_FD --exec chown $DEFAULT_USER:$DEFAULT_USER {} \; \
        # && fd . /home/$DEFAULT_USER $DEFAULT_PARAMETERS_FD --exec chown -R $DEFAULT_USER:$DEFAULT_USER /home/$DEFAULT_USER {} \;

###
## Define the running USER
###
USER $DEFAULT_USER

###
## COMPOSER
###

RUN set -ex \
        && echo "---> COMPOSER" \
        && COMPOSER_HOME="/home/${DEFAULT_USER}/.composer/" \
        && curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer \
        && composer global require hirak/prestissimo:"^0.3" --ansi \
        && composer global install --prefer-dist --no-dev --no-suggest --optimize-autoloader --ansi \
        && composer clear-cache

###
## PHPUnit
###

RUN set -ex \
        && echo "---> PHPUNIT" \
        && wget https://phar.phpunit.de/phpunit.phar \
        && chmod +x phpunit.phar \
        && sudo mv phpunit.phar /usr/local/bin/phpunit \
        && command -v phpunit

# Application directory
# Sets the working directory for any RUN, CMD, ENTRYPOINT, COPY and ADD instructions that follow it in the Dockerfile.
WORKDIR $REMOTE_SRC

# Environment variables
# Default: /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV PATH="$PATH:/home/${DEFAULT_USER}/.composer/vendor/bin"

# vim:set ft=dockerfile:
