#!/usr/bin/env bash

set -e # Exit immediately if a command exits with a non-zero status.

## Keep PHP-FPM running
## First arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
    set -- php-fpm "$@"
fi

###
## Log to stdout/stderr
###
log() {
    log_lvl="${1}"
    log_msg="${2}"

    log_clr_ok="\033[0;32m"
    log_clr_info="\033[0;34m"
    log_clr_warn="\033[0;33m"
    log_clr_err="\033[0;31m"
    log_clr_rst="\033[0m"

    if [ "${log_lvl}" = "ok" ]; then
        printf "${log_clr_ok}[OK]   %s${log_clr_rst}\n" "${log_msg}"
    elif [ "${log_lvl}" = "info" ]; then
        printf "${log_clr_info}[INFO] %s${log_clr_rst}\n" "${log_msg}"
    elif [ "${log_lvl}" = "warn" ]; then
        printf "${log_clr_warn}[WARN] %s${log_clr_rst}\n" "${log_msg}" 1>&2 # stdout -> stderr
    elif [ "${log_lvl}" = "err" ]; then
        printf "${log_clr_err}[ERR]  %s${log_clr_rst}\n" "${log_msg}" 1>&2 # stdout -> stderr
    else
        printf "${log_clr_err}[???]  %s${log_clr_rst}\n" "${log_msg}" 1>&2 # stdout -> stderr
    fi

    unset -v log_lvl
    unset -v log_msg
    unset -v log_clr_ok
    unset -v log_clr_info
    unset -v log_clr_warn
    unset -v log_clr_err
    unset -v log_clr_rst
}

###
## Wrapper for run_run command
###
run() {
    run_cmd="${1}"

    run_clr_red="\033[0;31m"
    run_clr_green="\033[0;32m"
    run_clr_reset="\033[0m"

    printf "${run_clr_red}%s \$ ${run_clr_green}${run_cmd}${run_clr_reset}\n" "$( whoami )"

    /bin/sh -c "LANG=C LC_ALL=C ${run_cmd}"

    unset -v run_cmd
    unset -v run_clr_red
    unset -v run_clr_green
    unset -v run_clr_reset
}

###
## Check the connection to database
###
check_database_connection() {

    log "info" "Attempting to connect to database ..."

    case "${DB_DRIVER}" in
        mysql)
            prog="mysqladmin -h ${DB_HOST} -u ${DB_USERNAME} ${DB_PASSWORD:+-p$DB_PASSWORD} -P ${DB_PORT} status"
            ;;
        pgsql)
            prog="/usr/bin/pg_isready"
            prog="${prog} -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USERNAME} -d ${DB_DATABASE} -t 1"
            ;;
        sqlite)
            prog="touch ${REMOTE_SRC}/database/database.sqlite"
    esac

    timeout=60

    while ! ${prog} >/dev/null 2>&1
    do
        timeout=$(( timeout - 1 ))
        if [[ "$timeout" -eq 0 ]]; then
            echo
            log "err" "Could not connect to database server! Aborting..."
            exit 1
        fi
        echo -n "."
        sleep 1
    done
    echo
}

###
## Check connection to MySQL database
###
check_db_init_mysql() {
    table=sessions
    if [[ "$(mysql -N -s -h "${DB_HOST}" -u "${DB_USERNAME}" "${DB_PASSWORD:+-p$DB_PASSWORD}" "${DB_DATABASE}" -P "${DB_PORT}" -e \
        "select count(*) from information_schema.tables where \
            table_schema='${DB_DATABASE}' and table_name='${DB_PREFIX}${table}';")" -eq 1 ]]; then
        log "info" "Table ${DB_PREFIX}${table} exists! ..."
    else
        log "warn" "Table ${DB_PREFIX}${table} does not exist! ..."
    fi
}

