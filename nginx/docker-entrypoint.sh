#!/bin/bash

set -e

echo

shopt -s dotglob
sudo chown -R ${USER_NAME}:${GROUP_NAME} \
        /var/run /var/run/ \
        /var/log/
shopt -u dotglob

printf "\n\033[32m--- [SERVER] Entrypoint NGINX --- \033[0m\n"

cp -R /usr/lib/nginx/modules .

# ================================================
# ================================================

export DNS_DOCKER_SERVER=$(cat /etc/resolv.conf | grep -i '^nameserver' | head -n1 | cut -d ' ' -f2)

for conf in $(find . -type f -not -path '*/\.*' -not -path "./servers/*" -regex '.*\.conf' | sort);
do
    envsubst '${DNS_DOCKER_SERVER}
              $HTTPS_PORT
              ${HTTP_PORT}' \
                < $conf | sponge $conf
done

for conf in $(find /home/${USER_NAME}/logrotate/ -type f | sort);
do
    envsubst '${USER_NAME}
              ${GROUP_NAME}' \
                < $conf | sponge $conf
done

find . -type f \
    ! -name "nginx.conf" \
    -not -path '*/\.*' \
    -not -path "./servers/*" \
    -not -path "./certs/*" \
    -exec chown ${USER_NAME}:${GROUP_NAME} {} \;

for VARIABLE_NAME in $(compgen -A variable | grep -E "_SERVICE$|_SRC$");
do
    if [[ "$VARIABLE_NAME" =~ _SRC$ ]]; then

        IS_LARAVEL_APP_VARIABLE_NAME="IS_${VARIABLE_NAME}_LARAVEL_APP"

        if [[ ${!IS_LARAVEL_APP_VARIABLE_NAME:-true} == true ]]; then
            mkdir -p "${!VARIABLE_NAME}/public"
            touch "${!VARIABLE_NAME}/public/index.php"
        fi

        if [[ ${FORCE_CHANGE_OWNERSHIP:-false} == true ]]; then
            printf "\n\033[33mCHOWN - Change User Ownership\033[0m\n\n"

            sudo chown -R $USER_NAME:$GROUP_NAME ${!VARIABLE_NAME}
        fi
    fi

    for conf in $(find /etc/nginx -type f -not -path '*/\.*' -regex '.*\.conf' | sort);
    do
        envsubst "$(printf '${%s} ' $VARIABLE_NAME)" < $conf | sponge $conf
    done
done

sed -i "/fastcgi_read_timeout.*/c\    fastcgi_read_timeout ${NGINX_FASTCGI_READ_TIMEOUT:-30s};" ./snippets/php-fpm.conf

if [[ "${ONLY_HTTP:-false}" == true ]]; then
    printf "\n\033[33m[SERVER] Only HTTP :80\033[0m\n"

    { \
        echo; \
        echo 'more_clear_headers Content-Security-Policy;'; \
        echo 'more_clear_headers Feature-Policy;'; \
    } | tee -a ./nginx.d/10-security-headers.conf > /dev/null

    # sed -i "/include snippets\/http-to-https-non-www.conf.*/d" ./nginx.conf
    # sed -i "/more_set_headers \"Content-Security-Policy.*/d" ./nginx.d/10-security-headers.conf

    for conf in $(find ./servers/ -type f -not -path '*/\.*' -regex '.*\.conf' | sort);
    do
        sed -i \
            -e "/include snippets\/ssl.*/d" \
            -e "/listen 443.*/c\    listen 80;" \
        \
        $conf
    done
fi

if [ ! -z "${CONTENT_SECURITY_POLICY:-""}" ]; then
    sed -i "/more_set_headers \"Content-Security-Policy:.*/c\more_set_headers \"Content-Security-Policy: ${CONTENT_SECURITY_POLICY}\";" ./nginx.d/10-security-headers.conf
fi

if [[ "${WITHOUT_SECURITY_HEADERS:-false}" == true ]]; then
    printf "\n\033[33m[SERVER] Without Security Headers\033[0m\n\n"

    rm --force ./nginx.d/10-security-headers.conf 2> /dev/null
fi

if [[ "${WITH_GEOIP2:-false}" == true ]]; then
    printf "\n\033[33m[SERVER] Configuring GeoIP2 Module NGINX\033[0m\n"

    if [ -z "$GEOIPUPDATE_ACCOUNT_ID" ] || [ -z  "$GEOIPUPDATE_LICENSE_KEY" ]; then
        printf "\n\033[31m::ERROR:: You must set the environment variables \$GEOIPUPDATE_ACCOUNT_ID and \$GEOIPUPDATE_LICENSE_KEY!\033[0m\n\n"
        exit 1
    fi

    configFile=/usr/local/etc/GeoIP.conf

    cat <<EOF > "$configFile"
AccountID $GEOIPUPDATE_ACCOUNT_ID
LicenseKey $GEOIPUPDATE_LICENSE_KEY
EditionIDs ${GEOIPUPDATE_EDITION_IDS:-GeoLite2-Country GeoLite2-City}
DatabaseDirectory /usr/local/share/GeoIP
RetryFor 0
EOF

    # At 03:00 | https://crontab.guru/#0_3_*_*_*
    crontab -l -u $USER_NAME | { cat; echo "0 3 * * * /home/${USER_NAME}/geoip2/cronjob $configFile >> /var/log/GeoIP.log 2>&1"; } | crontab -u $USER_NAME -

    if [[ "${RUN_GEOIPUPDATE_EXEC:-false}" == true ]]; then
        printf "\n\033[33m[SERVER] Running >_ geoipupdate\033[0m\n\n"

        /usr/local/bin/geoipupdate --config-file "$configFile" --verbose
    fi

    sudo chown -R ${USER_NAME}:${GROUP_NAME} /usr/local/share/GeoIP
else
    # Remove the lines between the two matches
    sed -i -e '/###BEGIN_GEOIP2$/,/###END_GEOIP2$/{/###BEGIN_GEOIP2$/!{/###END_GEOIP2$/!d;};}' ./nginx.conf

    # Removed all lines containing geoip2_data or allowed_country
    for conf in $(find /etc/nginx ! -name "nginx.conf" -type f -not -path '*/\.*' -regex '.*\.conf' -exec egrep -lir "(geoip2_data|allowed_country)" /dev/null {} \; | sort);
    do
        sed -i \
            -e "/geoip2_data/d" \
            -e "/allowed_country/,+2d" \
        \
        $conf

        # Remove the lines between the two matches
        sed -i -e '/###BEGIN_GEOIP2$/,/###END_GEOIP2$/{/###BEGIN_GEOIP2$/!{/###END_GEOIP2$/!d;};}' $conf
    done
fi

if ! grep -q "logrotate\/cronjob" /var/spool/cron/crontabs/$USER_NAME; then
    declare -p | grep -E 'GEOIPUPDATE_|APP_|USER_NAME|GROUP_NAME|HOSTNAME|HOME_USER|PATH' > /container.env
    # declare -p | grep -Ev 'BASHOPTS|BASH_VERSINFO|EUID|PPID|SHELLOPTS|UID' > /container.env

    # At 00:00
    # https://crontab.guru/#0_0_*_*_*
    crontab -l -u $USER_NAME | { cat; echo "0 0 * * * source /container.env; /home/${USER_NAME}/logrotate/cronjob >> /var/log/logrotate.log 2>&1"; } | crontab -u $USER_NAME -
fi

# CRON SERVICE
sudo /usr/sbin/crond -b -l 6 -L /var/log/cron.log > /dev/null 2>&1 < /dev/null

sudo chown -R ${USER_NAME}:${GROUP_NAME} /home/${USER_NAME} $(ls /etc/nginx -I certs -I servers)

# ================================================
# ================================================

# # Configuration reload
# # Start the new worker processes with a new configuration
# # Gracefully shutdown the old worker processes
# # https://docs.nginx.com/nginx/admin-guide/basic-functionality/runtime-control/
# kill -HUP `cat /var/run/nginx.pid`

# @see https://www.nginx.com/resources/wiki/start/topics/tutorials/commandline/

# Launch nginx
printf "\n"
printf '============================\n'
printf "\033[32m[SERVER] Launching NGINX ...\033[0m\n"
printf '============================\n\n'

exec "$@"
