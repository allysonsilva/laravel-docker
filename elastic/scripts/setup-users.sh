#!/bin/bash

set -euo pipefail

cacert=/usr/share/elasticsearch/config/certs/ca/ca.crt
# Wait for ca file to exist before we continue. If the ca file doesn't exist
# then something went wrong.
while [ ! -f $cacert ]
do
    sleep 2
done
ls -l $cacert

es_url=https://elastic:${ELASTIC_PASSWORD}@elasticsearch:9200
# Wait for Elasticsearch to start up before doing anything.
until curl -s --cacert $cacert $es_url -o /dev/null; do
    sleep 1
done

echo
echo 'Changing password for KIBANA ⚠️'
echo

# Set the password for the kibana user.
# REF: https://www.elastic.co/guide/en/x-pack/current/setting-up-authentication.html#set-built-in-user-passwords
until curl --cacert $cacert -s -H 'Content-Type:application/json' \
     -XPUT $es_url/_xpack/security/user/kibana/_password \
     -d "{\"password\": \"${ELASTIC_PASSWORD}\"}"
do
    sleep 2
    echo 'Retrying KIBANA...'
done

echo
echo '[KIBANA] Password changed successfully ✅'
echo

echo
echo 'Changing password for LOGSTASH ⚠️'
echo

until curl --cacert $cacert -s -H 'Content-Type:application/json' \
     -XPUT $es_url/_xpack/security/user/logstash_system/_password \
     -d "{\"password\": \"${ELASTIC_PASSWORD}\"}"
do
    sleep 2
    echo 'Retrying LOGSTASH...'
done

echo
echo '[LOGSTASH] Password changed successfully ✅'
echo
