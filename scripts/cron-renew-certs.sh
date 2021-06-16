#!/bin/bash

set -e

if ! [ -x "$(command -v docker)" ]; then
    printf "\033[31m[CRON-RENEW-CERTS] ERROR: docker is not installed!\033[0m\n\n" >&2
    exit 1
fi

if ! [ -x "$(command -v docker-compose)" ]; then
    printf "\033[31m[CRON-RENEW-CERTS] ERROR: docker-compose is not installed!\033[0m\n\n" >&2
    exit 1
fi

printf "\n"
printf "\033[34m==================================================\033[0m\n"
printf "\033[34m============== [CRON-RENEW-CERTS] ===============\033[0m\n"
printf "\033[34m==================================================\033[0m\n\n"

usage()
{
    echo
    echo -e "Usage: \033[3m$0\033[0m [ -h|--help ] [ -t <string>|--timer <string> ]" 1>&2
    echo -e "\t\t\t\t      [ -p <string>|--path <string> ] [ -a|--add ] [ -r|--remove ]" 1>&2

    echo
    echo -e "\t\033[3;32m-h, -help,   --help\033[0m
                    Display help"

    echo
    echo -e "\t\033[3;32m-a, -add,    --add\033[0m
                    - Adiciona o agendamento da renovação automática dos certificados Let's Encrypt ao \033[1mCRON\033[0m!
                    - \033[3mAdicionado ao CRON apenas se não existir, caso exista, é ignorado!\033[0m"

    echo
    echo -e "\t\033[3;32m-r, -remove, --remove\033[0m
                    - Remove a linha do agendamento da renovação automática dos certificados SSL/Let's Encrypt do \033[1mCRON\033[0m!"

    echo
    echo -e "\t\033[3;32m-t, -timer,  --timer\033[0m
                    - Temporizador do agendamento das tarefas do \033[1mCRONTAB\033[0m
                    - Primeiro parâmetro do Cron Job dos arquivos do crontab!
                    \033[1mDefault\033[0m: \033[3;32m0 0 * * SAT\033[0m" # "At 00:00 on Saturday"

    echo
    echo -e "\t\033[3;32m-p, -path,  --path\033[0m
                    - Pasta onde se encontra este projeto docker
                    \033[1mDefault\033[0m: \033[3;32m/var/www/docker/\033[0m"

    echo
    echo -e "\t \033[1mExemplos:\033[0m"
    echo -e "\t     $0 --timer=\"* * * * *\" --path=/var/www/docker/ --add"
    echo -e "\t     $0 -timer=\"* * * * *\" -path=/var/www/docker/ -a"
    echo -e "\t     $0 -t\"* * * * *\" -p\"/var/www/docker/\" -add"
    echo -e "\t     $0 -remove -add"
    echo -e "\t     $0 --remove --add"
    echo -e "\t     $0 -r -a"
    echo -e "\t     $0 -ra"
    echo -e "\t     $0 --timer=\"* * * * *\" -r -a"

    exit 0
}

add()
{
    printf "\033[96m[CRON-RENEW-CERTS] Configurando/adicionando agendamento no CRONTAB 📄\033[0m\n\n"

    CRON_FILE=/var/spool/cron/crontabs/$USER
    LOG_FILE=/var/log/renew-certs.log

    [ ! -f $CRON_FILE ] && sudo touch $CRON_FILE
    [ ! -f $LOG_FILE ] && sudo touch $LOG_FILE; sudo chown $USER:$USER $LOG_FILE

    if ! sudo grep -q "renew-certs" $CRON_FILE; then
        # sudo systemctl enable cron
        sudo crontab -l -u $USER | { cat; echo "${TIMER} SHELL=/bin/bash PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin; cd ${DOCKER_PATH}; bash ./scripts/renew-certs.sh >> ${LOG_FILE} 2>&1"; } | sudo crontab -u ${USER} -

        printf "\033[3;32m[CRON-RENEW-CERTS] Comando/script no CRONTAB foi adicionado com sucesso 🚀 \033[0m\n\n"
    else
        printf "\033[3;33m[CRON-RENEW-CERTS] Comando/script no CRONTAB já foi adicionado ✅ \033[0m\n\n"
    fi
}

remove()
{
    sudo crontab -u $USER -l | grep -v 'renew-certs' | sudo crontab -u $USER -

    printf "\033[3;32m[CRON-RENEW-CERTS] Comando/script no CRONTAB foi removido com sucesso ✔︎\033[0m\n\n"
}

[ $# -eq 0 ] && usage

# [$@ Is all command line parameters passed to the script]
# --options is for short options like -v
# --longoptions is for long options with double dash like --version
# [The comma separates different long options]
# --alternative is for long options with single dash like -version
options=$(getopt --longoptions "help,timer::,path::,add,remove" --options "ht::p::ar" --alternative -- "$@")

if [ $? != 0 ] ; then echo -e "\n Terminating..." >&2 ; exit 1 ; fi

# set --:
# If no arguments follow this option, then the positional parameters are unset. Otherwise, the positional parameters
# are set to the arguments, even if some of them begin with a '-'
eval set -- "$options"

TIMER=${TIMER:-"0 0 * * SAT"}
DOCKER_PATH=${DOCKER_PATH:-"/var/www/docker/"}

# ADD | REMOVE
IS_ADD=${IS_ADD:-false}
IS_REMOVE=${IS_REMOVE:-false}
OTHER_ARGUMENTS=()

# @see https://stackoverflow.com/questions/16483119/an-example-of-how-to-use-getopts-in-bash
while true ; do
    case $1 in
        -h|--help)
            usage
            ;;
        -t|--timer)
            shift
            TIMER=$1
            ;;
        -p|--path)
            shift
            DOCKER_PATH=$1
            ;;
        -a|--add)
            IS_ADD=true
            ;;
        -r|--remove)
            IS_REMOVE=true
            ;;
        --) shift ; break ;;
        # *) echo "Internal error!" ; exit 1 ;;
    esac
    shift
done

echo

if [[ "$IS_REMOVE" == "true" ]]; then
    remove
fi

if [[ "$IS_ADD" == "true" ]]; then
    add
fi

exit 0
