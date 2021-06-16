#!/bin/bash
# time ./scripts/deploy-version.sh
# @see HTTPie(https://httpie.io/)

# This will cause the script to exit on the first error
set -e

if ! [ -x "$(command -v docker)" ]; then
    printf "\033[31m[DEPLOY-VERSION] ERROR: docker is not installed!\033[0m\n\n" >&2
    exit 1
fi

if ! [ -x "$(command -v docker-compose)" ]; then
    printf "\033[31m[DEPLOY-VERSION] ERROR: docker-compose is not installed!\033[0m\n\n" >&2
    exit 1
fi

set -o allexport
[[ -f docker.env ]] && source docker.env
set +o allexport

set -o allexport
[[ -f deploy.env ]] && source deploy.env
set +o allexport

container_state()
{
    local options containers=() timeout=60

    # options may be followed by one colon to indicate they have a required argument
    if ! options=$(getopt --longoptions "containers:,timeout::" --options "c:t::" --alternative -- "$@")
    then
        # something went wrong, getopt will put out an error message for us
        exit 1
    fi

    if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi

    eval set -- "$options"

    while [ $# -gt 0 ]; do
        case $1 in
            --containers) shift ; IFS=' ' read -r -a containers <<< "$1" ;;
            --timeout) timeout="$2" ; shift;;
            # (-*) echo "$0: error - unrecognized option $1" 1>&2; exit 1;;
            (*) break;;
        esac
        shift
    done

    if [[ "$(declare -p containers)" =~ "declare -a" && ${#containers[@]} -gt 0 ]]; then

        for containerName in ${containers[@]}; do

            # Set timeout to the number of seconds you are willing to wait
            timeoutIn=$timeout; counter=0

            printf "\n\033[3;33m[DEPLOY-VERSION] Esperando healthcheck do container docker \"${containerName}\" = \"healthy\" ⏳ \033[0m\n"

            # This says that until docker inspect reports the container is in a running state, keep looping
            until [[ "$(docker container inspect -f '{{.State.Health.Status}}' ${containerName})" == "healthy" &&
                      $(docker container inspect --format '{{json .State.Running}}' $containerName) == true ]]; do

                # If we've reached the timeout period, report that and exit to prevent running an infinite loop
                if [[ $timeoutIn -lt $counter ]]; then
                    echo
                    docker logs $containerName

                    printf "\n\033[1;31m[DEPLOY-VERSION] ERROR: Timed out waiting for ${containerName} to come up/healthy ❌\033[0m\n\n"
                    exit 1
                fi

                # Every 5 seconds update the status
                if (( $counter % 5 == 0 )); then
                    printf "\n\033[35m[DEPLOY-VERSION] Waiting for $containerName to be ready/healthy (${counter}/${timeoutIn}) ⏱ \033[0m\n"
                fi

                # Wait a second and increment the counter
                sleep 1s
                counter=$((counter + 1))
            done

            printf "\n\033[43;3;30m[DEPLOY-VERSION] Serviço Docker \"${containerName}\" adicionado e Healthcheck validado com sucesso(UP) 🚀\033[0m\n"

        done

    else
        printf "\n\033[1;31m[DEPLOY-VERSION] ERROR: Nenhum container pôde ser encontrado na opção \`--containers\` ❌\033[0m\n\n"
        exit 1
    fi

    (( $? == 0 )) || return
}

usage()
{
    echo -e "Usage: \033[3m$0\033[0m [ -v=|--new-version= ] [ --num-nginx-scale= ] [ --num-php-scale= ]" 1>&2
    echo -e "\t\t\t\t   [ -o=|--compose-options= ] [ -s=|--compose-services= ]" 1>&2
    echo -e "\t\t\t\t   [ -d=|--traefik-api-domain= ] [ -t=|--traefik-service-name= ]" 1>&2

    echo
    echo -e "\t\033[3;32m-h, -help,             --help\033[0m
                    Display help"

    echo
    echo -e "\t\033[3;32m-v, -new-version,      --new-version\033[0m
                    - Nova versão utilizada como prefixo dos containers(PHP && NGINX)
                    - \033[3mUtilizando o padrão: \033[1mv{NUM_VERSAO}_CONTAINER_NAME_{NUM_SCALE}\033[0m\033[0m
                    \033[1mDefault\033[0m: \033[3;32mletra \"v\" concatenado com {número da versão antiga + 1}\033[0m"

    echo
    echo -e "\t\033[3;32m-num-nginx-scale,      --num-nginx-scale\033[0m
                    - Número total de containers que serão inicializados no contexto do \033[1mWebserver/NGINX\033[0m
                    \033[1mDefault\033[0m: \033[3;32mNúmero total de container em execução do NGINX\033[0m"

    echo
    echo -e "\t\033[3;32m-num-php-scale,        --num-php-scale\033[0m
                    - Número total de containers que serão inicializados no contexto do \033[1mAPP/PHP\033[0m
                    - \033[3mEsses containers serão utilizados no balanceamento de carga do NGINX!\033[0m
                    \033[1mDefault\033[0m: \033[3;32mNúmero total de container em execução do PHP\033[0m"

    echo
    echo -e "\t\033[3;32m-o, -compose-options,  --compose-options\033[0m
                    - \033[3mUsado pelos containers do Webserver/NGINX no comando da sua inicialização(UP)\033[0m
                    - Opções adicionais do comando $> docker-compose [-f <arg>...] [options]
                    - \033[3mUtilizado para usar arquivos docker-compose.yml por meio \`-f path/to/docker-compose.yml\`\033[0m
                    \033[1mDefault\033[0m: \033[3;32m-f services/app/docker-compose.webserver.yml\033[0m"

    echo
    echo -e "\t\033[3;32m-s, -compose-services, --compose-services\033[0m
                    - \033[3mUsado pelos containers do Webserver/NGINX no comando da sua inicialização(UP)\033[0m
                    - \033[3mNome do serviço no arquivo docker-compose.yml do container do NGINX\033[0m
                    \033[1mDefault\033[0m: \033[3;32mwebserver\033[0m"

    echo
    echo -e "\t\033[3;32m-d, -traefik-api-domain,   --traefik-api-domain\033[0m
                    - URL da API do Traefik para verificação da integridade do container NGINX=\033[1mhealthy\033[0m
                    \033[1mDefault\033[0m: \033[3;32mhttps://traefik.${DOMAIN:-yourdomain.tld}\033[0m"

    echo
    echo -e "\t\033[3;32m-t, -traefik-service-name, --traefik-service-name\033[0m
                    - Serviço NGINX de \033[1mLoad Balancer\033[0m que será manipulado no Traefik
                    \033[1mDefault\033[0m: \033[3;32mwebserver@docker\033[0m"

    echo
    echo -e "\t \033[1mExemplos:\033[0m"
    echo -e "\t     $0 --new-version=v10 --num-nginx-scale=2 -num-php-scale=4"
    echo -e "\t     $0 -new-version=v10 -o\"--verbose\" -swebserver2"
    echo -e "\t     $0 --compose-options=\"--verbose\" -compose-services=webserver2"
    echo -e "\t     $0 -vv11 -o\"--verbose\" -swebserver2 -dyourdomain.tld -twebserver2@docker"

    exit 0
}

# [ $# -eq 0 ] && usage

# [$@ Is all command line parameters passed to the script]
# --options is for short options like -v
# --longoptions is for long options with double dash like --version
# [The comma separates different long options]
# --alternative is for long options with single dash like -version
options=$(getopt --longoptions "help,new-version::,num-nginx-scale::,num-php-scale::,compose-options::,compose-services::,traefik-api-domain::,traefik-service-name::" --options "hv::o::s::d::t::" --alternative -- "$@")

if [ $? != 0 ] ; then echo -e "\n Terminating..." >&2 ; exit 1 ; fi

# set --:
# If no arguments follow this option, then the positional parameters are unset. Otherwise, the positional parameters
# are set to the arguments, even if some of them begin with a '-'
eval set -- "$options"

printf "\n"
printf "\033[34m==============================================\033[0m\n"
printf "\033[34m============== [DEPLOY-VERSION] ==============\033[0m\n"
printf "\033[34m==============================================\033[0m\n"

printf "\n\033[36m[DEPLOY-VERSION] Script started on $(date +"%d/%m/%Y %T") ⏳\033[0m\n\n"

# Default values of arguments
DOMAIN=${DOMAIN:-yourdomain.tld}
NEW_VERSION=${NEW_VERSION:-}
NUM_NGINX_SCALE=${NUM_NGINX_SCALE:-}
NUM_PHP_SCALE=${NUM_PHP_SCALE:-}
COMPOSE_PROJECT_NAME=${COMPOSE_PROJECT_NAME:-nothing}
DOCKER_COMPOSE_OPTIONS=${DOCKER_COMPOSE_OPTIONS:-""}
DOCKER_COMPOSE_WEBSERVER_OPTIONS=${DOCKER_COMPOSE_WEBSERVER_OPTIONS:-"-f services/app/docker-compose.webserver.yml"}
DOCKER_COMPOSE_SERVICES=${DOCKER_COMPOSE_SERVICES:-"webserver"}
TRAEFIK_API_DOMAIN=${TRAEFIK_API_DOMAIN:-"traefik.${DOMAIN}"}
TRAEFIK_SERVICE_NAME=${TRAEFIK_SERVICE_NAME:-"webserver@docker"}

NGINX_CONTAINER_NAME_SUFFIX="webserver_\d+";
NGINX_CONTAINER_NAME=${NGINX_CONTAINER_NAME:-"^/v([0-9]+)_${COMPOSE_PROJECT_NAME}_${NGINX_CONTAINER_NAME_SUFFIX}"}

PHP_CONTAINER_NAME_SUFFIX="app_(\d+)";
PHP_CONTAINER_NAME=${PHP_CONTAINER_NAME:-"^/v\d+_${COMPOSE_PROJECT_NAME}_${PHP_CONTAINER_NAME_SUFFIX}"}

OTHER_ARGUMENTS=()

# @see https://stackoverflow.com/questions/16483119/an-example-of-how-to-use-getopts-in-bash
while true ; do
    case $1 in
        -h|--help)
            usage
            ;;
        -v|--new-version) shift; NEW_VERSION=$1 ;;
        --num-nginx-scale) shift; NUM_NGINX_SCALE=$1 ;;
        --num-php-scale) shift; NUM_PHP_SCALE=$1 ;;
        -o|--compose-options) shift; DOCKER_COMPOSE_OPTIONS=$1 ;;
        -s|--compose-services) shift; DOCKER_COMPOSE_SERVICES=$1 ;;
        -d|--traefik-api-domain) shift; TRAEFIK_API_DOMAIN=$1 ;;
        -t|--traefik-service-name) shift; TRAEFIK_SERVICE_NAME=$1 ;;
        --) shift ; break ;;
        *) shift;  OTHER_ARGUMENTS+=("$1") ;;
    esac
    shift
done

# ==============================================================================
# ==============================================================================

readarray -t OLD__PHP_CONTAINERS < <(docker ps -q --filter name="${PHP_CONTAINER_NAME}" --filter status=running --filter health=healthy --no-trunc --format="{{.Names}}")
readarray -t OLD__NGINX_CONTAINERS < <(docker ps -q --filter name="${NGINX_CONTAINER_NAME}" --filter status=running --filter health=healthy --no-trunc --format="{{.Names}}")

NUM_NGINX_SCALE=${NUM_NGINX_SCALE:-${#OLD__NGINX_CONTAINERS[@]}}
NUM_PHP_SCALE=${NUM_PHP_SCALE:-${#OLD__PHP_CONTAINERS[@]}}

[[ "$NUM_PHP_SCALE" -le 0 ]] && NUM_PHP_SCALE=2
[[ "$NUM_NGINX_SCALE" -le 0 ]] && NUM_NGINX_SCALE=1

OLD_VERSION=$(echo ${OLD__NGINX_CONTAINERS[0]} | sed -r 's/^v([0-9]+).*/\1/')
NEXT_VERSION=${NEW_VERSION:-"v$(($OLD_VERSION + 1))"}

# ==============================================================================
# ==============================================================================

printf "\e[1m# Nova versão dos containers/aplicação no deploy:\e[0m \e[1;3;35m$NEXT_VERSION\e[0m\n"
printf "\e[1m# Quantidade de containers/serviços Webserver/NGINX que serão executados:\e[0m \e[1;3;35m$NUM_NGINX_SCALE\e[0m\n"
printf "\e[1m# Quantidade de containers/serviços APP/PHP-Laravel que serão executados:\e[0m \e[1;3;35m$NUM_PHP_SCALE\e[0m\n"
printf "\e[1m# Opções do comando $> docker-compose [options]:\e[0m \e[1;3;35m$DOCKER_COMPOSE_OPTIONS\e[0m\n"
printf "\e[1m# $> docker-compose [-f <arg>...] para container Webserver/NGINX:\e[0m \e[1;3;35m$DOCKER_COMPOSE_WEBSERVER_OPTIONS\e[0m\n"
printf "\e[1m# Serviços/Containers que serão inicializados pelo comando $> docker-compose up [SERVICE...]:\e[0m \e[1;3;35m$DOCKER_COMPOSE_SERVICES\e[0m\n"
printf "\e[1m# URL da API do Traefik:\e[0m \e[1;3;35m$TRAEFIK_API_DOMAIN\e[0m\n"
printf "\e[1m# Serviço de Load Balancer que será manipulado no Traefik:\e[0m \e[1;3;35m$TRAEFIK_SERVICE_NAME\e[0m\n"
printf "\e[1;4m# Regex para filtrar e manipular os containers NGINX:\e[0m \e[46;3;30m$NGINX_CONTAINER_NAME\e[0m\n"
printf "\e[1;4m# Regex para filtrar e manipular os containers PHP:\e[0m \e[46;3;30m$PHP_CONTAINER_NAME\e[0m\n"
printf "\e[1m# Outros argumentos do script:\e[0m \e[1;3;35m${OTHER_ARGUMENTS[*]}\e[0m\n"
echo

echo "### PWD"
echo `pwd`
echo

# ==============================================================================
# ==============================================================================

set -x
export CONTAINER_VERSION=${NEXT_VERSION}
{ set +x; } 2>/dev/null

PREFIX_TEMP__CONTAINER="${CONTAINER_VERSION}_temporary_${COMPOSE_PROJECT_NAME}"

printf "\n\033[3;33m[DEPLOY-VERSION] >_ git checkout ./services/nginx/servers&&./traefik/dynamic/WRR-service.yml \033[0m\n"
git checkout ./services/nginx/servers
git checkout ./traefik/dynamic/WRR-service.yml

FILE_TRAEFIK_WRR="./traefik/dynamic/WRR-service.yml"
FILE_NGINX_PHPFPM_STATUS="./services/nginx/servers/phpfpm-status.conf"

MAKE_APP="make \
            -f Makefile \
            -f services/app/Makefile"

printf "\n\033[3;33m[DEPLOY-VERSION] Baixando imagem Docker do serviço APP Laravel 🐳 \033[0m\n"

${MAKE_APP} docker-pull-app

printf "\n\033[3;33m[DEPLOY-VERSION] Executando serviço/container(2) Docker \"temporário\" APP Laravel 🐳 \033[0m\n"

REGEX_TEMP__PHP_CONTAINER="^/${PREFIX_TEMP__CONTAINER}_${PHP_CONTAINER_NAME_SUFFIX}"

${MAKE_APP} \
    docker-up-app \
        COMPOSE_PROJECT_NAME_SHELL="${COMPOSE_PROJECT_NAME}" \
        CONTAINER_NAME_PREFIX="${PREFIX_TEMP__CONTAINER}" \
        options="${DOCKER_COMPOSE_OPTIONS}" \
        scale=2

readarray -t TEMP__PHP_CONTAINERS < <(docker ps -q --filter name="${REGEX_TEMP__PHP_CONTAINER}" --filter status=running --no-trunc --format="{{.Names}}")

container_state --timeout=45 --containers="${TEMP__PHP_CONTAINERS[*]}"

printf "\n\n\033[46;3;30m[DEPLOY-VERSION] Atualizando arquivo de Load Balancing do APP Laravel \"temporário\" no Webserver/NGINX ☄️ \033[0m\n\n"

WEBSERVER_TEMP_CONTAINER_NAME="${PREFIX_TEMP__CONTAINER}_webserver"

bash ./scripts/loadbalancer-nginx.sh \
        -p=${REGEX_TEMP__PHP_CONTAINER} \
        -n=${WEBSERVER_TEMP_CONTAINER_NAME} \
        --not-reload-nginx

MAKE_WEBSERVER="make \
                    -f Makefile \
                    -f services/nginx/Makefile"

printf "\n\033[3;33m[DEPLOY-VERSION] Baixando imagem Docker do serviço Webserver/NGINX 🐳 \033[0m\n"

${MAKE_WEBSERVER} docker-pull-webserver

printf "\n\033[3;33m[DEPLOY-VERSION] Executando serviço/container(1) Docker \"temporário\" Webserver/NGINX 🐳 \033[0m\n"

${MAKE_WEBSERVER} \
        WEBSERVER_TEMP_CONTAINER_NAME="${WEBSERVER_TEMP_CONTAINER_NAME}" \
        COMPOSE_PROJECT_NAME_SHELL="${COMPOSE_PROJECT_NAME}" \
        CONTAINER_NAME_PREFIX="${PREFIX_TEMP__CONTAINER}" \
        docker-up-webserver \
        options="${DOCKER_COMPOSE_OPTIONS} ${DOCKER_COMPOSE_WEBSERVER_OPTIONS}" \
        services=webserver-temporary

container_state --timeout=45 --containers="${WEBSERVER_TEMP_CONTAINER_NAME}"

# (Uncomment)
sed -i -e '/### BEGIN-WEBSERVER-TEMPORARY$/,/### END-WEBSERVER-TEMPORARY$/{//!{s/\(^[[:blank:]]\)*#/\1 /}}' $FILE_TRAEFIK_WRR

# (Comment)
sed -i -e '/### BEGIN-WEBSERVER$/,/### END-WEBSERVER$/{//!{s/./#/}}' $FILE_TRAEFIK_WRR

echo
set -x
export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME}"
{ set +x; } 2>/dev/null

CONTAINER_NAME_PREFIX="${CONTAINER_VERSION}_${COMPOSE_PROJECT_NAME}"

printf "\n\e[42;3;30m[DEPLOY-VERSION] Serviço/Container Traefik \"webserver@docker\" comentado(* para desabilita-lo do Load Balancing Weighted Round Robin do Traefik), e Serviço/Container \"webserver-temporary@docker\" descomentado, para que todas as requisições sejam redirecionadas para o novo container \"temporário\" do Webserver/NGINX ☄️\e[0m\n\n"

printf "\033[3;33m[DEPLOY-VERSION] Executando serviço/container($NUM_PHP_SCALE) Docker APP Laravel 🐳 \033[0m\n"

${MAKE_APP} \
    docker-up-app \
        COMPOSE_PROJECT_NAME_SHELL="${COMPOSE_PROJECT_NAME}" \
        options="${DOCKER_COMPOSE_OPTIONS}" \
        up_options="--force-recreate --no-build --no-deps --detach" \
        version="${CONTAINER_VERSION}" \
        scale=$NUM_PHP_SCALE

# printf "\n\033[3;33m[DEPLOY-VERSION] Esperando healthcheck do container docker APP Laravel = \"healthy\" ⏳ \033[0m\n"

REGEX_NEW__PHP_CONTAINER="^${CONTAINER_NAME_PREFIX}_${PHP_CONTAINER_NAME_SUFFIX}"
readarray -t NEW__PHP_CONTAINERS < <(docker ps -q --filter name="${REGEX_NEW__PHP_CONTAINER}" --filter status=running --no-trunc --format="{{.Names}}")

container_state --timeout=60 --containers="${NEW__PHP_CONTAINERS[*]}"

printf "\n\n\033[46;3;30m[DEPLOY-VERSION] Atualizando arquivo de Load Balancing do APP Laravel no Webserver/NGINX ☄️ \033[0m\n\n"

REGEX_NEW__NGINX__CONTAINER="^${CONTAINER_NAME_PREFIX}_${NGINX_CONTAINER_NAME_SUFFIX}"

bash ./scripts/loadbalancer-nginx.sh --php-container-name="${REGEX_NEW__PHP_CONTAINER}" \
                                     --nginx-container-name="${REGEX_NEW__NGINX__CONTAINER}" \
                                     --not-reload-nginx

sed -i -e '/###BEGIN_PHPFPM_LOCATIONS$/,/###END_PHPFPM_LOCATIONS$/{//!d;}' $FILE_NGINX_PHPFPM_STATUS

for containerName in ${NEW__PHP_CONTAINERS[@]}; do
    urlNginx="fpm-status-${containerName}"
    fastcgiPass="fastcgi_pass ${containerName}:9000;"

    sed -i -e '/###BEGIN_PHPFPM_LOCATIONS$/a \location ~ ^/('"${urlNginx}"')$ {'"${fastcgiPass}"'}' $FILE_NGINX_PHPFPM_STATUS
done

printf "\n\033[3;33m[DEPLOY-VERSION] Executando serviço/container($NUM_NGINX_SCALE) Docker Webserver/NGINX 🐳 \033[0m\n"

${MAKE_WEBSERVER} \
        docker-up-webserver \
        COMPOSE_PROJECT_NAME_SHELL="${COMPOSE_PROJECT_NAME}" \
        options="${DOCKER_COMPOSE_OPTIONS} ${DOCKER_COMPOSE_WEBSERVER_OPTIONS}" \
        up_options="--force-recreate --no-build --no-deps --detach" \
        version="${CONTAINER_VERSION}" \
        scale=$NUM_NGINX_SCALE

readarray -t NEW__NGINX__CONTAINERS < <(docker ps -q --filter name="${REGEX_NEW__NGINX__CONTAINER}" --filter status=running --no-trunc --format="{{.Names}}")

readarray -t NGINX_IPS_NETWORK_TRAEFIK < <(docker inspect -f "{{ .NetworkSettings.Networks.${TRAEFIK_DOCKER_NETWORK:-traefik_network}.IPAddress }}" ${NEW__NGINX__CONTAINERS[@]})
NGINX_IPS_NETWORK_TRAEFIK_SORTED=($(printf '%s\n' "${NGINX_IPS_NETWORK_TRAEFIK[@]}" | sort))

# Waiting for the container to be healthy
container_state --timeout=60 --containers="${NEW__NGINX__CONTAINERS[*]}"

printf "\n\033[3;33m[DEPLOY-VERSION] Removendo containers da versão antiga(v${OLD_VERSION}) do App/Laravel e Webserver/NGINX 🐳 \033[0m\n\n"

set -x
# docker stop --time 60 ${OLD__PHP_CONTAINERS[*]} >/dev/null 2>&1 || true
# docker stop --time 60 ${OLD__NGINX_CONTAINERS[*]} >/dev/null 2>&1 || true

docker rm --force ${OLD__PHP_CONTAINERS[*]} >/dev/null 2>&1 || true
docker rm --force ${OLD__NGINX_CONTAINERS[*]} >/dev/null 2>&1 || true
{ set +x; } 2>/dev/null

sleep 5s

printf "\n\033[93;40m[DEPLOY-VERSION] Esperando atualização do status(.serverStatus) do serviço/container NGINX no Traefik\033[0m\n"

TRAEFIK_CONTAINER_NAME=${TRAEFIK_CONTAINER_NAME:-$(docker ps -q --latest --filter name="${COMPOSE_PROJECT_NAME}_${TRAEFIK_CONTAINER_PREFIX:-traefik}" --filter status=running --no-trunc --format="{{.Names}}")}

TRAEFIK_HOSTPORT=$(docker inspect --format='{{(index (index .NetworkSettings.Ports "443/tcp") 0).HostPort}}' ${TRAEFIK_CONTAINER_NAME})

# Set timeout to the number of seconds you are willing to wait
timeoutNginxHealthyTraefik=30; counterNginxHealthyTraefik=0; NGINX_IS_HEALTHY_IN_TRAEFIK=false

echo "127.0.0.1 ${TRAEFIK_API_DOMAIN}" | sudo tee -a /etc/hosts

# This says that until docker inspect reports the container is in a running state, keep looping
until [[ $NGINX_IS_HEALTHY_IN_TRAEFIK == true ]]; do

    # If we've reached the timeout period, report that and exit to prevent running an infinite loop
    if [[ $timeoutNginxHealthyTraefik -lt $counterNginxHealthyTraefik ]]; then
        printf "\n\033[1;31m[DEPLOY-VERSION] ERROR: Timed out waiting for NGINX in traefik container to come up/healthy ❌\033[0m\n\n"

        exit 1
    fi

    # Every 5 seconds update the status
    if (( $counterNginxHealthyTraefik % 5 == 0 )); then

        traefikServices=$(curl \
                        --silent \
                        --fail \
                        --show-error \
                        --insecure \
                        --digest \
                        -H 'Accept: application/json' \
                        -X GET https://${TRAEFIK_API_DOMAIN}:$TRAEFIK_HOSTPORT/api/http/services)

        TRAEFIK_NGINX_IPS=($(echo "$traefikServices" | jq -c '.[] | select(.name | try contains("'$TRAEFIK_SERVICE_NAME'")) | .serverStatus | with_entries(select(.value == "UP") | .key |= sub("(https:\/\/|:443)"; ""; "g")) | keys[]' | tr -d \"))
        TRAEFIK_NGINX_IPS_SORTED=($(printf '%s\n' "${TRAEFIK_NGINX_IPS[@]}" | sort))

        # if [ ${#TRAEFIK_NGINX_IPS_SORTED[@]} != ${#NGINX_IPS_NETWORK_TRAEFIK_SORTED[@]} ]; then
        #     echo "$traefikServices"
        # fi

        if [[ "${TRAEFIK_NGINX_IPS_SORTED[*]}" == "${NGINX_IPS_NETWORK_TRAEFIK_SORTED[*]}" ]]; then
            NGINX_IS_HEALTHY_IN_TRAEFIK=true
        fi

        printf "\n\033[35m[DEPLOY-VERSION] Waiting for NGINX in traefik to be ready/healthy (${counterNginxHealthyTraefik}/${timeoutNginxHealthyTraefik}) ⏱ \033[0m\n"
    fi

    # Wait a second and increment the counter
    sleep 1s
    counterNginxHealthyTraefik=$((counterNginxHealthyTraefik + 1))
done

sudo sed -i -e "/${TRAEFIK_API_DOMAIN}/d" /etc/hosts

printf "\n\033[43;3;30m[DEPLOY-VERSION] Serviço Docker NGINX com os IPs (${TRAEFIK_NGINX_IPS_SORTED[*]}) adicionado e Healthcheck validado com sucesso(UP) no Traefik 🚀\033[0m\n"

# (Uncomment)
sed -i -e '/### BEGIN-WEBSERVER$/,/### END-WEBSERVER$/{//!{s/^#/ /}}' $FILE_TRAEFIK_WRR

# (Comment)
sed -i -e '/### BEGIN-WEBSERVER-TEMPORARY$/,/### END-WEBSERVER-TEMPORARY$/{//!{s/./#/}}' $FILE_TRAEFIK_WRR

printf "\n\e[42;3;30m[DEPLOY-VERSION] Serviço/Container Traefik \"webserver@docker\" descomentado e Serviço/Container \"webserver-temporary@docker\" comentado. Todas as requisições serão redirecionadas para o serviço \"webserver@docker\" no Traefik! ☄️\e[0m\n"

readarray -t CONTAINERS_NOT__APP_NGINX_TRAEFIK < <(docker ps -q --filter name="${COMPOSE_PROJECT_NAME}" --filter status=running --no-trunc --format="{{.Names}}" | grep -v "$(docker ps -q --filter name="${COMPOSE_PROJECT_NAME}_app|${COMPOSE_PROJECT_NAME}_webserver|${COMPOSE_PROJECT_NAME}_traefik" --filter status=running --no-trunc --format="{{.Names}}")")

curl https://${DOMAIN} >/dev/null 2>&1 || true

sleep 5s

if [[ ${WITH_NETDATA:-false} == true ]]; then
    FILE_NETDATA_CONF="./services/netdata/configs/netdata.conf"
    FILE_NETDATA_NGINX_MODULE="./services/netdata/configs/modules/go.d/nginx.conf"
    FILE_NETDATA_PHPFPM_MODULE="./services/netdata/configs/modules/go.d/phpfpm.conf"

    git checkout ./services/netdata/configs >/dev/null 2>&1 || true

    sed -i -e '/###BEGIN_PHPFPM_JOBS$/,/###END_PHPFPM_JOBS$/{//!d;}' $FILE_NETDATA_PHPFPM_MODULE

    for containerName in ${NEW__PHP_CONTAINERS[@]}; do
        sed -i -e '/###BEGIN_PHPFPM_JOBS$/a \ \ - name: APP - '"${containerName}"'\n    url: http://webserver:8099/fpm-status-'"${containerName}"'?full&json' $FILE_NETDATA_PHPFPM_MODULE
    done

    sed -i -e '/###BEGIN_NGINX_JOBS$/,/###END_NGINX_JOBS$/{//!d;}' $FILE_NETDATA_NGINX_MODULE

    for containerName in ${NEW__NGINX__CONTAINERS[@]}; do
        sed -i -e '/###BEGIN_NGINX_JOBS$/a \ \ - name: Webserver - '"${containerName}"'\n    url: http://'"${containerName}"':8098/nginx-status' $FILE_NETDATA_NGINX_MODULE
    done

    printf "\n\033[3;33m[DEPLOY-VERSION] Criando novo container NETDATA para manipular os dados dos novos containers APP/PHP-FPM && Webserver/NGINX 🐳 \033[0m\n\n"

    docker rm --force $(docker ps --quiet --filter name="${NETDATA_CONTAINER_NAME:-$COMPOSE_PROJECT_NAME_(netdata|dockerproxy)}" --filter status=running) >/dev/null 2>&1 || true

    CONTAINERS_TO_EXCLUDE_ON_NETDATA=''

    for containerName in ${CONTAINERS_NOT__APP_NGINX_TRAEFIK[@]}; do
        CONTAINERS_TO_EXCLUDE_ON_NETDATA+="    enable cgroup ${containerName} = no\n"
    done

    CONTAINERS_TO_EXCLUDE_ON_NETDATA+="    enable cgroup ${CONTAINER_VERSION}_${COMPOSE_PROJECT_NAME}_netdata = no\n"
    CONTAINERS_TO_EXCLUDE_ON_NETDATA+="    enable cgroup ${CONTAINER_VERSION}_${COMPOSE_PROJECT_NAME}_dockerproxy = no"
    # CONTAINERS_TO_EXCLUDE_ON_NETDATA=${CONTAINERS_TO_EXCLUDE_ON_NETDATA::-2}

    sed -i \
            -e '/###DISABLE_DOCKER_CONTAINERS$/,/###END_DISABLE_DOCKER_CONTAINERS$/{//!d;}' \
            -e '/###DISABLE_DOCKER_CONTAINERS$/a \'"$CONTAINERS_TO_EXCLUDE_ON_NETDATA"'' \
        \
        $FILE_NETDATA_CONF

    make docker-up context=netdata version="${CONTAINER_VERSION}"
fi

printf "\n\033[3;33m[DEPLOY-VERSION] Removendo containers temporários do App/Laravel e Webserver/NGINX 🐳 \033[0m\n\n"

### Turn on debug mode ###
set -x
docker rm --force ${WEBSERVER_TEMP_CONTAINER_NAME} >/dev/null 2>&1 || true

docker ps --all --quiet --no-trunc --filter name="^v(\d+)_temporary_${COMPOSE_PROJECT_NAME}_app" --format="{{.Names}}" | xargs docker stop --time 120 | xargs docker rm --force >/dev/null 2>&1 || true
docker ps --all --quiet --no-trunc --filter name="^v(\d+)_temporary_${COMPOSE_PROJECT_NAME}_webserver" --format="{{.Names}}" | xargs docker stop --time 120 | xargs docker rm --force >/dev/null 2>&1 || true
{ set +x; } 2>/dev/null

printf "\n\033[3;33m[DEPLOY-VERSION] Removendo container parados e volumes não utilizados 🐳 \033[0m\n\n"

set -x
docker container prune --force >/dev/null 2>&1 || true
docker volume prune --force >/dev/null 2>&1 || true
{ set +x; } 2>/dev/null
### Turn OFF debug mode ###

sed -i \
        -e "/^CONTAINER_VERSION.*/c\CONTAINER_VERSION=${CONTAINER_VERSION}" \
        -e "/^DOCKER_COMPOSE_APP_SCALE.*/c\DOCKER_COMPOSE_APP_SCALE=${NUM_PHP_SCALE}" \
        -e "/^DOCKER_COMPOSE_WEBSERVER_SCALE.*/c\DOCKER_COMPOSE_WEBSERVER_SCALE=${NUM_NGINX_SCALE}" \
    \
    .env

printf "\n\033[36m[DEPLOY-VERSION] Script finalizado com sucesso em $(date +"%d/%m/%Y %T") ⏱\033[0m\n\n"

exit 0
