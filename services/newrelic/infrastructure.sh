#!/bin/bash

set -e

printf "\n"
printf "\033[34m===============================================\033[0m\n"
printf "\033[34m============== [NEW RELIC INFRA] ==============\033[0m\n"
printf "\033[34m===============================================\033[0m\n"

echo

# Create a configuration file and add your license key
{ \
    echo 'license_key: YOUR_LICENSE_KEY'; \
    echo 'display_name: "Company Infra PROD"'; \
} | sudo tee -a /etc/newrelic-infra.yml

# Add the New Relic Infrastructure Agent gpg key \
curl -s https://download.newrelic.com/infrastructure_agent/gpg/newrelic-infra.gpg | sudo apt-key add - && \
\
# Create the agent’s yum repository \
printf "deb [arch=amd64] https://download.newrelic.com/infrastructure_agent/linux/apt focal main" | sudo tee -a /etc/apt/sources.list.d/newrelic-infra.list && \
\
# Update your apt cache \
sudo apt-get update && \
\
# Run the installation script \
sudo apt-get install newrelic-infra -y

echo

printf "\033[36m[NEW RELIC INFRA] Script finalizado com sucesso 🚀\033[0m\n"

exit 0
