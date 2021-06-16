#!/bin/bash

wget https://www.cloudflare.com/ips-v4 -O ips-v4
wget https://www.cloudflare.com/ips-v6 -O ips-v6

# Allow all traffic from Cloudflare IPs (Restrict to ports 80 & 443)
for cfip in `cat ips-v4`; do ufw allow proto tcp from $cfip to any port 80,443 comment 'Cloudflare IP'; done
for cfip in `cat ips-v6`; do ufw allow proto tcp from $cfip to any port 80,443 comment 'Cloudflare IP'; done

ufw reload > /dev/null
