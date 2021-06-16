# -include services/app/.env.compose
# -include .env
# export

# Passing the >_ options option | Overwrite variable
options := $(DOCKER_COMPOSE_OPTIONS) $(DOCKER_COMPOSE_APP_OPTIONS)

COMMAND_UP ?= $(shell jq '.docker.app' ${COMMANDS_JSON})

# Internal variables || Optional args
MAKE := @$(MAKE) -f Makefile -f services/app/Makefile

# docker-compose.yml Files
DOCKER_COMPOSE_APP = $(DOCKER_COMPOSE_EXEC) -f services/app/docker-compose.yml

# Handling environment variables
APP_LOCAL_FOLDER_SHELL := $(if $(APP_LOCAL_FOLDER_SHELL),$(APP_LOCAL_FOLDER_SHELL),$(ROOT_PATH)/$(APP_LOCAL_FOLDER))

# make -f Makefile -f services/app/Makefile composer-install
composer-install:
	@echo
	@echo $(call message_info, Installing PHP dependencies with Composer 🗂)
	@echo
	docker run \
		--rm \
		--tty \
		--interactive \
		--volume $(APP_LOCAL_FOLDER_SHELL):/app \
		--workdir /app \
		$(if $(options), $(options),) \
		composer:2.0 \
			install \
				--optimize-autoloader \
				--ignore-platform-reqs \
				--prefer-dist \
				--ansi \
				--no-dev \
				--no-interaction

# make -f Makefile -f services/app/Makefile npm-handle npm_command="npm run prod"
npm-handle:
	@echo
	@echo $(call message_info, Installing NPM dependencies with Node 🗂)
	@echo
	docker run \
		--rm \
		--interactive \
		--volume $(APP_LOCAL_FOLDER_SHELL):/usr/app \
		--workdir /usr/app \
		$(if $(options),$(options),) \
		node:16-alpine \
			/bin/sh -c "$(if $(npm_command),$(npm_command), npm i)"

# make -f Makefile -f services/app/Makefile docker-build-app
docker-build-app:
	@echo
	@echo $(call message_info, Build an image APP 🏗)
	@echo
# @$(DOCKER_COMPOSE_EXEC) --file ./services/app/docker-compose.yml --ansi=auto --env-file .env build app
	docker build --progress=plain -t ${APP_IMAGE} -f ./php/Dockerfile \
		--build-arg APP_ENV=production \
		--build-arg USER_UID=${USER_UID} \
		--build-arg USER_GID=${USER_GID} \
		--build-arg REMOTE_SRC=${APP_PATH_SRC} \
		--build-arg LOCAL_APP_FOLDER=${APP_LOCAL_FOLDER} \
		--build-arg LOCAL_DOCKER_FOLDER=${LOCAL_DOCKER_FOLDER} \
	./../

# make -f Makefile -f services/app/Makefile docker-pull-app
docker-pull-app:
	@echo
	@echo $(call message_info, Pull an image APP 🏗)
	@echo
	@$(DOCKER_COMPOSE_APP) pull app

# make  -f Makefile \
		-f services/app/Makefile \
		docker-up-app \
		version=v1||v2||v3||v4... \
		scale=1||2||3||4... \
		up_options="--force-recreate" \
		services="app"
docker-up-app:
	@echo
	@echo $(call message_info, Running Container APP 🚀)
	@echo
# jq '.docker | has("app")' commands.json -> true || false
ifneq ($(COMMAND_UP), null)
	@eval $(COMMAND_UP)
	@echo
	@docker ps --filter name="$(COMPOSE_PROJECT_NAME)_app"
else
	$(DOCKER_COMPOSE_APP) \
		$(if $(options),$(options) $(common_options),$(common_options)) \
		up $(if $(up_options),$(up_options),--force-recreate --no-build --no-deps --detach) \
		--scale app=$(if $(scale),$(scale),$(if $(DOCKER_COMPOSE_APP_SCALE),$(DOCKER_COMPOSE_APP_SCALE),1)) \
		$(if $(services),$(services),app)
endif
