# Sets the default goal to be used if no targets were specified on the command line
.DEFAULT_GOAL := help

# -include .env
# export

COMPOSE_PROJECT_NAME_SHELL := ${COMPOSE_PROJECT_NAME}
CONTAINER_VERSION_SHELL := ${CONTAINER_VERSION}

ifneq ("$(wildcard .env)","")
include .env
export
endif

# Internal variables || Optional args
root_path := $(shell dirname -- `pwd`)
docker_folder ?= ./docker

COMMANDS_JSON ?= commands.json

uname_OS := $(shell uname -s)
user_UID := $(shell id -u)
user_GID := $(shell id -g)
current_uid ?= "${user_UID}:${user_GID}"

ifeq ($(uname_OS),Darwin)
	user_UID := 1001
	user_GID := 1001
endif

# docker-compose.yml Files
DOCKER_COMPOSE_EXEC = docker-compose
DOCKER_COMPOSE = $(DOCKER_COMPOSE_EXEC) -f docker-compose.yml

# Handling environment variables
COMPOSE_PROJECT_NAME := $(if $(COMPOSE_PROJECT_NAME_SHELL),$(COMPOSE_PROJECT_NAME_SHELL),$(COMPOSE_PROJECT_NAME))

# Passing the >_ version option
version := $(if $(version),$(version),$(if $(CONTAINER_VERSION_SHELL),$(CONTAINER_VERSION_SHELL),$(CONTAINER_VERSION)))
# Changing the version prefix environment variable
CONTAINER_VERSION := $(version)

CONTAINER_NAME_PREFIX := $(if $(version),$(version),v0)_$(COMPOSE_PROJECT_NAME)

# Passing the >_ options option
options := $(if $(options),$(options),$(if $(DOCKER_COMPOSE_OPTIONS),$(DOCKER_COMPOSE_OPTIONS),))
# Passing the >_ up_options option
up_options := $(if $(up_options),$(up_options),--force-recreate --no-build --no-deps --detach)
# Passing the >_ common_options option
common_options := $(if $(common_options),$(common_options),--compatibility --project-name $(CONTAINER_NAME_PREFIX))

# Internal functions
define message_failure
	"\033[1;31m ❌$(1)\033[0m"
endef

define message_success
	"\033[1;32m ✅$(1)\033[0m"
endef

define message_info
	"\033[0;34m❕$(1)\033[0m"
endef

# make config-env docker_folder=./docker
config-env:
	@cp -n .env.example .env || true
	@sed -i "/^# PWD/c\PWD=$(shell pwd)" .env
	@sed -i "/^# DOCKER_PATH/c\DOCKER_PATH=$(shell pwd)" .env
# @sed -i "/^# ROOT_PATH/c\ROOT_PATH=$(shell dirname -- `pwd`)" .env
	@sed -i "/# ROOT_PATH=.*/c\ROOT_PATH=$(root_path)" .env
	@sed -i "/# USER_UID=.*/c\USER_UID=$(user_UID)" .env
	@sed -i "/# USER_GID=.*/c\USER_GID=$(user_GID)" .env
	@sed -i "/^# CURRENT_UID/c\CURRENT_UID=${current_uid}" .env
# @sed -i "/^LOCAL_DOCKER_FOLDER/c\LOCAL_DOCKER_FOLDER=${docker_folder}" .env
	@sed -i "/LOCAL_DOCKER_FOLDER=.*/c\LOCAL_DOCKER_FOLDER=${docker_folder}" .env
	@touch commands.json && echo "{\"docker\": {}}" > commands.json
	@echo $(call message_success, Run \`make config-env\` successfully executed)

docker-rmf:
	@echo
	@echo $(call message_info, Remove all containers 🗑)
	@echo
	@docker rm $$(docker ps --quiet --filter name="$(COMPOSE_PROJECT_NAME)") --force || true

docker-rmf-volumes:
	@echo
	@echo $(call message_info, Docker remove all volumes with [--force] 🧹)
	@echo
	@docker volume rm $$(docker volume ls --quiet --filter name="$(COMPOSE_PROJECT_NAME)") --force || true

docker-rmi-none:
	@echo
	@echo $(call message_info, Remove <none> images 🗑)
	@echo
	@docker rmi -f $$(docker images | grep "<none>" | awk "{print $$3}") || true

docker-prune:
	@echo
	@echo $(call message_info, Docker volume+network prune 🧹)
	@echo
	@docker volume prune --force && docker network prune --force

docker-clean:
	@echo $(call message_info, Docker prune images + volumes + network 🗑)
	@echo
	@$(MAKE) --no-print-directory docker-rmi-none
	@echo
	@$(MAKE) --no-print-directory docker-prune

# make  docker-up \
		context=FOLDER_IN_SERVICES \
		options=--verbose \
		version=v0||v1||v2||v100... \
		up_options="--force-recreate" \
		scale=1||2||3||4... service="service_to_scale" \
		services="services_in_docker_compose"
docker-up:
	@echo
	@echo $(call message_info, Docker UP Container SERVICE 🚀)
	@echo
	$(DOCKER_COMPOSE_EXEC) -f services/$(context)/docker-compose.yml \
		$(options) $(common_options) \
		up $(up_options) \
		$(if $(and $(scale), $(service)),--scale $(service)=$(scale)) $(if $(services),$(services),)

# NEWs ▼
