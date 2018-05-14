FROM php:7.2-fpm

# LABELS
LABEL maintainer="Allyson Silva <contato@allyson.tech>"
LABEL description="PHP"
LABEL version="1.0"

# Reset user to root to allow software install
# USER root

# If an ARG instruction has a default value and if there is no value passed at build-time, the builder uses the default.
ARG DEFAULT_USER=development
ARG DEFAULT_USER_UID=1000
# Unlike an ARG instruction, ENV values are always persisted in the built image.
ENV DEFAULT_USER ${DEFAULT_USER:-development}

ENV WORKDIR ${WORKDIR:-/var/www/app}

# Add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
# RUN groupadd -r ${DEFAULT_USER} && useradd -r -g ${DEFAULT_USER} ${DEFAULT_USER}

# Terminal
ENV TERM=xterm-256color \
    COLORTERM=truecolor

# Samples / Templates (Copy the content of samples to /home/USER inside the container)
COPY ./samples/bashrc /home/${DEFAULT_USER}/.bashrc
COPY ./samples/composer.json /home/${DEFAULT_USER}/.composer/

# Entrypoint
COPY ./docker-entrypoint.sh /scripts/entrypoint.sh
RUN chmod +x /scripts/entrypoint.sh

##################################
# Default php configurations values
##################################

# = /usr/local/etc/php (--with-config-file-path)
ENV PHP_INI_DIR ${PHP_INI_DIR:-/usr/local/etc/php}
# = /usr/local/etc/php/conf.d (--with-config-file-scan-dir)
ENV PHP_INI_SCAN_DIR ${PHP_INI_DIR}/conf.d
# Pool Definitions (docker.conf | www.conf | zz-docker.conf)
# /usr/local/etc/php-fpm.d/www.conf
ENV PHP_FPM_POOL_DIR ${PHP_INI_DIR}-fpm.d

###################################
# Package and dependency management
###################################

# PHP EXTRA BUILD dependencies
ENV PHP_EXTRA_BUILD_DEPS \
    sudo \
    gnupg \
    # @see https://github.com/alanxz/rabbitmq-c
    librabbitmq-dev \
    libgd-dev \
    libjpeg-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libwebp-dev \
    libxslt-dev \
    libgmp-dev \
    libtidy-dev \
    libxml2-dev \
    libssl-dev

# Extra packages, common
ENV EXTRA_PACKAGES \
    git \
    zip \
    unzip \
    wget \
    vim

#####
# RUN
#####

# Common installation parameters
ENV DEFAULT_PARAMETERS --no-install-recommends --no-install-suggests -y

# https://github.com/krallin/tini
# A tiny but valid `init` for containers
ENV TINI_VERSION v0.18.0

