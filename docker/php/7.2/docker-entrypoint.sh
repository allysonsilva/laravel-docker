#!/usr/bin/env bash
set -e
set -u

# Keep PHP running
# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
    set -- php-fpm "$@"
fi

###########
# Functions
###########

##
## Log to stdout/stderr
##
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
        printf "${log_clr_warn}[WARN] %s${log_clr_rst}\n" "${log_msg}" 1>&2	# stdout -> stderr
    elif [ "${log_lvl}" = "err" ]; then
        printf "${log_clr_err}[ERR]  %s${log_clr_rst}\n" "${log_msg}" 1>&2	# stdout -> stderr
    else
        printf "${log_clr_err}[???]  %s${log_clr_rst}\n" "${log_msg}" 1>&2	# stdout -> stderr
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
### Wrapper for run_run command
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

#########
# CONFIGS
#########

sudo sed -i "/user = .*/c\user = ${DEFAULT_USER}" /usr/local/etc/php-fpm.d/www.conf
sudo sed -i "/^group = .*/c\group = ${DEFAULT_USER}" /usr/local/etc/php-fpm.d/www.conf
sudo sed -i "/listen.owner = .*/c\listen.owner = ${DEFAULT_USER}" /usr/local/etc/php-fpm.d/www.conf
sudo sed -i "/listen.group = .*/c\listen.group = ${DEFAULT_USER}" /usr/local/etc/php-fpm.d/www.conf
sudo sed -i "/listen = .*/c\listen = [::]:9000" /usr/local/etc/php-fpm.d/www.conf
sudo sed -i "/;access.log = .*/c\access.log = /proc/self/fd/2" /usr/local/etc/php-fpm.d/www.conf
sudo sed -i "/;clear_env = .*/c\clear_env = no" /usr/local/etc/php-fpm.d/www.conf
sudo sed -i "/;catch_workers_output = .*/c\catch_workers_output = yes" /usr/local/etc/php-fpm.d/www.conf
sudo sed -i "/pid = .*/c\;pid = run/php72-fpm.pid" /usr/local/etc/php-fpm.conf
sudo sed -i "/;daemonize = .*/c\daemonize = yes" /usr/local/etc/php-fpm.conf
sudo sed -i "/error_log = .*/c\error_log = /proc/self/fd/2" /usr/local/etc/php-fpm.conf

###########################
# Setup permissions project
###########################

##################
# Composer CONFIGS
##################

export COMPOSER_ALLOW_SUPERUSER=1
export COMPOSER_HOME="/home/${DEFAULT_USER}/.composer"
export COMPOSER_CACHE_DIR="/home/${DEFAULT_USER}/cache"
export COMPOSER_ALLOW_XDEBUG=1
export COMPOSER_DISABLE_XDEBUG_WARN=1
export COMPOSER_PROCESS_TIMEOUT=1200

# Install Global PHP Development Libraries
# composer global install --prefer-dist --no-dev --no-suggest --optimize-autoloader
# composer clear-cache

###
### Startup
###
log "info" "Starting $(php-fpm -v 2>&1 | head -1)"
echo
log "ok" "PHP-FPM init process complete; ready for start up."

###
### Command
###
exec "$@"