# Default settings for PHP-FPM
configure_php_fpm() {
    log "info" "Starting PHP-FPM configurations"

    sed -i "/user = .*/c\user = ${DEFAULT_USER}" ${PHP_FPM_POOL_DIR}/www.conf
    sed -i "/^group = .*/c\group = ${DEFAULT_USER}" ${PHP_FPM_POOL_DIR}/www.conf
    sed -i "/listen.owner = .*/c\listen.owner = ${DEFAULT_USER}" ${PHP_FPM_POOL_DIR}/www.conf
    sed -i "/listen.group = .*/c\listen.group = ${DEFAULT_USER}" ${PHP_FPM_POOL_DIR}/www.conf
    sed -i "/listen = .*/c\listen = [::]:9000" ${PHP_FPM_POOL_DIR}/www.conf
    sed -i "/pid = .*/c\;pid = run/php-fpm.pid" ${PHP_INI_DIR}-fpm.conf
    sed -i "/daemonize = .*/c\daemonize = no" ${PHP_INI_DIR}-fpm.conf

    # sed -i "/access.log = .*/c\access.log = /proc/self/fd/2" ${PHP_FPM_POOL_DIR}/www.conf
    # sed -i "/slowlog = .*/c\slowlog = /proc/self/fd/2" ${PHP_FPM_POOL_DIR}/www.conf
    # sed -i "/error_log = .*/c\error_log = /proc/self/fd/2" ${PHP_INI_DIR}-fpm.conf
    # sed -i "/;php_admin_value[error_log] = .*/c\php_admin_value[error_log] = /proc/self/fd/2" ${PHP_FPM_POOL_DIR}/www.conf

    sed -i "/;clear_env = .*/c\clear_env = no" ${PHP_FPM_POOL_DIR}/www.conf
    sed -i "/;catch_workers_output = .*/c\catch_workers_output = yes" ${PHP_FPM_POOL_DIR}/www.conf

    if [ "$PROJECT_ENVIRONMENT" == "development" ]; then
        log "info" "php-fpm.conf/www.conf Configurations for Development"

        # sed -i \
        #     -e "/rlimit_files = .*/c\;rlimit_files = " \
        #     -e "/rlimit_core = .*/c\;rlimit_core = " \
        # ${PHP_INI_DIR}-fpm.conf

        # @see https://www.kinamo.be/en/support/faq/determining-the-correct-number-of-child-processes-for-php-fpm-on-nginx
        # @see https://gist.github.com/holmberd/44fa5c2555139a1a46e01434d3aaa512
        # @see https://serverpilot.io/docs/how-to-change-the-php-fpm-max_children-setting
        # @see https://www.edufukunari.com.br/how-to-solve-php-fpm-server-reached-max-children/
        # Determine system RAM and average pool size memory.
            # free -h
            # All fpm processes: ps -ylC php-fpm --sort:rss (The column RSS contains the average memory usage in kilobytes per process)
            # Average memory: ps --no-headers -o "rss,cmd" -C php-fpm | awk '{ sum+=$1 } END { printf ("%d%s\n", sum/NR/1024,"M") }'
            # All fpm processes memory: ps -eo size,pid,user,command --sort -size | awk '{ hr=$1/1024 ; printf("%13.2f Mb ",hr) } { for ( x=4 ; x<=NF ; x++ ) { printf("%s ",$x) } print "" }' | grep php-fpm

        sed -i \
            -e "/pm = .*/c\pm = static" \
            -e "/pm.max_children = .*/c\pm.max_children = 10" \
            -e "/pm.start_servers = .*/c\pm.start_servers = 4" \
            -e "/pm.min_spare_servers = .*/c\pm.min_spare_servers = 2" \
            -e "/pm.max_spare_servers = .*/c\pm.max_spare_servers = 6" \
            -e "/pm.max_requests = .*/c\pm.max_requests = 500" \
            -e "/rlimit_files = .*/c\;rlimit_files = " \
            -e "/rlimit_core = .*/c\;rlimit_core = " \
        ${PHP_FPM_POOL_DIR}/www.conf

        # sed -i \
        #         -e "/pm = .*/c\pm = dynamic" \
        #         -e "/pm.max_children = .*/c\pm.max_children = 25" \
        #         -e "/pm.start_servers = .*/c\pm.start_servers = 10" \
        #         -e "/pm.min_spare_servers = .*/c\pm.min_spare_servers = 5" \
        #         -e "/pm.max_spare_servers = .*/c\pm.max_spare_servers = 10" \
        #         -e "/pm.max_requests = .*/c\pm.max_requests = 1000" \
        #         -e "/rlimit_files = .*/c\rlimit_files = 131072" \
        #         -e "/rlimit_core = .*/c\rlimit_core = unlimited" \
        # ${PHP_FPM_POOL_DIR}/www.conf

        # { \
        #     echo '[global]'; \
        #     echo; \
        #     echo 'error_log = /proc/self/fd/2'; \
        #     echo; \
        #     echo 'daemonize = no'; \
        #     echo; \
        #     echo 'include=etc/php-fpm.d/*.conf'; \
        # } | tee ${PHP_INI_DIR}-fpm.conf # == /usr/local/etc/php-fpm.conf

        # { \
        #     echo '[www]'; \
        #     echo 'user = www-data'; \
        #     echo 'group = www-data'; \
        #     echo; \
        #     echo 'listen = 9000'; \
        #     echo; \
        #     echo 'pm = dynamic'; \
        #     echo 'pm.max_children = 5'; \
        #     echo 'pm.start_servers = 2'; \
        #     echo 'pm.min_spare_servers = 1'; \
        #     echo 'pm.max_spare_servers = 3'; \
        #     echo; \
        #     echo '; if we send this to /proc/self/fd/1, it never appears'; \
        #     echo 'access.log = /proc/self/fd/2'; \
        #     echo; \
        #     echo '; Ensure worker stdout and stderr are sent to the main error log.'; \
        #     echo 'catch_workers_output = yes'; \
        #     echo; \
        #     echo '; Clear environment in FPM workers'; \
        #     echo 'clear_env = no'; \
        # } > ${PHP_FPM_POOL_DIR}/www.conf # == /usr/local/etc/php-fpm.d/www.conf

        ## Change PHP.INI
        sed -i \
                -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" \
                -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 8M/g" \
                -e "s/post_max_size\s*=\s*2M/post_max_size = 8M/g" \
                -e "s/variables_order = \"GPCS\"/variables_order = \"EGPCS\"/g" \
            $PHP_INI_DIR/php.ini
    fi
}

