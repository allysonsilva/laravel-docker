#!/bin/bash
set -eux

function fixperms() {
    for folder in $@; do
        if $(find ${folder} ! -user nginx -o ! -group nginx | egrep '.' -q); then
            echo "Fixing permissions in $folder..."
            chown -R www-data. "${folder}"
        else
            echo "Permissions already fixed in ${folder}."
        fi
    done
}

function runas_nginx() {
    su - nginx -s /bin/sh -c "$1"
}

# NGINX FastCGI Cache
if [ ! -d "${REMOTE_SRC}/storage/nginx/cache" ]; then
    mkdir -p ${REMOTE_SRC}/storage/nginx/cache
fi

echo "Setting Timezone to ${TZ} ..."
ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime
echo ${TZ} > /etc/timezone

# Nginx
echo "Setting Nginx configuration ..."

find /etc/nginx -type f -exec sed -i \
                                        -e "s/\\\.example\\\.com/\\\.$(echo $DOMAIN_APP | sed 's/\./\\\\./g')/g" \
                                        -e "s/example\\\.com/$(echo $DOMAIN_APP | sed 's/\./\\\\./g')/g" \
                                    {} \;

find /etc/nginx -type f -exec sed -i \
                                        -e "s|{{DOMAIN_APP}}|$DOMAIN_APP|g" \
                                        -e "s,{{APP_PATH_PREFIX}},$APP_PATH_PREFIX,g" \
                                    {} \;

sed -i \
        -e "s/@HSTS_HEADER@/$HSTS_HEADER/g" \
        -e "s/@RP_HEADER@/$RP_HEADER/g" /etc/nginx/snippets/server/security_http_headers.conf

if [[ "${ONLY_APP:-false}" == true ]]; then
    # Will remove all regular files (recursively, including hidden ones) except app.conf.
    find /etc/nginx/servers/* ! -name 'app.conf' -type f -exec rm -f {} +
    else
        if [ -f /etc/nginx/servers/app.conf ]; then
            # Remove DUPLICATED-conflicting server name [APP]
            rm /etc/nginx/servers/app.conf
        fi
fi

echo "Fixing permissions..."
fixperms "$REMOTE_SRC" /var/cache/nginx

# echo "Installing APP"
# runas_nginx "php artisan serve --port=8080 &>/dev/null"

## Docker Command
exec "$@"