#####
# PHP
#####
RUN set -eux && \
    apt-get update && \
    apt-get install ${DEFAULT_PARAMETERS} ${PHP_EXTRA_BUILD_DEPS} ${EXTRA_PACKAGES} && \
        ########
        # Configure PHP extensions
        ########
            docker-php-ext-configure gd \
                --with-gd \
                --with-jpeg-dir=/usr/include/ \
                --with-png-dir=/usr/include/ \
                --with-webp-dir=/usr/include/ && \
            docker-php-ext-configure mysqli --with-mysqli=mysqlnd && \
            docker-php-ext-configure pdo_mysql --with-pdo-mysql=mysqlnd && \
            docker-php-ext-configure intl --enable-intl && \
        ########
        # Install PHP extensions
        ########
            docker-php-ext-install -j $(nproc) \
                calendar \
                exif \
                dom \
                tidy \
                tokenizer \
                mbstring \
                json \
                gettext \
                shmop \
                gd \
                bcmath \
                intl \
                gmp \
                pcntl \
                mysqli \
                pdo_mysql \
                soap \
                xsl \
                xml \
                zip \
                sockets \
                opcache && \
            # https://github.com/docker-library/php/issues/443
            pecl update-channels && \
            ## XDEBUG
            pecl install xdebug-2.6.0 && \
            docker-php-ext-enable xdebug && \
    # PHPUnit (Global) – The PHP Testing Framework
    echo "---> PHPUnit – The PHP Testing Framework" && \
    wget https://phar.phpunit.de/phpunit.phar -O /usr/local/bin/phpunit && \
    chmod +x /usr/local/bin/phpunit && \
    echo "---> Cleaning up" && \
    rm -rf /tmp/* ~/.pearrc && \
    apt-get clean -y && apt-get purge -y --autoremove && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /usr/share/man && \
    rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin && \
    echo "---> Remove files default PHP-FPM" && \
    rm ${PHP_INI_DIR}-fpm.conf.default && \
    rm ${PHP_FPM_POOL_DIR}/www.conf.default && \
    echo "---> Adding user to environment" && \
    adduser --disabled-password --gecos '' --force-badname ${DEFAULT_USER} -u ${DEFAULT_USER_UID} && \
    echo "${DEFAULT_USER} ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    echo "---> Changing permissions" && \
    mkdir -p ${WORKDIR} && \
    chown -R ${DEFAULT_USER}:${DEFAULT_USER} /var/www && \
    chown -R ${DEFAULT_USER}:${DEFAULT_USER} /usr/local/lib/php && \
    chown -R ${DEFAULT_USER}:${DEFAULT_USER} /home/${DEFAULT_USER} && \
    echo "---> TINI" && \
    wget -O /tini https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static && \
    chmod +x /tini

########
## AMQP
# https://github.com/pdezwart/php-amqp
########
ARG INSTALL_PHP_AMQP=false
ENV PHP_AMQP_VERSION 1.9.3
RUN if [ ${INSTALL_PHP_AMQP} = true ]; then \
    pecl install amqp-${PHP_AMQP_VERSION} && \
    docker-php-ext-enable amqp \
;fi

########
## MONGODB
# https://docs.mongodb.com/php-library/current
# https://github.com/mongodb/mongo-php-library && composer require mongodb/mongodb
########
ARG INSTALL_PHP_MONGO=false
ENV PHP_MONGO_VERSION 1.4.2
RUN if [ ${INSTALL_PHP_MONGO} = true ]; then \
    pecl install mongodb-${PHP_MONGO_VERSION} && \
    docker-php-ext-enable mongodb \
;fi

########
## IGBINARY
########
ARG INSTALL_PHP_IGBINARY=false
RUN if [ ${INSTALL_PHP_IGBINARY} = true ]; then \
    pecl install igbinary-devel && \
    docker-php-ext-enable igbinary \
;fi

########
## LZF
########
ARG INSTALL_PHP_LZF=false
RUN if [ ${INSTALL_PHP_LZF} = true ]; then \
    pecl install lzf && \
    docker-php-ext-enable lzf \
;fi

########
## REDIS
# https://github.com/phpredis/phpredis
########
ARG INSTALL_PHP_REDIS=false
ENV PHP_REDIS_VERSION 4.0.0
RUN if [ ${INSTALL_PHP_REDIS} = true ]; then \
    printf "yes \n no \n" | pecl install -o -f redis-${PHP_REDIS_VERSION} && \
    docker-php-ext-enable redis \
;fi

########
## SWOOLE
# https://github.com/swoole/swoole-src
########
ARG INSTALL_PHP_SWOOLE=false
ENV PHP_SWOOLE_VERSION 2.1.1
RUN if [ ${INSTALL_PHP_SWOOLE} = true ]; then \
    pecl install swoole-${PHP_SWOOLE_VERSION} && \
    docker-php-ext-enable swoole \
;fi

########
## DATA STRUCTURES (DS)
# Data Structures (https://medium.com/p/9dda7af674cd)
# https://github.com/php-ds/extension
########
ARG INSTALL_PHP_DS=false
ENV PHP_DS_VERSION 1.2.5
RUN if [ ${INSTALL_PHP_DS} = true ]; then \
    pecl install ds-${PHP_DS_VERSION} && \
    docker-php-ext-enable ds \
;fi

########
## PHP REF
# https://github.com/pinepain/php-ref
########
ARG INSTALL_PHP_REF=false
ENV PHP_REF_VERSION v0.6.0
RUN if [ ${INSTALL_PHP_REF} = true ]; then \
    FILE='/tmp/php-ref.tar.gz'; \
    FOLDER='/tmp/php-ref'; \
    curl -L -o $FILE "https://github.com/pinepain/php-ref/archive/${PHP_REF_VERSION}.tar.gz" && \
    mkdir -p $FOLDER && tar -C $FOLDER -zxvf $FILE --strip-components=1 && \
    docker-php-ext-configure $FOLDER --enable-ref && \
    docker-php-ext-install $FOLDER && \
    rm -rf /tmp/* \
;fi

########
## PHP MEMINFO
# https://github.com/BitOne/php-meminfo
########
ARG INSTALL_PHP_MEMINFO=false
ENV PHP_MEMINFO_VERSION v1.0.1
RUN if [ ${INSTALL_PHP_MEMINFO} = true ]; then \
    FILE='/tmp/php-meminfo.tar.gz'; \
    FOLDER='/tmp/php-meminfo'; \
    curl -L -o $FILE "https://github.com/BitOne/php-meminfo/archive/${PHP_MEMINFO_VERSION}.tar.gz" && \
    mkdir -p $FOLDER && tar -C $FOLDER -zxvf $FILE --strip 1 && \
    docker-php-ext-configure "$FOLDER/extension/php7/" --enable-meminfo && \
    docker-php-ext-install "$FOLDER/extension/php7/" && \
    rm -rf /tmp/* \
;fi

##############################
# SQLSRV + PDO_SQLSRV
# + ODBC Driver for SQL Server
##############################

# Microsoft Drivers for PHP for SQL Server (SQLSRV + PDO_SQLSRV)
# https://pecl.php.net/package/sqlsrv
# https://pecl.php.net/package/pdo_sqlsrv

ARG INSTALL_PHP_SQLSRV=false
ENV PHP_SQLSRV_VERSION 5.2.0
RUN if [ ${INSTALL_PHP_SQLSRV} = true ]; then \
    apt-get update -yqq && apt-get install ${DEFAULT_PARAMETERS} apt-transport-https && \
    # Installing the Microsoft ODBC Driver for SQL Server on Linux (DEBIAN)
    curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add - && \
    curl https://packages.microsoft.com/config/debian/9/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update -yqq && \
    # @see https://docs.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server#debian-8-and-9
    ACCEPT_EULA=Y apt-get install msodbcsql17 ${DEFAULT_PARAMETERS} && \
    # optional: for unixODBC development headers
    apt-get install unixodbc-dev ${DEFAULT_PARAMETERS} && \
    ## SQLSRV + PDO_SQLSRV
    pecl install sqlsrv-${PHP_SQLSRV_VERSION} pdo_sqlsrv-${PHP_SQLSRV_VERSION} && \
    docker-php-ext-enable sqlsrv pdo_sqlsrv \
;fi

################
# CONFIGURATIONS
################

# EXTENSIONS
COPY ./config/extensions/xdebug.ini ${PHP_INI_SCAN_DIR}/docker-php-ext-xdebug.ini
COPY ./config/extensions/opcache.ini ${PHP_INI_SCAN_DIR}/docker-php-ext-opcache.ini
# PHP-FPM
COPY ./config/fpm/php-fpm.conf ${PHP_INI_DIR}-fpm.conf
# PHP-FPM-POOL-WWW
COPY ./config/fpm/www.conf ${PHP_FPM_POOL_DIR}/www.conf
# PHP-INI
COPY ./config/php.ini-development.ini ${PHP_INI_DIR}/php.ini

# Verify PHP
RUN set -x && \
    /usr/local/sbin/php-fpm --test && \
    PHP_ERROR="$( php -v 2>&1 1>/dev/null )" && \
    if [ -n "${PHP_ERROR}" ]; then echo "${PHP_ERROR}"; false; fi

# Forward request and error logs to docker log collector
# RUN ln -sf /dev/stdout /var/log/php-fpm/access.log && \
#     ln -sf /dev/stderr /var/log/php-fpm/error.log

# Define the running user
USER ${DEFAULT_USER}

# COMPOSER
RUN set -x && \
    sudo apt-get update -yqq && \
    curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer && \
    composer global install --prefer-dist --no-dev --no-suggest --optimize-autoloader && \
    composer clear-cache

# Application directory
WORKDIR "$WORKDIR"

# Environment variables
ENV PATH="/home/${DEFAULT_USER}/.composer/vendor/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# ENTRYPOINT
ENTRYPOINT ["/tini", "--", "/scripts/entrypoint.sh"]

EXPOSE 9000 9099 8001 8002
CMD ["/usr/local/sbin/php-fpm", "-y", "/usr/local/etc/php-fpm.conf", "--allow-to-run-as-root", "--nodaemonize"]
