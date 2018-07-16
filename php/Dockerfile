# docker build -t app:latest -f ./docker/php/Dockerfile \
#   --build-arg DEFAULT_ENVIRONMENT=production \
#   --build-arg INSTALL_PHP_XDEBUG=false \
#   .
FROM app:1.0

# Define the running user
USER root

# Local project folder
ENV LOCAL_SRC ${LOCAL_SRC:-./}

# Location of the folder in the container, path of the folder inside the container
ENV REMOTE_SRC ${REMOTE_SRC:-/var/www/app/}

# Path Docker Base
ENV DOCKER_PATH=./docker
ENV DOCKER_PHP_PATH=./docker/php

# If an ARG instruction has a default value and if there is no value passed at build-time, the builder uses the default.
ARG DEFAULT_ENVIRONMENT=development
# Unlike an ARG instruction, ENV values are always persisted in the built image.
ENV DEFAULT_ENVIRONMENT ${DEFAULT_ENVIRONMENT:-development}

# SSH ROOT
# COPY ${DOCKER_PATH}/ssh/id_rsa /root/.ssh/id_rsa
# COPY ${DOCKER_PATH}/ssh/id_rsa.pub /root/.ssh/id_rsa.pub

# SSH USER
COPY ${DOCKER_PATH}/ssh/id_rsa /home/${DEFAULT_USER}/.ssh/id_rsa
COPY ${DOCKER_PATH}/ssh/id_rsa.pub /home/${DEFAULT_USER}/.ssh/id_rsa.pub

RUN chmod 600 /home/${DEFAULT_USER}/.ssh/* \
    && ls -lah /home/${DEFAULT_USER}/.ssh \
    && touch /home/${DEFAULT_USER}/.ssh/known_hosts

#####
## XDEBUG
#####
ARG INSTALL_PHP_XDEBUG=true
ENV PHP_XDEBUG_VERSION 2.6.0
RUN if [ ${INSTALL_PHP_XDEBUG} = true ]; then \
    yes | pecl install xdebug-${PHP_XDEBUG_VERSION} && \
    docker-php-ext-enable xdebug \
;fi

# PHP-INI
COPY ${DOCKER_PHP_PATH}/config/php.ini-${DEFAULT_ENVIRONMENT}.ini ${PHP_INI_DIR}/php.ini

# Files APP
COPY --chown=app:app ${LOCAL_SRC} ${REMOTE_SRC}

RUN set -eux && \
    echo "---> Changing permissions" && \
    chown -R ${DEFAULT_USER}:${DEFAULT_USER} /var/www && \
    chown -R ${DEFAULT_USER}:${DEFAULT_USER} /usr/local/lib/php && \
    chown -R ${DEFAULT_USER}:${DEFAULT_USER} /home/${DEFAULT_USER}

# Define the running user
USER ${DEFAULT_USER}

RUN set -eux && \
    composer install --prefer-dist --no-interaction --optimize-autoloader && \
    # USE [--no-dev] IN (PRODUCTION)
    composer dump-autoload --optimize && \
    composer run-script post-root-package-install && \
    composer run-script post-create-project-cmd && \
    composer run-script post-autoload-dump

RUN set -eux && \
    php artisan clear-compiled && \
    # php artisan cache:clear && \
    php artisan view:clear && \
    php artisan route:clear && \
    php artisan config:clear && \
    php artisan storage:link && \
    php artisan key:generate --force && \
    # npm install && npm run prod && \
    # php artisan route:cache && \
    # php artisan config:cache && \
    # php artisan migrate | php artisan migrate --seed && \
    sudo find ${REMOTE_SRC} -type f -exec chmod 664 {} \; && \
    sudo find ${REMOTE_SRC} -type d -exec chmod 775 {} \; && \
    sudo chgrp -R ${DEFAULT_USER} storage bootstrap/cache && \
    sudo chmod -R ug+rwx storage bootstrap/cache && \
    sudo chown -R ${DEFAULT_USER}:${DEFAULT_USER} ${REMOTE_SRC}
