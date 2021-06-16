# -include services/nginx/.env.compose
# -include .env
# export

# Internal variables || Optional args
certs_path ?= $(DOCKER_NGINX_SERVICE_PATH)/certs
servers_path ?= $(DOCKER_NGINX_SERVICE_PATH)/servers
cert_name ?= app-certs

# Passing the >_ options option | Overwrite variable
options := $(DOCKER_COMPOSE_OPTIONS) $(DOCKER_COMPOSE_WEBSERVER_OPTIONS)

MAKE := @$(MAKE) -f Makefile -f services/nginx/Makefile

COMMAND_UP ?= $(shell jq '.docker.webserver' ${COMMANDS_JSON})

# docker-compose.yml Files
DOCKER_COMPOSE_NGINX = $(DOCKER_COMPOSE_EXEC) \
							-f services/nginx/docker-compose.yml \
							-f services/nginx/docker-compose.certs.yml

# $> make -f Makefile -f services/nginx/Makefile gen-certs email=certs@yourdomain.tld \
# 			manual=yes := For Manual DNS challenge (https://certbot.eff.org/docs/using.html#manual)
# 			webroot=yes := For Webroot challenge (https://certbot.eff.org/docs/using.html#webroot)
gen-certs:
	@echo
	@echo $(call message_info, Generate/Renew Certificates 🧾)
	@echo
	@mkdir -p ${certs_path}/challenges
	@mkdir -p ${certs_path}/certbot/etc/letsencrypt
	@mkdir -p ${certs_path}/certbot/var/lib/letsencrypt
	docker run \
		--name certbot-gen-certs \
		--rm \
		--interactive \
		--user ${current_uid} \
			-v "${certs_path}/certbot/etc/letsencrypt:/etc/letsencrypt" \
			-v "${certs_path}/certbot/var/lib/letsencrypt:/var/lib/letsencrypt" \
			-v "${certs_path}/challenges/:/var/www/certbot/" \
		${WEBSERVER_CERTBOT_IMAGE} \
			certonly \
				$(if $(manual),--manual,) \
				\
				$(if $(email),--email $(email) --eff-email,) \
				\
				$(if $(webroot),--webroot --webroot-path /var/www/certbot/,) \
				--domains $(domains) \
				--cert-name ${cert_name} \
				$(if $(preferred_challenge),--preferred-challenges $(preferred_challenge),) \
				\
				--renew-by-default \
				--agree-tos \
				\
				--rsa-key-size $(if $(rsa_key_size),$(rsa_key_size),4096) \
				--redirect \
				--staple-ocsp \
				--hsts \
				\
				$(if $(server),$(server),--server https://acme-v02.api.letsencrypt.org/directory) \
				$(if $(other_arguments),$(other_arguments),)
	@$(MAKE) --no-print-directory copy-certs cert_name=${cert_name}

# make -f Makefile -f services/nginx/Makefile \
#     gen-certs-cloudflare \
#         domains="yourdomain.tld,*.yourdomain.tld" \
#         email="certs@yourdomain.tld"
gen-certs-cloudflare:
	@echo
	@echo $(call message_info, Generate/Renew Cloudflare Certificates 🧾)
	@echo
	@mkdir -p ${certs_path}/certbot/etc/letsencrypt
	@mkdir -p ${certs_path}/certbot/var/lib/letsencrypt
	docker run \
		--name certbot-gen-cloudflare \
		--rm \
		--interactive \
		--user ${current_uid} \
			-v "${certs_path}/certbot/etc/letsencrypt:/etc/letsencrypt" \
			-v "${certs_path}/certbot/var/lib/letsencrypt:/var/lib/letsencrypt" \
			-v "${certs_path}/cloudflare.ini:/home/certbot/cloudflare.ini:ro" \
		${WEBSERVER_CERTBOT_CLOUDFLARE_IMAGE} \
			certonly \
				--dns-cloudflare \
				--dns-cloudflare-propagation-seconds 60 \
				--dns-cloudflare-credentials /home/certbot/cloudflare.ini \
				\
				--domains $(domains) \
				--cert-name ${cert_name} \
				--preferred-challenges dns-01 \
				\
				--agree-tos \
				$(if $(email),--email $(email),) \
				--no-eff-email \
				--renew-by-default \
				--rsa-key-size $(if $(rsa_key_size),$(rsa_key_size),4096) \
				\
				$(if $(server),$(server),--server https://acme-v02.api.letsencrypt.org/directory) \
				$(if $(other_arguments), $(other_arguments),)
	@$(MAKE) --no-print-directory copy-certs cert_name=${cert_name}
	@$(MAKE) --no-print-directory get-certs

# $> make -f Makefile -f services/nginx/Makefile copy-certs cert_name=app-certs
copy-certs:
	@echo
	@echo $(call message_info, Copying Let's Encrypt certificates 🧾)
	@echo
	cp -LRf ${certs_path}/certbot/etc/letsencrypt/live/${cert_name}/* ${certs_path}
# cp -LRf ${certs_path}/certbot/etc/letsencrypt/live/${cert_name}/fullchain.pem ${certs_path}/fullchain.pem
# cp -LRf ${certs_path}/certbot/etc/letsencrypt/live/${cert_name}/privkey.pem ${certs_path}/privkey.pem
# cp -LRf ${certs_path}/certbot/etc/letsencrypt/live/${cert_name}/chain.pem ${certs_path}/chain.pem
# cp -LRf ${certs_path}/certbot/etc/letsencrypt/live/${cert_name}/cert.pem ${certs_path}/cert.pem

get-certs:
	@echo
	@echo $(call message_info, Retrieve certificate information 🧾)
	@echo
	@docker run \
		-it --rm \
	-v "${certs_path}/certbot/etc/letsencrypt:/etc/letsencrypt" \
		--name certbot-certificates \
		certbot/certbot:v1.16.0 \
		certificates

# make -f Makefile -f services/nginx/Makefile docker-build-webserver
docker-build-webserver:
	@echo
	@echo $(call message_info, Build an image WEBSERVER 🏗)
	@echo
# @$(DOCKER_COMPOSE_EXEC) --file ./services/nginx/docker-compose.yml --ansi=auto --env-file .env build webserver
	docker build --progress=plain -t ${WEBSERVER_IMAGE} -f ./nginx/Dockerfile \
		--build-arg TAG_APP_IMAGE=${APP_IMAGE} \
		--build-arg APP_PATH_SRC=${APP_PATH_SRC} \
		--build-arg USER_UID=${USER_UID} \
		--build-arg USER_GID=${USER_GID} \
		--build-arg BUILD_DATE=$(shell date +'%Y-%m-%d') \
	./nginx

# make -f Makefile -f services/nginx/Makefile docker-pull-webserver
docker-pull-webserver:
	@echo
	@echo $(call message_info, Pull an image WEBSERVER 🏗)
	@echo
	@$(DOCKER_COMPOSE_NGINX) pull webserver

# make  -f Makefile \
		-f services/nginx/Makefile \
		docker-up-webserver \
		version=v1||v2||v3||v4... \
		scale=1||2||3||4... \
		up_options="--force-recreate" \
		services="webserver"
docker-up-webserver:
	@echo
	@echo $(call message_info, Docker UP WEBSERVER 🚀)
	@echo
# jq '.docker | has("webserver")' commands.json -> true || false
ifneq ($(COMMAND_UP), null)
	@eval $(COMMAND_UP)
	@echo
	@docker ps --filter name="$(COMPOSE_PROJECT_NAME)_webserver"
else
	$(DOCKER_COMPOSE_NGINX) \
		$(if $(options),$(options) $(common_options),$(common_options)) \
		up $(if $(up_options),$(up_options),--force-recreate --no-build --no-deps --detach) \
		--scale webserver=$(if $(scale),$(scale),$(if $(DOCKER_COMPOSE_WEBSERVER_SCALE),$(DOCKER_COMPOSE_WEBSERVER_SCALE),1)) \
		$(if $(services),$(services),webserver)
endif

# make -f Makefile -f services/nginx/Makefile docker-stop-webserver
docker-stop-webserver:
	@echo
	@echo $(call message_info, Stopping WEBSERVER gracefully ⚙️ ⏳)
	@echo
	$(DOCKER_COMPOSE_NGINX) stop
	@echo
	@echo $(call message_info, Removing WEBSERVER 🧹)
	@echo
	$(DOCKER_COMPOSE_NGINX) rm --stop --force -v
	@echo
	@echo $(call message_info, >_ docker volume prune 🧹)
	@echo
	@docker volume prune --force

# make -f Makefile -f services/nginx/Makefile docker-restart-webserver
docker-restart-webserver:
	@$(MAKE) --no-print-directory docker-stop-webserver
	@$(MAKE) --no-print-directory docker-up-webserver

# make -f Makefile -f services/nginx/Makefile allow-ip ip=YOUR_IP server=nginx-status
allow-ip:
	@echo $(call message_info, Permitindo IP NGINX)
ifneq ($(strip $(ip)),)
# @sed -i '0,/# allow.*/s//allow $(ip);/' ./services/nginx/servers/$(server).conf
	@sed -i '/^server {/a \ \ \ \ allow $(ip);' $(DOCKER_NGINX_SERVICE_PATH)/servers/$(server).conf
	@$(DOCKER_COMPOSE_NGINX) exec webserver nginx -s reload || true
	@echo $(call message_info, IP [$(ip)] Permitido ✅)
endif

# make -f Makefile -f services/nginx/Makefile remove-ip ip=YOUR_IP server=nginx-status
remove-ip:
	@echo $(call message_info, Removendo(allow) IP NGINX)
ifneq ($(strip $(ip)),)
# @sed -i '0,/allow $(ip);/s//# allow YOUR_IP;/' ./services/nginx/servers/$(server).conf
	@sed -i '/allow $(ip);/d' $(DOCKER_NGINX_SERVICE_PATH)/servers/$(server).conf
	@$(DOCKER_COMPOSE_NGINX) exec webserver nginx -s reload || true
	@echo $(call message_info, Removido IP [$(ip)] ❌)
endif
