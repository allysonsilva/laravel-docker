#!/bin/bash

# SERVER_HOSTNAME=(redis|mysql|mongo...).yourdomain.tld ./self-signed-SSL.sh

# This will cause the script to exit on the first error
set -e

# @see https://blog.devolutions.net/2020/07/tutorial-how-to-generate-secure-self-signed-server-and-client-certificates-with-openssl
# @see https://www.scottbrady91.com/OpenSSL/Creating-Elliptical-Curve-Keys-using-OpenSSL

# ./scripts/self-signed-SSL.sh --service=mongodb --cert-ca-pass=keypassword --cert-server-pass=keypassword --cert-server-host="mongodb.yourdomain.tld"
# ./scripts/self-signed-SSL.sh --service=redis --cert-ca-pass=keypassword --cert-server-pass=keypassword --with-dhparam
# ./scripts/self-signed-SSL.sh --service=mysql

printf "\n"
printf "\033[36m=================================================\033[0m\n"
printf "\033[36m============== [SELF-SIGNED-SSH] ================\033[0m\n"
printf "\033[36m=================================================\033[0m\n\n"

options=$(getopt --longoptions "service:,cert-ca-pass:,cert-server-pass:,cert-server-host::,with-dhparam::" --options "" --alternative -- "$@")

if [ $? != 0 ] ; then echo -e "\n Terminating..." >&2 ; exit 1 ; fi

eval set -- "$options"

if [[ -z "$1" || "$1" == "--" ]] ; then
    printf "\033[31m[ ERROR: ] No arguments supplied!\033[0m\n" >&2
    printf "\033[31m[ ERROR: ] Please call '$0 <argument>' to run this command!\033[0m\n" >&2

    exit 1
fi

SERVICE=${SERVICE:-}
CERT_CA_KEY_PASSWORD=${CERT_CA_KEY_PASSWORD:-}
CERT_SERVER_KEY_PASSWORD=${CERT_SERVER_KEY_PASSWORD:-}
SERVER_HOSTNAME=${SERVER_HOSTNAME:-}
WITH_DHPARAM=${WITH_DHPARAM:-false}
COMMON_SUBJECT=${COMMON_SUBJECT:-"/C=BR/ST=State/L=Locality/O=Organization Name"}
OTHER_ARGUMENTS=()

while true ; do
    case $1 in
        --service) shift; SERVICE="$1" ;;
        --cert-ca-pass) shift; CERT_CA_KEY_PASSWORD="$1" ;;
        --cert-server-pass) shift; CERT_SERVER_KEY_PASSWORD="$1" ;;
        --cert-server-host) shift; SERVER_HOSTNAME=$1 ;;
        --with-dhparam) shift; WITH_DHPARAM=true ;;
        --) shift ; break ;;
        *) shift;  OTHER_ARGUMENTS+=("$1") ;;
    esac
    shift
done

if [ -z "$SERVICE" ]; then
    printf "\033[31m[ ERROR: ] A opção --service deve ser obrigatória na execução desse script!\033[0m\n" >&2

    exit 1
fi

export DNS_ADDRESS=${SERVER_HOSTNAME:-$(hostname)}
export DIR_SSL_SERVICE="`cd $(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd -P)/../services/${SERVICE}/ssl; pwd`"

if [ "$(uname -s)" == "Darwin" ]; then
    export IP_ADDRESS=$(ifconfig en0 | awk '/inet / {print $2; }')
else
    # [[ -z "$SERVER_HOSTNAME" ]] && export DNS_ADDRESS=$(hostname --domain)

    export IP_ADDRESS=$(hostname -I | awk '{print $1}')
fi

# Create clean environment
rm -rf newcerts
mkdir newcerts && cd newcerts

# Server and client certificates must differ in the organization part of the Distinguished Names,
# or in another word and must differ at least in one of the O, OU, or DC values.

# #####################
# Create CA certificate
# #####################

# Generate the Certificate Authority Certificate | Generate a private key for a curve
#
#  password provided from the command-line: -pass pass:keypassword
#  password provided from the specific file: -pass file:/home/milosz/.pkey_pass
#  password provided from the environment variable: -pass env:pkey_pass
#  password provided from standard input: -pass stdin
if [ ! -z "$CERT_CA_KEY_PASSWORD" ]; then
    echo $CERT_CA_KEY_PASSWORD | openssl genpkey -aes256 -algorithm EC -pkeyopt ec_paramgen_curve:secp521r1 -out ca-key.pem -pass stdin

    CERT_CA_KEY_PASSWORD_PARAMETER="-passin pass:$CERT_CA_KEY_PASSWORD"
else
    openssl ecparam -name secp521r1 -genkey -noout -out ca-key.pem
fi
#
# Print the key
# $> openssl ec -in ca-key.pem -noout -text $CERT_CA_KEY_PASSWORD_PARAMETER
# $> openssl pkey -in ca-key.pem -text $CERT_CA_KEY_PASSWORD_PARAMETER

