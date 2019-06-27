#!/bin/bash

set -ex

########
## QUEUE ENTRYPOINT
########

if [ -z "$APP_ENV" ]; then
    echo 'A $APP_ENV environment is required to run this container'
    exit 1
fi

# If the application key is not set, your user sessions and other encrypted data will not be secure!
if [ -z "$APP_KEY" ]; then
    echo 'A $APP_KEY environment is required to run this container'
    exit 1
fi

if [ "$(stat -c "%U:%G" $REMOTE_SRC)" != "$DEFAULT_USER:$DEFAULT_USER" ]; then
    echo "Creating $REMOTE_SRC and changing container user permission"

    mkdir -p $REMOTE_SRC
    sudo chown -R $DEFAULT_USER:$DEFAULT_USER $REMOTE_SRC
fi

# Increase the memory_limit
if [ ! -z "$PHP_MEM_LIMIT" ]; then
    sed -i "/memory_limit = .*/c\memory_limit = ${PHP_MEM_LIMIT}" $PHP_INI_DIR/php.ini
fi

# Increase the post_max_size
if [ ! -z "$PHP_POST_MAX_SIZE" ]; then
    sed -i "/post_max_size = .*/c\post_max_size = ${PHP_POST_MAX_SIZE}" $PHP_INI_DIR/php.ini
fi

# Increase the upload_max_filesize
if [ ! -z "$PHP_UPLOAD_MAX_FILESIZE" ]; then
    sed -i "/upload_max_filesize = .*/c\upload_max_filesize= ${PHP_UPLOAD_MAX_FILESIZE}" $PHP_INI_DIR/php.ini
fi

# Set Timezone
if [ ! -z "$TIMEZONE" ]; then
    cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
fi

if [ "$PROJECT_ENVIRONMENT" == "development" ]; then

    # Remove Opcache in development
    if [ -f ${PHP_INI_SCAN_DIR}/opcache.ini ]; then
        rm ${PHP_INI_SCAN_DIR}/opcache.ini
    fi

    if [ -f ${PHP_INI_SCAN_DIR}/docker-php-ext-opcache.ini ]; then
        rm ${PHP_INI_SCAN_DIR}/docker-php-ext-opcache.ini
    fi

    # DEVELOPMENT
    echo "Laravel - Clear all and permissions [Development]"
    echo

    php artisan clear-compiled
    php artisan view:clear
    php artisan config:clear
    php artisan route:clear
fi

if [[ $PROJECT_ENVIRONMENT == "production" ]]; then

    # Remove Xdebug in production
    if [ -f ${PHP_INI_SCAN_DIR}/xdebug.ini ]; then
        rm ${PHP_INI_SCAN_DIR}/xdebug.ini
    fi

    if [ -f ${PHP_INI_SCAN_DIR}/docker-php-ext-xdebug.ini ]; then
        rm ${PHP_INI_SCAN_DIR}/docker-php-ext-xdebug.ini
    fi

    # PRODUCTION
    echo "Laravel - Cache Optimization [Production]"
    echo

    php artisan route:cache
    # @see https://github.com/laravel/framework/issues/21727
    php artisan config:cache
fi

########
## SUPERVISOR
########

# @see http://supervisord.org/subprocess.html#subprocess-environment

echo
echo "Starting [SUPERVISOR]"
echo

if [[ $LARAVEL_QUEUE_MANAGER == "horizon" ]]; then

    if [[ $(php artisan horizon 2>&1 >/dev/null) ]]; then
        echo "Laravel - Horizon is already installed"
    else
        echo "Laravel/Composer - Install Horizon"

        composer require laravel/horizon
        # # php artisan queue:failed-table
        # # php artisan migrate
        php artisan horizon:install
    fi

    echo "Running the [HORIZON] Service..."
    echo

    # php artisan horizon:purge
    # php artisan horizon:terminate
    # php artisan queue:restart

    sudo sed -i \
                -e "s|{{DEFAULT_USER}}|$DEFAULT_USER|g" \
                -e "s|{{REMOTE_SRC}}|${REMOTE_SRC}|g" \
                -e "s|{{REDIS_HOST}}|$REDIS_HOST|g" \
                -e "s|{{REDIS_PASSWORD}}|$REDIS_PASSWORD|g" \
                -e "s|{{REDIS_PORT}}|$REDIS_PORT|g" \
                -e "s|{{REDIS_QUEUE}}|$REDIS_QUEUE|g" /etc/supervisor/conf.d/laravel-horizon.conf.tpl \
    \
    && sudo mv /etc/supervisor/conf.d/laravel-horizon.conf.tpl /etc/supervisor/conf.d/laravel-horizon.conf \
    # \
    # && sudo supervisorctl start laravel-horizon:*

fi

if [[ $LARAVEL_QUEUE_MANAGER == "worker" ]]; then

    echo "Running the [WORKER] Service..."
    echo

    sudo sed -i \
                -e "s|{{DEFAULT_USER}}|$DEFAULT_USER|g" \
                -e "s|{{REMOTE_SRC}}|${REMOTE_SRC}|g" \
                -e "s|{{REDIS_HOST}}|${REDIS_HOST:-redis}|g" \
                -e "s|{{REDIS_PASSWORD}}|$REDIS_PASSWORD|g" \
                -e "s|{{REDIS_PORT}}|${REDIS_PORT:-6379}|g" \
                -e "s|{{REDIS_QUEUE}}|${REDIS_QUEUE}|g" \
                -e "s|{{QUEUE_CONNECTION}}|${QUEUE_CONNECTION:-redis}|g" \
                -e "s|{{QUEUE_TIMEOUT}}|${QUEUE_TIMEOUT:-90}|g" \
                -e "s|{{QUEUE_MEMORY}}|${QUEUE_MEMORY:-128}|g" \
                -e "s|{{QUEUE_TRIES}}|${QUEUE_TRIES:-3}|g" \
                -e "s|{{QUEUE_SLEEP}}|${QUEUE_SLEEP:-5}|g" /etc/supervisor/conf.d/laravel-worker.conf.tpl \
    \
    && sudo mv /etc/supervisor/conf.d/laravel-worker.conf.tpl /etc/supervisor/conf.d/laravel-worker.conf \
    # \
    # && sudo supervisorctl start laravel-worker:*

fi

php -v

## Start supervisord and services
# sudo /usr/bin/supervisord --nodaemon --configuration /etc/supervisor/supervisord.conf

# sudo supervisorctl stop all
# sudo supervisorctl reread
# sudo supervisorctl update
# sudo supervisorctl start all

## Docker Command
exec "$@"
