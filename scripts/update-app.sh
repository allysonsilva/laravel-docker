#!/bin/bash
# time ./scripts/update-app.sh

set -e

# ssh -o StrictHostKeyChecking=yes $SSH_SERVER 'bash -s' -- < update-app.sh --container-name=xyz --path=/var/www/xyz --branch=production

set -o allexport
[[ -f docker.env ]] && source docker.env
set +o allexport

set -o allexport
[[ -f update.env ]] && source update.env
set +o allexport

help()
{
    echo -e "Usage: \033[3m$0\033[0m [ -R|--with-reload-phpfpm ] [ -C=|--container-name= ] [ -W=|--container-workdir= ]" 1>&2
    echo -e "\t\t\t       [ -P=|--path= ] [ -B=|--branch= ] [ --npm-run= ]" 1>&2

    echo
    echo -e "\t\033[3;32m-h, -help, --help\033[0m
                    Display help"

    echo
    echo -e "\t\033[3;32m-R, -with-reload-phpfpm, --with-reload-phpfpm\033[0m
                    - Executa o reload graceful no PHP-FPM
                    - \033[3mEnvia o SIGNAL \033[1mSIGUSR2\033[0m\033[3m para o processo master do PHP-FPM\033[0m
                    \033[1mDefault\033[0m: \033[3;32mfalse\033[0m"

    echo
    echo -e "\t\033[3;32m-M, -force-migrations, --force-migrations\033[0m
                    - Executar as migrations com o comando \`php artisan migrate --force\`
                    \033[1mDefault\033[0m: \033[3;32mNão é executado o comando \`php artisan migrate\`\033[0m"

    echo
    echo -e "\t\033[3;32m-C, -container-name, --container-name\033[0m
                    - Corresponde ao nome do container PHP/Laravel que será executado os comandos \n\t\t    \033[1mlaravel(php artisan ...) e php composer\033[0m
                    \033[1mDefault\033[0m: \033[3;32m^/v([0-9]+)${COMPOSE_PROJECT_NAME}_app_\d+\033[0m"

    echo
    echo -e "\t\033[3;32m-W, -container-workdir, --container-workdir\033[0m
                    - Corresponde ao caminho/diretório dentro do container PHP/Laravel,
                      usado na opção \`--workdir\` do comando \`docker exec\` na execução de comandos \`artisan\`
                    \033[1mDefault\033[0m: \033[3;32mMesmo valor que a opção \`-P|--path\`\033[0m"

    echo
    echo -e "\t\033[3;32m-P, -path, --path\033[0m
                    - Caminho absoluto da pasta da aplicação PHP/Laravel onde será
                      atualizado o repositório com os comandos do GIT
                      \033[1mDefault\033[0m: \033[3;32m/var/www/app\033[0m"

    echo
    echo -e "\t\033[3;32m-B, -branch, --branch\033[0m
                    - Branch para realizar atualização dos arquivos(git pull origin <branch> --rebase)
                    \033[1mDefault\033[0m: \033[3;32mmaster\033[0m"

    echo
    echo -e "\t\033[3;32m-npm-run, --npm-run\033[0m
                    - Script/comandos \`npm\` para serem executados
                    \033[1mDefault\033[0m: \033[3;32mNão é executado nenhum comando \`npm\`\033[0m"

    echo
    echo -e "\t \033[1mEXAMPLES:\033[0m"
    echo -e "\t     $0 -MR --container-name=\"v1_app_1\""
    echo -e "\t     $0 -R --container-name=\"v1_app_1\" --path=\"/var/www/app\" --branch=\"main\""
    echo -e "\t     $0 --with-reload-phpfpm -P \"/var/www/app\" -B \"staging\" -C\"v1_app_1\" --npm-run=\"prod\""
    echo

    exit 0
}

if ! [ -x "$(command -v docker)" ]; then
    printf "\033[31m[UPDATE-APP] ERROR: docker is not installed!\033[0m\n\n" >&2
    exit 1
fi

if ! [ -x "$(command -v docker-compose)" ]; then
    printf "\033[31m[UPDATE-APP] ERROR: docker-compose is not installed!\033[0m\n\n" >&2
    exit 1
fi

printf "\n"
printf "\033[34m==========================================\033[0m\n"
printf "\033[34m============== [UPDATE-APP] ==============\033[0m\n"
printf "\033[34m==========================================\033[0m\n"

options=$(getopt --longoptions "help,with-reload-phpfpm,force-migrations,path:,branch:,container-name::,container-workdir::,npm-run::" --options "hRMP:B:C::W::" --alternative -- "$@")

if [ $? != 0 ] ; then echo -e "\n Terminating..." >&2 ; exit 1 ; fi

eval set -- "$options"

[[ -n "$COMPOSE_PROJECT_NAME" ]] && export COMPOSE_PROJECT_NAME="_${COMPOSE_PROJECT_NAME}"

# Default values of arguments
CONTAINER_RELOAD_PHPFPM=${CONTAINER_RELOAD_PHPFPM:-false}
CONTAINER_LARAVEL_RUN_MIGRATION=${CONTAINER_LARAVEL_RUN_MIGRATION:-false}
LARAVEL_CONTAINER_NAME=${LARAVEL_CONTAINER_NAME:-"^/v([0-9]+)${COMPOSE_PROJECT_NAME}_app_\d+"}
LARAVEL_CONTAINER_WORKDIR=${LARAVEL_CONTAINER_WORKDIR:-}
WEBPATH_GIT=${WEBPATH_GIT:-"/var/www/app"}
BRANCH=${BRANCH:-master}
NPM_COMMAND_RUN=${NPM_COMMAND_RUN:-""}
OTHER_ARGUMENTS=()

# @see https://stackoverflow.com/questions/16483119/an-example-of-how-to-use-getopts-in-bash
while true ; do
    case $1 in
        -h|--help)
            help
            ;;
        -R|--with-reload-phpfpm) CONTAINER_RELOAD_PHPFPM=true ;;
        -M|--force-migrations) CONTAINER_LARAVEL_RUN_MIGRATION=true ;;
        -C|--container-name) shift; LARAVEL_CONTAINER_NAME=$1 ;;
        -W|--container-workdir) shift; LARAVEL_CONTAINER_WORKDIR=$1 ;;
        -P|--path) shift; WEBPATH_GIT=$1 ;;
        -B|--branch) shift; BRANCH=$1 ;;
        --npm-run) shift; NPM_COMMAND_RUN=$1 ;;
        --) shift ; break ;;
        *) shift;  OTHER_ARGUMENTS+=("$1") ;;
    esac
    shift
done

echo

[[ -z "$LARAVEL_CONTAINER_WORKDIR" ]] && LARAVEL_CONTAINER_WORKDIR=${WEBPATH_GIT}

printf "\e[1m### Containers Docker PHP-FPM que será manipulado:\e[0m \e[1;3;35m$LARAVEL_CONTAINER_NAME\e[0m\n"
printf "\e[1m### Containers Docker PHP-FPM será recarregado?\e[0m \e[1;3;35m$CONTAINER_RELOAD_PHPFPM\e[0m\n"
printf "\e[1m### Containers Docker PHP-FPM deve executar as migrations(artisan migrate --force)?\e[0m \e[1;3;35m$CONTAINER_LARAVEL_RUN_MIGRATION\e[0m\n"
printf "\e[1m### Pasta da aplicação onde os comandos GIT serão executados:\e[0m \e[1;3;35m$WEBPATH_GIT\e[0m\n"
printf "\e[1m### Pasta que os comandos \`php artisan\` serão executados dentro do container:\e[0m \e[1;3;35m$LARAVEL_CONTAINER_WORKDIR\e[0m\n"
printf "\e[1m### Git Branch:\e[0m \e[1;3;35m$BRANCH\e[0m\n"
printf "\e[1m### Comandos NPM que serão executados:\e[0m \e[1;3;35m$NPM_COMMAND_RUN\e[0m\n"
printf "\e[1m### Outros argumentos do script:\e[0m \e[1;3;35m${OTHER_ARGUMENTS[*]}\e[0m\n"

if [ -z "$WEBPATH_GIT" ] || [ -z "$BRANCH" ]; then
    printf "\n\033[31m[UPDATE-APP] As seguintes opções --path e --branch devem ser obrigatórios na execução desse script ❌\033[0m\n"

    exit 1
fi

cd $WEBPATH_GIT

echo
echo "### PWD"
echo `pwd`
echo

if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" != "true" ]; then
    printf "\033[31m[UPDATE-APP] A pasta \"$WEBPATH_GIT\" não é um repositório GIT ❌\033[0m\n\n"

    exit 1
fi

printf "\033[32m[UPDATE-APP] >_ git checkout -- .\033[0m\n\n"
git checkout -- .

if [[ -z "$(git branch --list ${BRANCH})" ]]; then
    # if [ "$(git rev-list --count --all 2>/dev/null)" -eq 1 ]; then
    #     # Repositório clonado com git clone --depth=1 --no-single-branch
    # fi

    printf "\033[33m[UPDATE-APP] ### Adicionando branch \"$BRANCH\" ao repositório\033[0m\n\n"

    git remote set-branches --add origin $BRANCH
    git fetch --depth 1 origin $BRANCH
fi

# git config --unset-all remote.origin.fetch
# git fetch origin --prune

printf "\n\033[32m[UPDATE-APP] >_ git fetch origin\033[0m\n\n"
git fetch origin $BRANCH

printf "\n\033[32m[UPDATE-APP] >_ git checkout $BRANCH\033[0m\n\n"
git checkout $BRANCH

printf "\n\033[33m[UPDATE-APP] ### Atualizando branch: >_ git pull origin $BRANCH --rebase\033[0m\n\n"
git pull origin $BRANCH --rebase 2>/dev/null || true

if [ "$(git ls-files -u | wc -l)" -gt 0 ] ; then
    echo
    printf "\033[31m[UPDATE-APP] ❌ >_ \`git pull --rebase\` Não pode ser completado com sucesso porque houve conflitos entre os seguinte arquivos:\033[0m\n\n"

    for file in $(git diff --name-only --diff-filter=U)
    do
        printf "\033[37m[UPDATE-APP] 📄 ${file}\033[0m\n"
    done

    echo
    printf "\033[31m[UPDATE-APP] ❌ Desfazendo >_ \`pull --rebase\` com >_ \`git rebase --abort\`\033[0m\n"

    git rebase --abort
    exit 1
fi

printf "\n\033[35m[UPDATE-APP] Git Branch \"$BRANCH\" atualizada com sucesso ✅\033[0m\n"

if [ ! -z "$NPM_COMMAND_RUN" ]; then
    printf "\n\033[32m[UPDATE-APP] Executando comando \"npm i\" + \"npm run $NPM_COMMAND_RUN\"\033[0m\n"

    npm i
    npm run $NPM_COMMAND_RUN
fi

readarray -t LARAVEL_CONTAINERS < <(docker ps -q --filter status=running --filter name="${LARAVEL_CONTAINER_NAME}" --no-trunc --format="{{.Names}}")

if [[ ${#LARAVEL_CONTAINERS[@]} -eq 0 ]]
then
    printf "\n\033[31m[UPDATE-APP] Nenhum container PHP/Laravel pôde ser encontrado ou possue um status diferente de \"running\" ❌\033[0m\n\n"

    exit 1
fi

for laravel_container_name in ${LARAVEL_CONTAINERS[@]}; do
    printf "\n\033[32m[UPDATE-APP] 🐳 Executando comandos Laravel no container \"$laravel_container_name\"\033[0m\n\n"

    laravel_migrate_status="php artisan migrate:status --ansi"
    laravel_run_migrations="#echo; ${laravel_migrate_status}; echo; php artisan migrate --force >/dev/null 2>&1 || true; echo; ${laravel_migrate_status}"

    if [[ $CONTAINER_LARAVEL_RUN_MIGRATION == true ]]; then
        # Remove first character
        laravel_run_migrations="${laravel_run_migrations:1}"
    fi

    cat <<EOF | docker exec --workdir ${LARAVEL_CONTAINER_WORKDIR} --interactive $laravel_container_name bash
echo; php artisan down

echo; composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader

$laravel_run_migrations

echo; php artisan storage:link 2>/dev/null || true

echo; php artisan route:clear
echo; php artisan route:cache

echo; php artisan config:clear
echo; php artisan config:cache

echo; php artisan clear-compiled

echo; php artisan view:clear
echo; php artisan view:cache
EOF

    echo

    if [[ $CONTAINER_RELOAD_PHPFPM == true ]]; then
        # Configuration reload
        printf "\n\033[32m[UPDATE-APP] 🐳 PHP-FPM Graceful reload of all workers + reload of fpm conf/binary\033[0m\n\n"

        # docker kill --signal "SIGUSR2" $laravel_container_name
        docker exec --workdir ${LARAVEL_CONTAINER_WORKDIR} --interactive $laravel_container_name kill -USR2 1 2>/dev/null || true
    fi

    # Up APP
    docker exec --workdir ${LARAVEL_CONTAINER_WORKDIR} --interactive $laravel_container_name /bin/bash -c "php artisan up;" 2>/dev/null || true

done

printf "\n\033[36m[UPDATE-APP] Script finalizado com sucesso em $(date +"%d/%m/%Y %T") 🚀\033[0m\n"

exit 0
