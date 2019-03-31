#/bin/ash

confdir="${PWD}/config"
chown 1000 -R "$confdir"
find "$confdir" -type f -name "*.keystore" -exec chmod go-wrx {} \;
find "$confdir" -type f -name "*.yml" -exec chmod go-wrx {} \;

if [ -f "$confdir/elasticsearch/elasticsearch.keystore" ]; then
    rm "$confdir/elasticsearch/elasticsearch.keystore"
fi

PW=$(openssl rand -base64 16;)

ELASTIC_PASSWORD="${ELASTIC_PASSWORD:-$PW}"
export ELASTIC_PASSWORD

# SETUP [ELASTICSEARCH]
docker-compose -f docker-compose.yml -f ./setups/docker-compose.setup.elasticsearch.yml up setup_elasticsearch

# SETUP [KIBANA]
docker-compose -f docker-compose.yml -f ./setups/docker-compose.setup.kibana.yml up setup_kibana

# SETUP [LOGSTASH]
docker-compose -f docker-compose.yml -f ./setups/docker-compose.setup.logstash.yml up setup_logstash

# SETUP [BEATS]
docker-compose -f docker-compose.yml -f ./setups/docker-compose.setup.beats.yml up setup_filebeat setup_metricbeat setup_packetbeat

printf "Setup completed successfully. To start the stack please run:\n\t docker-compose up -d\n"
printf "\nIf you wish to remove the setup containers please run:\n\tdocker-compose -f docker-compose.yml -f docker-compose.setup.yml down --remove-orphans\n"
printf "\nYou will have to re-start the stack after removing setup containers.\n"
printf "\nYour 'elastic' user password is: $ELASTIC_PASSWORD\n"
