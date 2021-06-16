#!/bin/sh

set -e

GOACCESS_ORIGIN="--origin=https://goaccess.${DOMAIN}"

if [ ${HTTPS_PORT} -ne 443 ]; then
    GOACCESS_ORIGIN="${GOACCESS_ORIGIN}:${HTTPS_PORT}"
fi

yes | cp -rf goaccess.conf.tpl goaccess.conf

if [[ "${WITH_GEOIP2:-false}" == true ]]; then
    sed -i \
            -e "s/\"client_ip\": \"%h\"/&, %^, %^, %^/" \
            -e '/^#geoip-database.*/s/^#//' \
        \
        goaccess.conf
fi

printf "\n"
printf '======================\n'
printf "\033[31mLaunching GoAccess ...\033[0m\n"
printf '======================\n\n'

# @see https://bytes.fyi/real-time-goaccess-reports-with-nginx/
exec /bin/goaccess \
    --ws-url=wss://goaccess.${DOMAIN}:${HTTPS_PORT}/wss \
    $GOACCESS_ORIGIN \
    --config-file=/etc/goaccess/goaccess.conf