####
## Laravel APP
####

if [ -z "$APP_ENV" ]; then
    log "err" 'A $APP_ENV environment is required to run this container'
    exit 1
fi

# If the application key is not set, your user sessions and other encrypted data will not be secure!
if [ -z "$APP_KEY" ]; then
    log "err" 'A $APP_KEY environment is required to run this container'
    log "info" "INFO: Use 'APP_KEY=$(php artisan key:generate --show --no-ansi)'"
    exit 1
fi

if [ "$(stat -c "%U:%G" $REMOTE_SRC)" != "$DEFAULT_USER:$DEFAULT_USER" ]; then
    log "info" "Creating $REMOTE_SRC and changing container user permission"

    mkdir -p $REMOTE_SRC
    sudo chown -R $DEFAULT_USER:$DEFAULT_USER $REMOTE_SRC
fi

configure_project_env() {

    log "info" "Configuring Laravel commands according to the project flow"

    # NGINX FastCGI Cache
    mkdir -p $REMOTE_SRC/storage/nginx/cache

    if [ ! -d "vendor" ]; then
        log "warn" "Composer vendor folder was not installed. Running $> composer install --prefer-dist --no-interaction --optimize-autoloader --no-dev"

        run "composer install --prefer-dist --no-interaction --optimize-autoloader --no-dev"
        run "composer dump-autoload --optimize"
        run "composer run-script post-root-package-install"
        # # do not run php artisan key:generate --ansi
        # run "composer run-script post-create-project-cmd"
        run "composer run-script post-autoload-dump"
    fi

    run "rm -rf ${REMOTE_SRC}public/storage"
    run "php artisan storage:link"

    if [[ $PROJECT_ENVIRONMENT == "production" ]]; then
        # Remove Xdebug in production
        run "rm ${PHP_INI_SCAN_DIR}/docker-php-ext-xdebug.ini"

        # PRODUCTION
        log "info" "Laravel - Cache - Production"

        # $> {config:cache} && {route:cache}
        # @see https://github.com/laravel/framework/blob/5.8/src/Illuminate/Foundation/Console/OptimizeCommand.php#L28
        run "php artisan optimize"
    fi

    if [ "$PROJECT_ENVIRONMENT" == "development" ]; then
        # Remove Opcache in development
        run "rm ${PHP_INI_SCAN_DIR}/docker-php-ext-opcache.ini"

        # DEVELOPMENT
        log "info" "Laravel - Clear all and permissions"

        # $> {view:clear} && {cache:clear} && {route:clear} && {config:clear} && {clear-compiled}
        # @see https://github.com/laravel/framework/blob/5.8/src/Illuminate/Foundation/Console/OptimizeClearCommand.php#L28
        run "php artisan optimize:clear"
    fi
}

