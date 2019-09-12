# Image base, built from the root php folder of the docker folder
ARG PHP_BASE_IMAGE=app:base

#####
## PHP Dependencies
#####

FROM composer:1.8 as vendor

WORKDIR /app

# https://getcomposer.org/doc/03-cli.md#composer-home
ENV COMPOSER_HOME /composer

# Copy only the files needed to download dependencies to avoid redownloading them when our code changes
COPY composer.json composer.json
COPY composer.lock composer.lock

RUN set -ex \
        && composer global require hirak/prestissimo:"^0.3" --ansi \
        && composer global install --prefer-dist --no-dev --no-suggest --ansi \
        && composer config --list --global

# We need to copy our whole application so that we can generate the autoload file inside the vendor folder
# No copy unnecessary files
COPY app/ app/
COPY bootstrap/ bootstrap/
COPY config/ config/
COPY database/ database/
COPY routes/ routes/
COPY storage/framework storage/framework
COPY artisan artisan
COPY .env.example .env.example

# This will download project dependencies
RUN set -ex \
        && composer install \
            --ignore-platform-reqs \
            # --optimize-autoloader \
            --no-autoloader \
            --prefer-dist \
            --ansi \
            --no-dev \
            --no-scripts \
            --no-interaction

#####
## FRONTEND
#####

FROM node:11-alpine as frontend

WORKDIR /app

# COPY package-lock.json package-lock.json
COPY package.json webpack.mix.js ./
COPY resources/ resources/

ARG PROJECT_ENVIRONMENT

RUN set -ex \
        && npm install && npm run ${PROJECT_ENVIRONMENT}

#####
## APPLICATION
#####

FROM $PHP_BASE_IMAGE

# Add label for documentation
LABEL maintainer="Allyson Silva <support@allyson.tech>" \
      description="Final image for production and use of the application in Laravel" \
      version="prod"

# If an ARG instruction has a default value and if there is no value passed at build-time, the builder uses the default
ARG DOMAIN_APP
# Unlike an ARG instruction, ENV values are always persisted in the built image
ENV DOMAIN_APP ${DOMAIN_APP:-appxyz.dev}

# Application prefix path
ARG APP_PATH_PREFIX
ENV APP_PATH_PREFIX ${APP_PATH_PREFIX:-/var/www}

# Path docker base
ARG DOCKER_FOLDER_PATH=./docker
ENV DOCKER_FOLDER_PATH ${DOCKER_FOLDER_PATH:-./docker}

# Path docker APP folder
# Path Config/Dockerfile APP
ARG DOCKER_APP_PATH=${DOCKER_FOLDER_PATH}/app
ENV DOCKER_APP_PATH ${DOCKER_APP_PATH}

# Default directory for application deployment
# Location of the folder in the container, path of the folder inside the container
ENV REMOTE_SRC ${APP_PATH_PREFIX}/${DOMAIN_APP}/

# Local project folder
ENV LOCAL_APP_FOLDER ${LOCAL_APP_FOLDER:-./}

# If an ARG instruction has a default value and if there is no value passed at build-time, the builder uses the default
ARG PROJECT_ENVIRONMENT=production
# Unlike an ARG instruction, ENV values are always persisted in the built image
ENV PROJECT_ENVIRONMENT ${PROJECT_ENVIRONMENT:-production}

# Default APP_ENV
ARG APP_ENV=production
ENV APP_ENV ${APP_ENV:-production}

# Application directory
# Sets the working directory for any RUN, CMD, ENTRYPOINT, COPY and ADD instructions that follow it in the Dockerfile.
WORKDIR $REMOTE_SRC

# Define the running user
USER root

###
## SSH - GitHub
# Handling private packages
# @see https://getcomposer.org/doc/05-repositories.md#using-private-repositories
###
# COPY $DOCKER_APP_PATH/ssh/id_rsa /home/$DEFAULT_USER/.ssh/id_rsa
# COPY $DOCKER_APP_PATH/ssh/id_rsa.pub /home/$DEFAULT_USER/.ssh/id_rsa.pub

# RUN chmod 600 /home/$DEFAULT_USER/.ssh/* \
#         && ls -lah /home/$DEFAULT_USER/.ssh \
#         && touch /home/$DEFAULT_USER/.ssh/known_hosts

#####
## PHP CONFIGURATIONS
#####

## EXTENSIONS
COPY $DOCKER_APP_PATH/config/extensions/xdebug.ini ${PHP_INI_SCAN_DIR}/docker-php-ext-xdebug.ini
COPY $DOCKER_APP_PATH/config/extensions/opcache.ini ${PHP_INI_SCAN_DIR}/docker-php-ext-opcache.ini

# PHP-INI
COPY $DOCKER_APP_PATH/config/php.ini-$PROJECT_ENVIRONMENT.ini $PHP_INI_DIR/php.ini
# PHP-FPM
COPY $DOCKER_APP_PATH/config/fpm/php-fpm.conf ${PHP_INI_DIR}-fpm.conf
# PHP-FPM-POOL-WWW
COPY $DOCKER_APP_PATH/config/fpm/www.conf ${PHP_FPM_POOL_DIR}/www.conf

# Remove default files
RUN set -ex \
        && echo "---> Remove default files PHP-FPM" \
        \
        && rm ${PHP_INI_DIR}-fpm.conf.default \
        && rm ${PHP_FPM_POOL_DIR}/www.conf.default \
        && rm ${PHP_FPM_POOL_DIR}/docker.conf \
        && rm ${PHP_FPM_POOL_DIR}/zz-docker.conf \
        && rm -rf /tmp/pear ~/.pearrc

