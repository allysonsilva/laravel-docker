#!/bin/bash
# time ./scripts/loadbalancer-nginx.sh

set -e

startExecution=`date +%s`

if ! [ -x "$(command -v docker)" ]; then
    printf "\033[31m[LOADBALANCER-NGINX] Error: docker is not installed!\033[0m\n\n" >&2
    exit 1
fi

if ! [ -x "$(command -v docker-compose)" ]; then
    printf "\033[31m[LOADBALANCER-NGINX] Error: docker-compose is not installed!\033[0m\n\n" >&2
    exit 1
fi

set -o allexport
[[ -f docker.env ]] && source docker.env
set +o allexport

printf "\n"
printf "\033[34m==================================================\033[0m\n"
printf "\033[34m============== [LOADBALANCER-NGINX] ==============\033[0m\n"
printf "\033[34m==================================================\033[0m\n\n"

help()
{
    echo -e "Usage: \033[3m$0\033[0m [ -p=|--php-container-name= ] [ -n=|--nginx-container-name= ]" 1>&2
    echo -e "\t\t\t\t       [ -l=|--loadbalancer-name= ] [ -f=|--filename-server= ] [ --not-reload-nginx ]" 1>&2

    echo
    echo -e "\t\033[3;32m-p|--php-container-name\033[0m
                    - Corresponde ao filtro(todo, parte ou regex) do nome dos containers \033[1mPHP/LARAVEL\033[0m
                    que será utilizado no comando \033[33m\`>_ docker ps\`\033[0m na opção \033[33m\`>_ --filter name=\"VALUE_SENT\"\`\033[0m
                    - A lista dos nomes dos containers recuperados no comando \`>_ docker ps\`,
                    serão utilizados no balanceamento de carga do NGINX no grupo de servidores
                    \`upstream\` da opção \`--loadbalancer-name\`
                    \033[1mDefault\033[0m: \033[3;32m^/v([0-9]+)${COMPOSE_PROJECT_NAME}_app_\d+\033[0m"

    echo
    echo -e "\t\033[3;32m-n|--nginx-container-name\033[0m
                    - Filtra os containers NGINX para manipulação do balanceamento de carga
                    - Assim como a opção \`--php-container-name\`, o valor pode corresponder ao nome
                    completo do container ou a parte do nome do container com ou sem regex
                    \033[1mDefault\033[0m: \033[3;32m^v\d+${COMPOSE_PROJECT_NAME}_webserver\033[0m"

    echo
    echo -e "\t\033[3;32m-l|--loadbalancer-name\033[0m
                    Nome que será utilizado no load balancing do NGINX na diretiva \033[33m\`upstream NAME_SENT {}\`\033[0m
                    \033[1mDefault\033[0m: \033[3;32mloadbalancer-app\033[0m"

    echo
    echo -e "\t\033[3;32m-f|--filename-server\033[0m
                    Nome do arquivo NGINX(virtual server) que será modificado na pasta \033[33m./services/nginx/servers/\033[0m
                    \033[1mDefault\033[0m: \033[3;32mapp.conf\033[0m"

    echo
    echo -e "\t\033[3;32m--not-reload-nginx\033[0m
                    Use essa opção para não recarregar \033[33m\`>_ nginx -s reload\`\033[0m os worker processes do NGINX"

    echo
    echo -e "\t \033[1mEXAMPLES:\033[0m"
    echo -e "\t     $0 --php-container-name=\"^/foo$\" \ \n\t\t\t\t\t--nginx-container-name=^webserver \ \n\t\t\t\t\t--loadbalancer-name=backend \ \n\t\t\t\t\t--filename-server=xyz.conf"
    echo -e "\t     $0 -p=\"^/foo$\" -n=^webserver -l=backend -f=xyz.conf --not-reload-nginx"
}

# # passing option -h or --help
# while getopts ":h" option; do
#    case $option in
#         h) # display Help
#             help
#             exit;;
#         # \?) # incorrect option
#         #     echo "Error: Invalid option"
#         #     exit;;
#    esac
# done

# printf "\033[36m[LOADBALANCER-NGINX] Script started on $(date +"%d/%m/%Y %T") ⏳\033[0m\n\n"

[[ -n "$COMPOSE_PROJECT_NAME" ]] && export COMPOSE_PROJECT_NAME="_${COMPOSE_PROJECT_NAME}"

# Default values of arguments
PHP_CONTAINER_NAME=${PHP_CONTAINER_NAME:-"^/v([0-9]+)${COMPOSE_PROJECT_NAME}_app_\d+"}
NGINX_CONTAINER_NAME=${NGINX_CONTAINER_NAME:-"^v\d+${COMPOSE_PROJECT_NAME}_webserver"}
NGINX_LOADBALANCER_NAME=${NGINX_LOADBALANCER_NAME:-loadbalancer-app}
NGINX_FILENAME_SERVER=${NGINX_FILENAME_SERVER:-app.conf}
NOT_RELOAD_NGINX=false
OTHER_ARGUMENTS=()

# Loop through arguments and process them
# @see https://pretzelhands.com/posts/command-line-flags
for arg in "$@"
do
    case $arg in
        --not-reload-nginx)
        NOT_RELOAD_NGINX=true
        shift
        ;;
        -p=*|--php-container-name=*)
        PHP_CONTAINER_NAME="${arg#*=}"
        shift
        ;;
        -n=*|--nginx-container-name=*)
        NGINX_CONTAINER_NAME="${arg#*=}"
        shift
        ;;
        -l=*|--loadbalancer-name=*)
        NGINX_LOADBALANCER_NAME="${arg#*=}"
        shift
        ;;
        -f=*|--filename-server=*)
        NGINX_FILENAME_SERVER="${arg#*=}"
        shift
        ;;
        -h|--help)
        help
        exit 0
        ;;
        *)
        OTHER_ARGUMENTS+=("$1")
        shift # Remove generic argument from processing
        ;;
    esac
done

echo -e "\033[1m# -p|--php-container-name:\033[0m \033[1;3;35m$PHP_CONTAINER_NAME\033[0m"
echo -e "\033[1m# -n|--nginx-container-name:\033[0m \033[1;3;35m$NGINX_CONTAINER_NAME\033[0m"
echo -e "\033[1m# -l|--loadbalancer-name:\033[0m \033[1;3;35m$NGINX_LOADBALANCER_NAME\033[0m"
echo -e "\033[1m# -f|--filename-server:\033[0m \033[1;3;35m$NGINX_FILENAME_SERVER\033[0m"
echo -e "\033[1m# --not-reload-nginx:\033[0m \033[1;3;35m$NOT_RELOAD_NGINX\033[0m"
echo -e "\033[1m# Other arguments:\033[0m \033[1;3;35m${OTHER_ARGUMENTS[*]}\033[0m"
echo

readarray -t CONTAINERS_PHP < <(docker ps -q --filter name="$PHP_CONTAINER_NAME" --filter status=running --filter health=healthy --no-trunc --format="{{.Names}}")

NGINX_FILENAME_SERVER="./services/nginx/servers/${NGINX_FILENAME_SERVER}"

if [[ ${#CONTAINERS_PHP[@]} -le 0 ]]; then
    printf "\033[31m[LOADBALANCER-NGINX] Nenhum container \033[1mPHP/LARAVEL\033[0m\033[31m pôde ser encontrado ❌\033[0m\n\n"
    exit 1
fi

if ! [ -f ${NGINX_FILENAME_SERVER} ]; then
    printf "\033[31m[LOADBALANCER-NGINX] Arquivo \"${NGINX_FILENAME_SERVER}\" de virtual server do NGINX não pôde ser encontrado ❌\033[0m\n\n"
    exit 1
fi

if [[ $NOT_RELOAD_NGINX == false ]]; then
    readarray -t CONTAINERS_NGINX < <(docker ps -q --filter name="$NGINX_CONTAINER_NAME" --filter status=running --filter health=healthy --no-trunc --format="{{.Names}}")

    if [[ ${#CONTAINERS_NGINX[@]} -le 0 ]]; then
        printf "\033[31m[LOADBALANCER-NGINX] Nenhum container \033[1mNGINX\033[0m\033[31m pôde ser encontrado ❌\033[0m\n\n"
        exit 1
    fi

    printf "\033[96m### 🐳 Containers NGINX que serão recarregados: \n - Configuration reload \n - Start the new worker processes with a new configuration \n - Gracefully shutdown the old worker processes \033[0m\n\n"

    printf "\033[97m"
    docker ps --filter name="$NGINX_CONTAINER_NAME" --filter status=running --filter health=healthy --no-trunc --format="table {{.Names}}\t{{.Status}}\t{{.State}}" 2>/dev/null || true
    printf "\033[0m"
fi

printf "\n\033[96m### 🐳 Containers PHP/LARAVEL que serão utilizados no Load Balancing do NGINX:\033[0m\n\n"

printf "\033[97m"
docker ps --filter name="$PHP_CONTAINER_NAME" --filter status=running --filter health=healthy --no-trunc --format="table {{.Names}}\t{{.Status}}\t{{.State}}" 2>/dev/null || true
printf "\033[0m"

CONTAINERS_TO_SERVER=''

for index in "${!CONTAINERS_PHP[@]}"; do
    # I=$(expr $index + 1)
    # printf "%s\t%s\n" "$I" "${CONTAINERS_PHP[$index]}"

    CONTAINERS_TO_SERVER+="    server ${CONTAINERS_PHP[$index]}:9000;\n"
    # CONTAINERS_TO_SERVER+="    server ${CONTAINERS_PHP[$index]}:9000 max_fails=3 fail_timeout=30s;\n"
done

sed -i \
        -e '/^###SET_UPSTREAM$/,/^###END_SET_UPSTREAM$/{//!d;}' \
        -e '/^###SET_UPSTREAM$/a upstream '"$NGINX_LOADBALANCER_NAME"' {\n    zone '"$NGINX_LOADBALANCER_NAME"' 256k;\n\n'"$CONTAINERS_TO_SERVER"'}' \
        -e 's/set $phpfpm_server.*/set $phpfpm_server '"$NGINX_LOADBALANCER_NAME"';/g' \
    \
    $NGINX_FILENAME_SERVER

if [[ $NOT_RELOAD_NGINX == false ]]; then
    printf "\n\033[33m[LOADBALANCER-NGINX] Recarregando(\`>_ nginx -s reload\`) as configurações e os worker processes dos containers NGINX: \033[1;3m${CONTAINERS_NGINX[*]}\033[0m\n\n"

    for nginxContainerName in "${CONTAINERS_NGINX[@]}"; do
        # # Configuration reload
        # # Start the new worker processes with a new configuration
        # # Gracefully shutdown the old worker processes
        docker exec -it $nginxContainerName nginx -s reload 2>/dev/null || true

        printf "\033[32m[LOADBALANCER-NGINX] NGINX container \033[1;35m$nginxContainerName\033[0m\033[32m worker processes reload successfully ✅\033[0m\n\n"
    done
else
    printf "\n\033[33m[LOADBALANCER-NGINX] Configuração/Worker processes do container NGINX não será recarregado(\`nginx -s reload\`)! \033[0m\n\n"
fi

# printf "\033[36m[LOADBALANCER-NGINX] Script finalizado com sucesso em $(date +"%d/%m/%Y %T") 🚀\033[0m\n\n"

# diffTimeLps=$(( $(date +%s) - ${startExecution} ))
# printf "\033[36m[LOADBALANCER-NGINX] Duração em segundos da execução do script: \033[1m$(($diffTimeLps % 60))\033[0m\n\n"

exit 0