configure_app_env() {

    log "info" "Setting APP ENV (.env)"

    if [[ "${DB_DRIVER}" = "sqlite" ]]; then
        DB_DATABASE=""
        DB_HOST=""
        DB_PORT=""
        DB_USERNAME=""
        DB_PASSWORD=""
    fi

    # Configure ENV file

    sed 's,{{APP_ENV}},'"${APP_ENV}"',g' -i $REMOTE_SRC/.env
    sed 's,{{APP_DEBUG}},'"${APP_DEBUG}"',g' -i $REMOTE_SRC/.env
    sed 's,{{APP_URL}},'"${APP_URL}"',g' -i $REMOTE_SRC/.env

    sed 's,{{DB_CONNECTION}},'"${DB_CONNECTION}"',g' -i $REMOTE_SRC/.env
    sed 's,{{DB_HOST}},'"${DB_HOST}"',g' -i $REMOTE_SRC/.env
    sed 's,{{DB_PORT}},'"${DB_PORT}"',g' -i $REMOTE_SRC/.env
    sed 's,{{DB_DATABASE}},'"${DB_DATABASE}"',g' -i $REMOTE_SRC/.env
    sed 's,{{DB_USERNAME}},'"${DB_USERNAME}"',g' -i $REMOTE_SRC/.env
    sed 's,{{DB_PASSWORD}},'"${DB_PASSWORD}"',g' -i $REMOTE_SRC/.env

    sed 's,{{BROADCAST_DRIVER}},'"${BROADCAST_DRIVER}"',g' -i $REMOTE_SRC/.env
    sed 's,{{CACHE_DRIVER}},'"${CACHE_DRIVER}"',g' -i $REMOTE_SRC/.env
    sed 's,{{QUEUE_CONNECTION}},'"${QUEUE_CONNECTION}"',g' -i $REMOTE_SRC/.env

    sed 's,{{SESSION_DRIVER}},'"${SESSION_DRIVER}"',g' -i $REMOTE_SRC/.env
    sed 's,{{SESSION_DOMAIN}},'"${SESSION_DOMAIN}"',g' -i $REMOTE_SRC/.env
    sed 's,{{SESSION_SECURE_COOKIE}},'"${SESSION_SECURE_COOKIE}"',g' -i $REMOTE_SRC/.env

    sed 's,{{REDIS_HOST}},'"${REDIS_HOST}"',g' -i $REMOTE_SRC/.env
    sed 's,{{REDIS_PORT}},'"${REDIS_PORT}"',g' -i $REMOTE_SRC/.env
    sed 's,{{REDIS_PASSWORD}},'"${REDIS_PASSWORD}"',g' -i $REMOTE_SRC/.env

    sed 's,{{MAIL_DRIVER}},'"${MAIL_DRIVER}"',g' -i $REMOTE_SRC/.env
    sed 's,{{MAIL_HOST}},'"${MAIL_HOST}"',g' -i $REMOTE_SRC/.env
    sed 's,{{MAIL_PORT}},'"${MAIL_PORT}"',g' -i $REMOTE_SRC/.env
    sed 's,{{MAIL_USERNAME}},'"${MAIL_USERNAME}"',g' -i $REMOTE_SRC/.env
    sed 's,{{MAIL_PASSWORD}},'"${MAIL_PASSWORD}"',g' -i $REMOTE_SRC/.env
    sed 's,{{MAIL_FROM_ADDRESS}},'"${MAIL_FROM_ADDRESS}"',g' -i $REMOTE_SRC/.env
    sed 's,{{MAIL_FROM_NAME}},'"${MAIL_FROM_NAME}"',g' -i $REMOTE_SRC/.env
    sed 's,{{MAIL_ENCRYPTION}},'"${MAIL_ENCRYPTION}"',g' -i $REMOTE_SRC/.env

    if [[ -z "${APP_KEY}" || "${APP_KEY}" = "null" ]]; then
        keygen="$(php artisan key:generate)"
        APP_KEY=$(echo "${keygen}" | grep -oP '(?<=\[).*(?=\])')
        log "err" "ERROR: Please set the 'APP_KEY=${APP_KEY}' environment variable at runtime or in docker-compose.yml and re-launch"
        exit 0
    fi

    sed "s,{{APP_KEY}},$APP_KEY,g" -i $REMOTE_SRC/.env

    # Remove empty lines
    sed '/^.*=""$/d'  -i $REMOTE_SRC/.env
}

migrate_db() {
    force=""
    if [[ "${FORCE_MIGRATION:-false}" == true ]]; then
        force="--force"
    fi
    php artisan migrate ${force}
}

seed_db() {
    php artisan db:seed
}

start_app() {
    configure_php_fpm
    configure_app_env
    configure_project_env
    # check_database_connection
    # check_db_init_mysql
    # migrate_db
    # seed_db
}

start_app

run "php --ini"
run "php -v"

log "ok" "[PHP-FPM] Init process complete; Ready for start up."

## Run the original command
exec "$@"