# Generate the Certificate Authority Certificate
set -x
openssl req -new -x509 -sha256 -days 1024 -nodes \
        -key ca-key.pem -out ca.pem \
        ${CERT_CA_KEY_PASSWORD_PARAMETER} \
        -subj "${COMMON_SUBJECT}/OU=authority/CN=Prod CA Certificate"
{ set +x; } 2>/dev/null
#
# Print the certificate in text form
# $> openssl x509 -in ca.pem -noout -text

echo

# ##################
# SERVER Certificate
# ##################

# Generate the Server Certificate Private Key
if [ ! -z "$CERT_SERVER_KEY_PASSWORD" ]; then
    openssl genpkey -aes256 -algorithm EC -pkeyopt ec_paramgen_curve:secp521r1 -out server-key.pem -pass pass:${CERT_SERVER_KEY_PASSWORD}
    # OR $> openssl ecparam -genkey -name secp521r1 | openssl ec -aes256 -out server-key.pem -passout pass:${CERT_SERVER_KEY_PASSWORD}

    CERT_SERVER_KEY_PASSWORD_PARAMETER="-passin pass:$CERT_SERVER_KEY_PASSWORD"
else
    openssl ecparam -name secp521r1 -genkey -noout -out server-key.pem
fi

# On the technical side, the SAN extension was introduced to integrate the common name.
# Since HTTPS was first introduced in 2000 (and defined by the RFC 2818), the use of the
# commonName field has been considered deprecated, because it’s ambiguous and untyped.
#
# The CA/Browser Forum has since mandated that the SAN would also include any value present in the common name,
# effectively making the SAN the only required reference for a certificate match with the server name.
# The notion of the common name survives mostly as a legacy of the past.
# There are active discussions to remove its use from most browsers and interfaces.
#
# Update: as per RFC 6125, published in 2011, the validator must check SAN first, and if SAN exists, then CN should not be checked.
#
# @see https://stackoverflow.com/questions/5935369/how-do-common-names-cn-and-subject-alternative-names-san-work-together
#
# ! IMPORTANT: The value of the `--host` parameter in the `mongo` command/client must match some DNS/SAN value of the variable below. Otherwise, insert error of:
# *            - connection attempt failed: SSLHandshakeFailed: The server certificate does not match the host name.
set -x
SUBJECT_ALTERNATIVE_NAME="subjectAltName=DNS:${DNS_ADDRESS},DNS:localhost,IP:${IP_ADDRESS}"

# Generate the Server Certificate Signing Request
openssl req -new -sha256 -nodes \
        -key server-key.pem -out server.csr \
        $CERT_SERVER_KEY_PASSWORD_PARAMETER \
        -subj "${COMMON_SUBJECT}/OU=server/CN=`hostname`" \
        -addext "$SUBJECT_ALTERNATIVE_NAME"

# Generate the Server Certificate
openssl x509 -req -sha256 -days 500 \
        -in server.csr \
        -CA ca.pem \
        -CAkey ca-key.pem -CAcreateserial \
        $CERT_CA_KEY_PASSWORD_PARAMETER \
        -out server-cert.pem \
        -extfile <(printf "\n[SAN]\n$SUBJECT_ALTERNATIVE_NAME") -ext SAN -extensions SAN
{ set +x; } 2>/dev/null
# echo
# openssl x509 -text -in server-cert.pem -noout
# echo
# openssl req -in server.csr -noout -text

echo

# ##################
# CLIENT Certificate
# ##################

set -x
# Generate the Client Certificate Private Key
openssl ecparam -name secp521r1 -genkey -noout -out client-key.pem

# Create the Client Certificate Signing Request
openssl req -new -sha256 -nodes \
        -key client-key.pem -out client.csr \
        -subj "${COMMON_SUBJECT}/OU=client/CN=Client Certificate"

# Generate the Client Certificate
openssl x509 -req -sha256 -days 500 \
        -in client.csr \
        -CA ca.pem \
        -CAkey ca-key.pem -CAcreateserial \
        $CERT_CA_KEY_PASSWORD_PARAMETER \
        -out client-cert.pem

if [[ "${WITH_DHPARAM:-false}" == true ]]; then
    echo
    openssl dhparam -out dhparam.pem 4096
fi
{ set +x; } 2>/dev/null

echo

if [[ "$SERVICE" == "mongodb" ]]; then
    # Concat each Node Certificate with its key
    cat server-key.pem server-cert.pem > server.pem
    cat client-key.pem client-cert.pem > client.pem
fi

openssl verify -CAfile ca.pem server-cert.pem client-cert.pem

echo

chmod 644 server* client*

mv -f -v *.pem ${DIR_SSL_SERVICE}
rm -rf server* client* ca*

# openssl x509 -text -in ca.pem
# openssl x509 -text -in server-cert.pem
# openssl x509 -text -in client-cert.pem
# openssl x509 -in server.pem -text -noout
# openssl x509 -in client.pem -text -noout

printf "\n\e[42;3;30m[SELF-SIGNED-SSH] Successfully generated SSL files 📄\e[0m\n\n"

exit 0
