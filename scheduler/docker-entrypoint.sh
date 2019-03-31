#!/usr/bin/env bash

set -ex

#####
# SCHEDULER ENTRYPOINT
#####

# It must be used so that CRON can use the values of the environment variables
# The CRON service can not retrieve all environment variables, especially those defined in the docker-compose.yml file, when the line below is not set
printenv > /etc/environment

if [ -f ${PHP_INI_SCAN_DIR}/docker-php-ext-xdebug.ini ]; then
    rm ${PHP_INI_SCAN_DIR}/docker-php-ext-xdebug.ini
fi

if [ -f ${PHP_INI_SCAN_DIR}/docker-php-ext-swoole.ini ]; then
    rm ${PHP_INI_SCAN_DIR}/docker-php-ext-swoole.ini
fi

if [ -f ${PHP_INI_SCAN_DIR}/docker-php-ext-opcache.ini ]; then
    rm ${PHP_INI_SCAN_DIR}/docker-php-ext-opcache.ini
fi

if [ -z "$APP_ENV" ]; then
    echo 'A $APP_ENV environment is required to run this container'
    exit 1
fi

# If the application key is not set, your user sessions and other encrypted data will not be secure!
if [ -z "$APP_KEY" ]; then
    echo 'A $APP_KEY environment is required to run this container'
    exit 1
fi

echo
echo "Laravel - Clear all"
echo

# DEV
php artisan clear-compiled
php artisan view:clear
php artisan config:clear
php artisan route:clear

echo
echo "Laravel - Cache Optimization"
echo

# PROD
php artisan route:cache
# @see https://github.com/laravel/framework/issues/21727
php artisan config:cache

echo "Starting [CRON]"
echo

# Add to cron
sudo sed -i -e "s|{{USER}}|$DEFAULT_USER|g" \
         -i -e "s|{{REMOTE_SRC}}|${REMOTE_SRC}|g" /etc/cron.d/laravel-scheduler
# crontab -l | { cat; echo "* * * * * ${DEFAULT_USER} /usr/local/bin/php ${REMOTE_SRC}artisan schedule:run >> /dev/null 2>&1"; } | crontab -

# while [ true ]
# do
#     php ${REMOTE_SRC}/artisan schedule:run --verbose --no-interaction &
#     sleep 60
# done

# To check if the job is scheduled
# docker exec -ti <your-container-id> bash -c "crontab -l"
# To check if the cron service is running
# docker exec -ti <your-container-id> bash -c "pgrep cron"

php -v

## Docker Command
## Start CRON
exec "$@"