# Forward request and error logs to docker log collector
RUN set -ex \
        && mkdir -p $PHP_LOG_PREFIX \
        && mkdir -p /tmp/php /tmp/php/sessions /tmp/php/uploads \
        \
        && touch ${PHP_LOG_PREFIX}/php-fpm.access.log \
        && touch ${PHP_LOG_PREFIX}/php-fpm.errors.log \
        && touch ${PHP_LOG_PREFIX}/php-fpm.slow.log \
        && touch ${PHP_LOG_PREFIX}/php.errors.log \
        \
        && ln -sf /dev/stderr ${PHP_LOG_PREFIX}/php-fpm.access.log \
        && ln -sf /dev/stderr ${PHP_LOG_PREFIX}/php-fpm.errors.log

#####
## APP
#####

# Check if the path/folder of the $REMOTE_SRC variable does not exist
RUN     if [ ! -d "$REMOTE_SRC" ]; then \
                mkdir -p $REMOTE_SRC \
                && chown -R $DEFAULT_USER:$DEFAULT_USER $REMOTE_SRC \
        ;fi

### Files APP
### Copy our application
COPY --chown=app:app $LOCAL_APP_FOLDER $REMOTE_SRC

## Copy the downloaded dependencies from the {vendor} stage
COPY --from=vendor /app/vendor/ ./vendor/
COPY --from=vendor /app/composer.json ./composer.json
COPY --from=vendor /app/composer.lock ./composer.lock
COPY --from=vendor /app/bootstrap/ ./bootstrap/
COPY --from=vendor /app/config/ ./config/
COPY --from=vendor /app/routes/ ./routes/
COPY --from=vendor /app/storage/framework ./storage/framework

## Copy from {frontend} stage
COPY --from=frontend /app/public/ ./public/
COPY --from=frontend /app/public/mix-manifest.json ./public/mix-manifest.json

## MYSQL
COPY --chown=app:app ${DOCKER_FOLDER_PATH}/mysql/ssl/client-key.pem ${REMOTE_SRC}/database/docker/mysql/ssl/client-key.pem
COPY --chown=app:app ${DOCKER_FOLDER_PATH}/mysql/ssl/client-cert.pem ${REMOTE_SRC}/database/docker/mysql/ssl/client-cert.pem
COPY --chown=app:app ${DOCKER_FOLDER_PATH}/mysql/ssl/ca.pem ${REMOTE_SRC}/database/docker/mysql/ssl/ca.pem

## MONGODB
COPY --chown=app:app ${DOCKER_FOLDER_PATH}/mongodb/ssl/rootCA.pem ${REMOTE_SRC}/database/docker/mongodb/ssl/rootCA.pem
COPY --chown=app:app ${DOCKER_FOLDER_PATH}/mongodb/ssl/client.pem ${REMOTE_SRC}/database/docker/mongodb/ssl/client.pem

# Remove folder docker
RUN     if [ -d ${DOCKER_FOLDER_PATH} ]; then \
            rm -rf ${DOCKER_FOLDER_PATH} \
        ;fi

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
        && chown -R $DEFAULT_USER:$DEFAULT_USER /usr/local/var/log $PHP_LOG_PREFIX \
                                                /usr/local/var/run \
                                                /usr/local/etc \
                                                /tmp/php \
        && fd . $APP_PATH_PREFIX $DEFAULT_PARAMETERS_FD --exec chown $DEFAULT_USER:$DEFAULT_USER {} \; \
        && fd . /usr/local/lib/php $DEFAULT_PARAMETERS_FD --exec chown $DEFAULT_USER:$DEFAULT_USER {} \; \
        && fd . /home/$DEFAULT_USER $DEFAULT_PARAMETERS_FD --exec chown $DEFAULT_USER:$DEFAULT_USER {} \;

## ENTRYPOINT
COPY $DOCKER_APP_PATH/docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Define the running USER
USER $DEFAULT_USER

RUN set -ex \
        && composer dump-autoload --optimize --classmap-authoritative --no-dev --ansi \
        && composer run-script post-root-package-install
        # # do not run php artisan key:generate --ansi
        # && composer run-script post-create-project-cmd

RUN set -ex && \
        # @see https://tighten.co/blog/app-key-and-you
        # do not change it unless you really want to:
        #    - invalidate sessions/cookies (user logout)
        #    - invalidate password reset tokens
        #    - invalidate signed urls
        # php artisan key:generate --force && \
        # php artisan migrate | php artisan migrate --seed && \
        # sudo find ${REMOTE_SRC} -type f -exec chmod 664 {} \; && \
        # sudo find ${REMOTE_SRC} -type d -exec chmod 775 {} \; && \
        DEFAULT_EXCLUDE_FD='--exclude public -E .git -E vendor' && \
        sudo fd . $DEFAULT_EXCLUDE_FD $DEFAULT_PARAMETERS_FD --type f --exec chmod 664 {} \; && \
        sudo fd . $DEFAULT_EXCLUDE_FD $DEFAULT_PARAMETERS_FD --type d --exec chmod 755 {} \; && \
        sudo chgrp -R $DEFAULT_USER storage bootstrap/cache && \
        sudo chmod -R ug+rwx storage bootstrap/cache && \
        # sudo chown -R $DEFAULT_USER:$DEFAULT_USER $REMOTE_SRC && \
        # sudo fd . $DEFAULT_PARAMETERS_FD --exec chown $DEFAULT_USER:$DEFAULT_USER {} \; && \
        exa --long --links --list-dirs --group --accessed --modified --header --git *

#############
## ENTRYPOINT
#############

ENTRYPOINT ["/entrypoint.sh"]

# PHP-FPM
EXPOSE 9000

CMD ["/usr/local/sbin/php-fpm", "-y", "/usr/local/etc/php-fpm.conf", "--nodaemonize"]

# vim:set ft=dockerfile:
