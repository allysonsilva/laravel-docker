#!/usr/bin/env bash

set -e

shopt -s dotglob
sudo chown -R ${USER_NAME}:${USER_NAME} \
        /home/${USER_NAME} \
        /usr/local/var/run \
        /var/run /var/run/ \
        /var/log \
        /tmp/php \
        $LOG_PATH
shopt -u dotglob

# Get the container IP
CONTAINER_IP=`ifconfig eth0 | grep 'inet addr' | cut -d: -f2 | awk '{print $1}'`
# Get the service name you specified in the docker-compose.yml by a reverse DNS lookup on the IP
SERVICE_NAME=`dig -x $CONTAINER_IP +short | cut -d'.' -f1`
PROJECT_NAME=`dig -x $CONTAINER_IP +short | cut -d'_' -f2`
# # The number of replicas is equal to the A records associated with the service name
# COUNT_SERVICES=`dig $PROJECT_NAME +short | wc -l`
# # Extract the replica number from the same PTR entry
# INDEX=`dig -x $CONTAINER_IP +short | sed 's/.*_\([0-9]*\)\..*/\1/'`
# # Hello I'm container 1 of 2
# echo "Hello I'm container $INDEX of $COUNT_SERVICES"

sudo find /usr/local/etc ! -name "php.ini" | xargs -I {} chown ${USER_NAME}:${USER_NAME} {}

# Convert to UPPERCASE
CONTAINER_ROLE=${CONTAINER_ROLE^^}

printf "\n\033[34m--- [$CONTAINER_ROLE] ENTRYPOINT APP --- \033[0m\n"

if [ "$1" = '/bin/bash' ]; then

    configure_php_ini() {
        sed -i \
            -e "s/memory_limit.*$/memory_limit = ${PHP_MEMORY_LIMIT:-128M}/g" \
            -e "s/max_execution_time.*$/max_execution_time = ${PHP_MAX_EXECUTION_TIME:-30}/g" \
            -e "s/max_input_time.*$/max_input_time = ${PHP_MAX_INPUT_TIME:-30}/g" \
            -e "s/post_max_size.*$/post_max_size = ${PHP_POST_MAX_SIZE:-8M}/g" \
            -e "s/upload_max_filesize.*$/upload_max_filesize = ${PHP_UPLOAD_MAX_FILESIZE:-2M}/g" \
        \
        $PHP_INI_DIR/php.ini
    }

    configure_phpfpm_child_processes() {
        pm=("$@")

        # ps -o pid,user,vsz,rss,comm,args
        sed -i \
            -e "/pm = .*/c\pm = ${PHPFPM_PM:-dynamic}" \
            -e "/^pm.max_children.*/c\pm.max_children = ${PHPFPM_MAX_CHILDREN:-${pm[0]}}" \
            -e "/^pm.start_servers.*/c\pm.start_servers = ${PHPFPM_START_SERVERS:-${pm[1]}}" \
            -e "/^pm.min_spare_servers.*/c\pm.min_spare_servers =  ${PHPFPM_MIN_SPARE_SERVERS:-${pm[2]}}" \
            -e "/^pm.max_spare_servers.*/c\pm.max_spare_servers = ${PHPFPM_MAX_SPARE_SERVERS:-${pm[3]}}" \
            -e "/pm.max_requests = .*/c\pm.max_requests = ${PHPFPM_MAX_REQUESTS:-1024}" \
            -e "/rlimit_files = .*/c\rlimit_files = ${PHPFPM_RLIMIT_FILES:-32768}" \
            -e "/rlimit_core = .*/c\rlimit_core = ${PHPFPM_RLIMIT_CORE:-unlimited}" \
        \
        ${PHP_FPM_POOL_DIR}/www.conf
    }

    install_composer_dependencies() {
        if [ ! -d "vendor" ] && [ -f "composer.json" ]; then
            printf "\n\033[33mComposer vendor folder was not installed. Running >_ composer install --prefer-dist --no-interaction --optimize-autoloader --ansi --no-dev\033[0m\n\n"

            composer install --prefer-dist --no-interaction --optimize-autoloader --ignore-platform-reqs --ansi --no-dev

            printf "\n\033[33mcomposer run-script post-root-package-install\033[0m\n\n"

            composer run-script post-root-package-install

            printf "\n\033[33mcomposer run-script post-autoload-dump\033[0m\n\n"

            composer run-script post-autoload-dump
        fi
    }

    if [ -z "$APP_ENV" ]; then
        printf "\n\033[31m[$CONTAINER_ROLE] A \$APP_ENV environment is required to run this container!\033[0m\n"
        exit 1
    fi

    # If the application key is not set, your user sessions and other encrypted data will not be secure!
    if [ -z "$APP_KEY" ]; then
        printf "\n\033[31m[$CONTAINER_ROLE] A \$APP_KEY environment is required to run this container!\033[0m\n"
        exit 1
    fi

    # $> {view:clear} && {cache:clear} && {route:clear} && {config:clear} && {clear-compiled}
    # @see https://github.com/laravel/framework/blob/8.x/src/Illuminate/Foundation/Console/OptimizeClearCommand.php#L28
    if [[ -d "vendor" && ${FORCE_CLEAR:-false} == true ]]; then
        printf "\n\033[33mLaravel - artisan view:clear + route:clear + config:clear + clear-compiled\033[0m\n\n"

        php artisan view:clear
        php artisan route:clear
        php artisan config:clear
        php artisan clear-compiled
    fi

    if [[ -d "vendor" && ${CACHE_CLEAR:-false} == true ]]; then
        printf "\n\033[33mLaravel - artisan cache:clear\033[0m\n\n"

        php artisan cache:clear 2>/dev/null || true
    fi

    if [[ -d "vendor" && ${FORCE_OPTIMIZE:-false} == true ]]; then
        printf "\n\033[33mLaravel Cache Optimization - artisan config:cache + route:cache + view:cache\033[0m\n\n"

        # $> {config:cache} && {route:cache}
        # @see https://github.com/laravel/framework/blob/8.x/src/Illuminate/Foundation/Console/OptimizeCommand.php#L28
        php artisan optimize || true
        php artisan view:cache || true
    fi

    if [[ -d "vendor" && ${FORCE_MIGRATE:-false} == true ]]; then
        printf "\n\033[33mLaravel - artisan migrate --force\033[0m\n\n"

        php artisan migrate --force || true
    fi

    if [[ ${FORCE_STORAGE_LINK:-false} == true ]]; then
        printf "\n\033[33mLaravel - artisan storage:link\033[0m\n\n"

        rm -rf ${REMOTE_SRC}/public/storage || true
        php artisan storage:link || true
    fi

    if [[ -n "$XDEBUG_ENABLED" && $XDEBUG_ENABLED == true ]]; then
        mkdir -p /tmp/php/xdebug >/dev/null 2>&1 || true

        # { \
        #     echo '[xdebug]'; \
        #     echo 'zend_extension=xdebug.so'; \
        #     echo; \
        #     echo 'xdebug.mode=debug'; \
        #     echo 'xdebug.idekey=VSCODE'; \
        #     echo "xdebug.client_host=${XDEBUG_CLIENT_HOST:-`/sbin/ip route|awk '/default/ { print $3 }'`}"
        # } | tee -a ${PHP_INI_SCAN_DIR}/zz-xdebug.ini > /dev/null

    else
        rm -f $PHP_LOG_PATH/php-xdebug.log >/dev/null 2>&1 || true

        rm -f ${PHP_INI_SCAN_DIR}/docker-php-ext-xdebug.ini >/dev/null 2>&1 || true
        rm -f ${PHP_INI_SCAN_DIR}/xdebug.ini >/dev/null 2>&1 || true
    fi

    if [[ ${OPCACHE_ENABLED:-true} == false ]]; then
        rm -f ${PHP_INI_SCAN_DIR}/docker-php-ext-opcache.ini >/dev/null 2>&1 || true
        rm -f ${PHP_INI_SCAN_DIR}/opcache.ini >/dev/null 2>&1 || true
    fi

    # Removing php-fpm configuration from logrotate and deleting php-fpm log files!
    if [ "$CONTAINER_ROLE" != "PHP-FPM" ]; then
        rm -f /home/$USER_NAME/logrotate/conf.d/php-fpm 2> /dev/null
        rm -rf ${PHP_INI_DIR}-fpm* >/dev/null 2>&1 || true

        rm -f $(php -r "echo(PHP_CONFIG_FILE_SCAN_DIR);")/newrelic.ini >/dev/null 2>&1 || true
        pkill -9 '^newrelic-daemon*' || true

        find ${PHP_LOG_PATH} -maxdepth 1 -name "php-fpm.*.log" -type f -print0 | xargs -0 rm -f 2> /dev/null
    fi

    # Run logrotate only in production!
    if [ "$APP_ENV" = "production" ]; then
        configure_php_ini

        for conf in $(find /home/${USER_NAME}/logrotate/ -type f | sort);
        do
            sed -i \
                -e "s|{{USER_NAME}}|$USER_NAME|g" \
                -e "s|{{REMOTE_SRC}}|${REMOTE_SRC}|g" $conf
        done

        if ! sudo grep -q "logrotate\/cronjob" /etc/crontabs/$USER_NAME; then
            declare -p | grep -Ev 'BASHOPTS|BASH_VERSINFO|EUID|PPID|SHELLOPTS|UID' > /home/${USER_NAME}/container.env

            # At minute 0
            # https://crontab.guru/every-hour
            sudo crontab -l -u $USER_NAME | { cat; echo "0 * * * * source /home/${USER_NAME}/container.env; /home/${USER_NAME}/logrotate/cronjob >> /var/log/logrotate.log 2>&1"; } | sudo crontab -u $USER_NAME -
        fi

        if [ "$CONTAINER_ROLE" != "SCHEDULER" ]; then
            printf "\n\033[33mRunning >_ sudo /usr/sbin/crond -b -l 6 -L /var/log/cron.log\033[0m\n"

            # CRON SERVICE
            sudo /usr/sbin/crond -b -l 6 -L /var/log/cron.log > /dev/null 2>&1 < /dev/null
        fi
    else
        rm -rf /home/$USER_NAME/logrotate/ 2> /dev/null

        # To remove a job(0 * * * * .../logrotate/cronjob) from crond:
        sudo crontab -u $USER_NAME -l | grep -v '/logrotate/cronjob' | sudo crontab -u $USER_NAME -
    fi

    install_composer_dependencies

    echo
    php -v
    echo
    php --ini

    if [[ $CONTAINER_ROLE == "PHP-FPM" ]]
    then

        sed -i \
            -e "/daemonize = .*/c\daemonize = no" \
            -e "/emergency_restart_threshold = .*/c\emergency_restart_threshold = ${PHPFPM_EMERGENCY_RESTART_THRESHOLD:-15}" \
            -e "/emergency_restart_interval = .*/c\emergency_restart_interval = ${PHPFPM_EMERGENCY_RESTART_INTERVAL:-1m}" \
            -e "/process_control_timeout = .*/c\process_control_timeout = ${PHPFPM_PROCESS_CONTROL_TIMEOUT:-20s}" \
        \
        ${PHP_INI_DIR}-fpm.conf

        sed -i \
            -e "/^user = .*/c\user = ${USER_NAME}" \
            -e "/^group = .*/c\group = ${USER_NAME}" \
            -e "/listen.owner = .*/c\listen.owner = ${USER_NAME}" \
            -e "/listen.group = .*/c\listen.group = ${USER_NAME}" \
            -e "/^listen = .*/c\listen = 9000" \
            -e "/^pm.status_path = .*/c\pm.status_path = /fpm-status-${SERVICE_NAME}" \
            -e "/^listen.allowed_clients = .*/c\;listen.allowed_clients =" \
            -e "/^request_terminate_timeout = .*/c\request_terminate_timeout = ${PHPFPM_REQUEST_TERMINATE_TIMEOUT:-30s}" \
            -e "/^request_slowlog_timeout = .*/c\request_slowlog_timeout = ${PHPFPM_REQUEST_SLOWLOG_TIMEOUT:-10s}" \
        \
        ${PHP_FPM_POOL_DIR}/www.conf

        printf "\n\033[34mRunning the APP/[PHP-FPM] Service ...\033[0m\n"

        if [ "$APP_ENV" = "production" ]
        then

            pmChilds=(40 15 10 25)

            { \
                echo; \
                echo 'php_flag[display_errors] = Off'; \
                echo 'php_admin_flag[log_errors] = On'; \
            } | tee -a ${PHP_FPM_POOL_DIR}/www.conf > /dev/null

            printf "\n\033[34m[PHP-FPM] APP Production ✅ ...\033[0m\n"

        else

            pmChilds=(12 6 4 8)

            sed -i \
                -e "/access.log = .*/c\access.log = /proc/self/fd/2" \
                -e "/slowlog = .*/c\slowlog = /proc/self/fd/2" \
            \
            ${PHP_FPM_POOL_DIR}/www.conf

            sed -i "/error_log = .*/c\error_log = /proc/self/fd/2" ${PHP_INI_DIR}-fpm.conf

            printf "\n\033[34m[PHP-FPM] APP Local/Dev ✅ ...\033[0m\n"

        fi

        configure_phpfpm_child_processes "${pmChilds[@]}"

        # If the user wants to enable new relic
        if [[ ${NEW_RELIC_ENABLED:-false} == true ]]; then

            {
                    printf "\n"
                    echo '; ========================='
                    echo '; ========================='
                    printf "\n"
            } >> $(php -r "echo(PHP_CONFIG_FILE_SCAN_DIR);")/newrelic.ini

            sed -i  -e "s/REPLACE_WITH_REAL_KEY/${NEW_RELIC_LICENSE_KEY}/" \
                    -e "s/newrelic.appname[[:space:]]=[[:space:]].*/newrelic.appname=\"${NEW_RELIC_APPNAME}\"/" \
                    -e s/\;newrelic.daemon.address.\*/newrelic.daemon.address="\"${NEW_RELIC_DAEMON_ADDRESS}\""/ \
                    -e 's/;newrelic.daemon.app_connect_timeout.*/newrelic.daemon.app_connect_timeout=25s/' \
                    -e 's/;newrelic.daemon.start_timeout.*/newrelic.daemon.start_timeout=15s/' \
                    -e "s/;newrelic.labels.*/newrelic.labels=\"${NEW_RELIC_LABELS}\"/" \
                    -e '$anewrelic.enabled=true' \
                    -e '$anewrelic.framework='\"${FRAMEWORK}\"'' \
                    -e '$anewrelic.process_host.display_name='"\"${NEW_RELIC_APPNAME} PHP-FPM\""'' \
                    -e '$anewrelic.distributed_tracing_enabled=true' \
                    -e '$anewrelic.daemon.utilization.detect_docker=true' \
                    $(php -r "echo(PHP_CONFIG_FILE_SCAN_DIR);")/newrelic.ini
                    # /usr/local/etc/php/conf.d/newrelic.ini
                    # newrelic.logfile = "/var/log/newrelic/php_agent.log"
                    # newrelic.daemon.logfile = "/var/log/newrelic/newrelic-daemon.log"
        else
            # sed -i  -e s/\;newrelic.enabled.\*/newrelic.enabled\ =\ false/ \
            #         -e s/\;newrelic.daemon.utilization.detect_docker.\*/newrelic.daemon.utilization.detect_docker\ =\ false/ \
            #         $(php -r "echo(PHP_CONFIG_FILE_SCAN_DIR);")/newrelic.ini
            rm -f $(php -r "echo(PHP_CONFIG_FILE_SCAN_DIR);")/newrelic.ini >/dev/null 2>&1 || true
            pkill -9 '^newrelic-daemon*' || true
        fi

        # Launch PHP-FPM
        printf "\n"
        printf '===========================\n'
        printf "\033[34m[APP] Launching PHP-FPM ...\033[0m\n"
        printf '===========================\n\n'

        exec /usr/local/sbin/php-fpm -y /usr/local/etc/php-fpm.conf --nodaemonize --force-stderr

    elif [[ $CONTAINER_ROLE == "QUEUE" ]]
    then

        if [[ $LARAVEL_QUEUE_MANAGER == "horizon" ]]; then

            printf "\n\033[34m[$CONTAINER_ROLE] Running the [HORIZON] Service ...\033[0m\n"

            fileHorizonTpl=/etc/supervisor/conf.d/laravel-horizon.conf.tpl

            if [ -f "$fileHorizonTpl" ]; then
                sudo sed -i \
                    -e "s|{{USER_NAME}}|$USER_NAME|g" \
                    -e "s|{{REMOTE_SRC}}|${REMOTE_SRC}|g" $fileHorizonTpl \
                \
                && sudo mv $fileHorizonTpl /etc/supervisor/conf.d/laravel-horizon.conf
            fi

            # # During your application's deployment process, you should instruct the Horizon process
            # # to terminate so that it will be restarted by your process monitor and receive your code changes:
            #
            # php artisan horizon:terminate

        elif [[ $LARAVEL_QUEUE_MANAGER == "worker" ]]; then

            printf "\n\033[34m[$CONTAINER_ROLE] Running the [WORKER] Service ...\033[0m\n"

            fileWorkerTpl=/etc/supervisor/conf.d/laravel-worker.conf.tpl

            if [ -f "$fileWorkerTpl" ]; then
                sudo sed -i \
                        -e "s|{{USER_NAME}}|$USER_NAME|g" \
                        -e "s|{{REMOTE_SRC}}|${REMOTE_SRC}|g" \
                        -e "s|{{REDIS_QUEUE}}|${REDIS_QUEUE:-default}|g" \
                        -e "s|{{QUEUE_CONNECTION}}|${QUEUE_CONNECTION:-redis}|g" \
                        -e "s|{{QUEUE_TIMEOUT}}|${QUEUE_TIMEOUT:-60}|g" \
                        -e "s|{{QUEUE_MEMORY}}|${QUEUE_MEMORY:-64}|g" \
                        -e "s|{{QUEUE_TRIES}}|${QUEUE_TRIES:-3}|g" \
                        -e "s|{{QUEUE_BACKOFF}}|${QUEUE_BACKOFF:-3}|g" \
                        -e "s|{{QUEUE_SLEEP}}|${QUEUE_SLEEP:-10}|g" ${fileWorkerTpl} \
                \
                && sudo mv $fileWorkerTpl /etc/supervisor/conf.d/laravel-worker.conf
            fi

        else
            printf "\n\033[31m[$CONTAINER_ROLE] Queue type could not be found. configure --env=\"\$LARAVEL_QUEUE_MANAGER=worker or horizon\" in command \$> docker run!\033[0m\n\n"
            exit 1
        fi

        printf "\n\033[34m[$CONTAINER_ROLE] Starting [SUPERVISOR] ... \033[0m\n\n"

        exec /usr/bin/supervisord --nodaemon --configuration /etc/supervisor/supervisord.conf

        # # Reload the daemon's configuration files
        # supervisorctl -c /etc/supervisor/supervisord.conf reread
        # # Reload config and add/remove as necessary
        # supervisorctl -c /etc/supervisor/supervisord.conf update
        # # Start all processes of the group "laravel-worker"
        # supervisorctl -c /etc/supervisor/supervisord.conf start laravel-worker:*

        # # Since queue workers are long-lived processes, they will not notice changes to your code without being restarted.
        # # So, the simplest way to deploy an application using queue workers is to restart the workers during your deployment process.
        # # You may gracefully restart all of the workers by issuing the queue:restart command:
        #
        # # This command will instruct all queue workers to gracefully exit after they finish processing their current job so that no existing jobs are lost.
        # php artisan queue:restart

    elif [[ $CONTAINER_ROLE == "SCHEDULER" ]]
    then

        if ! sudo grep -q "\/artisan schedule:run" /etc/crontabs/${USER_NAME}; then
            printf "\n\033[33mAdding >_ php artisan schedule:run >> /dev/null 2>&1 command to crond\033[0m\n"

            # https://crontab.guru/every-minute
            sudo crontab -l -u $USER_NAME | { cat; echo "* * * * * /usr/local/bin/php ${REMOTE_SRC}/artisan schedule:run --no-ansi >> ${REMOTE_SRC}/storage/logs/scheduler.log 2>&1"; } | sudo crontab -u $USER_NAME -
        fi

        # It must be used so that CRON can use the values of the environment variables
        # The CRON service can not retrieve all environment variables, especially those defined in the docker-compose.yml file, when the line below is not set
        printenv > /etc/environment

        sudo sed -i -e "s|{{REMOTE_SRC}}|${REMOTE_SRC}|g" /etc/crontabs/${USER_NAME}
        sudo sed -i -e "s|{{REMOTE_SRC}}|${REMOTE_SRC}|g" /var/spool/cron/crontabs/$USER_NAME

        printf "\n\033[34m[$CONTAINER_ROLE] Starting [CRON] Service ...\033[0m\n\n"

        exec /usr/sbin/crond -l 2 -f -L /var/log/cron.log

    else

        printf "\n\033[31m::ERROR:: Could not match the container role \"$CONTAINER_ROLE\"\033[0m\n\n"
        exit 1

    fi

fi

exec "$@"
