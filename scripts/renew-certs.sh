#!/bin/bash

set -e

set -o allexport
[[ -f docker.env ]] && source docker.env
set +o allexport

set -o allexport
[[ -f renew.env ]] && source renew.env
set +o allexport

printf "\n"
printf "\033[34m============================================\033[0m\n"
printf "\033[34m============== [RENEW-CERTS] ===============\033[0m\n"
printf "\033[34m============================================\033[0m\n\n"

MAKE_NGINX="make \
            -f Makefile \
            -f services/nginx/Makefile"

NGINX_CONTAINER_NAME=${NGINX_CONTAINER_NAME:-"^/v([0-9]+)_${COMPOSE_PROJECT_NAME}_webserver"}

readarray -t NGINX_CONTAINERS_NAME < <(docker ps -q --filter name="${NGINX_CONTAINER_NAME}" --filter status=running --filter health=healthy --no-trunc --format="{{.Names}}")

if [[ "${RENEW_CERT_IS_CHALLENGE_WEBROOT:-false}" == true ]]; then
    printf "\033[3;33m[RENEW-CERTS] Challenge mode is \"Webroot\"\033[0m\n"

    NGINX_SERVER_PATH=./services/nginx/servers/

    # # (Uncomment)
    find ${NGINX_SERVER_PATH} -maxdepth 1 -type f -regex ".*\.conf" -exec sed -i -e '/listen 80;/s/\(^[[:blank:]]\)*# //' {} \;
    find ${NGINX_SERVER_PATH} -maxdepth 1 -type f -regex ".*\.conf" -exec sed -i -e '/include servers\/shared\/letsencrypt\.conf;/s/\(^[[:blank:]]\)*# //' {} \;

    for CONTAINER_NAME in ${NGINX_CONTAINERS_NAME[@]}; do
        # # [NGINX] Start the new worker processes with a new configuration - Gracefully shutdown the old worker processes
        printf "\n\033[35m[RENEW-CERTS] Executing the command \`nginx -t\` AND \`nginx -s reload\` in the Docker Webserver/NGINX container \"$CONTAINER_NAME\" 🐳 \033[0m\n\n"

        docker exec --interactive $CONTAINER_NAME nginx -t || true
        docker exec --interactive $CONTAINER_NAME nginx -s reload 2>/dev/null || true
        # docker kill --signal HUP $CONTAINER_NAME >/dev/null 2>&1 || true
    done

    # # (Comment)
    find ${NGINX_SERVER_PATH} -maxdepth 1 -type f -regex ".*\.conf" -exec sed -i -e '/\(^\s*\?\)listen 80;/s/^[[:space:]]*/    # /' {} \;
    find ${NGINX_SERVER_PATH} -maxdepth 1 -type f -regex ".*\.conf" -exec sed -i -e '/\(^\s*\?\)include servers\/shared\/letsencrypt\.conf;/s/^[[:space:]]*/    # /' {} \;
else
    printf "\033[3;33m[RENEW-CERTS] Challenge mode is \"DNS\"\033[0m\n"
fi

printf "\n\033[43;3;30m[RENEW-CERTS] Executing command to renew certificates ✅\033[0m\n"

${MAKE_NGINX} \
    ${RENEW_CERT_COMMAND_TARGET} \
    ${RENEW_CERT_COMMAND_OPTIONS} \
    email="${RENEW_CERT_EMAIL}" \
    domains="${RENEW_CERT_DOMAINS}"

if [[ ${#NGINX_CONTAINERS_NAME[@]} -gt 0 ]]; then
    printf "\n\033[43;3;30m[RENEW-CERTS] Recreating the Webserver/NGINX containers 🐳 🚀\033[0m\n"

    ${MAKE_NGINX} \
        docker-up-webserver \
        up_options="--force-recreate --no-build --no-deps --detach"
fi

printf "\n\e[42;3;30m[RENEW-CERTS] Script successfully executed ☄️ \e[0m\n\n"

exit 0
