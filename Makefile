# Makefile for Docker APP

# include .env

# Optional args
domain_app ?= app.com
app_path_prefix ?= /var/www
docker_folder_path ?= ./docker
remote_src ?= /var/www/app.com/
nginx_image_name ?= webserver:3.0
php_base_image_name ?= app:base
app_image_name ?= app:3.0
app_queue_image_name ?= app:queue
app_scheduler_image_name ?= app:scheduler
app_env__project_environment ?= production

uname_OS := $(shell uname -s)
user_UID := 1001
user_GID := 1002
ifeq ($(uname_OS),Linux)
	user_UID := $(shell id -u)
	user_GID := $(shell id -g)
endif

# # Detect operating system in Makefile
# OSFLAG:=
# ifeq ($(OS),Windows_NT)
# 	OSFLAG += -D WIN32
# 		ifeq ($(PROCESSOR_ARCHITEW6432),AMD64)
# 			OSFLAG += -D AMD64
# 		else
# 		ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)
# 			OSFLAG += -D AMD64
# 		endif
# 		ifeq ($(PROCESSOR_ARCHITECTURE),x86)
# 			OSFLAG += -D IA32
# 		endif
# 	endif
# else
# 	uname_s := $(shell uname -s)
# 	ifeq ($(uname_s),Linux)
# 		OSFLAG += -D LINUX
# 	endif
# 	ifeq ($(uname_s),Darwin)
# 		OSFLAG += -D OSX
# 	endif
# 	uname_p := $(shell uname -p)
# 	ifeq ($(uname_p),x86_64)
# 		OSFLAG += -D AMD64
# 	endif
# 	ifneq ($(filter %86,$(uname_p)),)
# 		OSFLAG += -D IA32
# 	endif
# 	ifneq ($(filter arm%,$(uname_p)),)
# 		OSFLAG += -D ARM
# 	endif
# endif

help:
	@echo ""
	@echo "usage: make COMMAND"
	@echo ""
	@echo "Commands:"
	@echo "  pull                Download images"
	@echo "  build               Build project images"
	@echo "  build-nginx         Build the NGINX image to act as a reverse proxy"
	@echo "  run-nginx           Create a container for the webserver with docker run"
	@echo "  in-nginx            Access the NGINX container"
	@echo "  build-php           Build the base image of projects in PHP"
	@echo "  build-full-php      Build the base image of projects in PHP with all extensions and components enabled by default"
	@echo "  build-app           Build the image with settings for Laravel/PHP projects"
	@echo "  run-app             Create a container for the application with docker run"
	@echo "  build-queue         Build the image to act as queue management. Extends the default project image (build-app)"
	@echo "  build-scheduler     Build the image to act as scheduler management. Extends the default project image (build-app)"
	@echo "  app-code-phpcs      Check the APP with PHP Code Sniffer (PSR2)"
	@echo "  app-code-phpmd      Analyse the APP with PHP Mess Detector"
	@echo "  docker-clean        Remove docker images with filter <none>"
	@echo "  docker-stop         Stop and execute $$> make docker-clean"
	@echo "  composer-up         Update PHP dependencies with composer"
	@echo "  gen-certs           Generate SSL certificates"
	@echo "  get-certs           Retrieves certificate expiration dates"
	@echo "  mysql-dump          Create backup of all databases"
	@echo "  mysql-restore       Restore backup of all databases"

pull:
	docker pull composer:1.8
	docker pull node:11-alpine
	docker pull nginx:1.15
	docker pull mysql:5.7
	docker pull mongo:4.1
	docker pull php:7.3-fpm
	docker pull redis:5-alpine
	docker pull traefik:1.7-alpine
	docker pull containous/whoami:latest

build:
	make build-php
	make build-nginx
	make build-app
	make build-queue
	make build-scheduler

# $> make build-nginx nginx_image_name=webserver:3.0 domain_app=mydomain.com
build-nginx:
	docker build -t ${nginx_image_name} -f ./nginx/Dockerfile \
		--build-arg DOMAIN_APP=${domain_app} \
		--build-arg APP_PATH_PREFIX=${app_path_prefix} \
		--build-arg TAG_APP_IMAGE=${app_image_name} \
		--build-arg BUILD_DATE=$(shell date +'%Y-%m-%d') \
		--build-arg VCS_REF=3.0 \
	./nginx

run-nginx:
	docker run \
			--rm \
			-p 80:80 \
			-p 443:443 \
		-v $(shell pwd)/../:${remote_src} \
		-v $(shell pwd)/nginx/docker-entrypoint.sh:/entrypoint.sh:ro \
				--env "DOMAIN_APP=${domain_app}" \
				--env "APP_PATH_PREFIX=${app_path_prefix}" \
			--workdir ${remote_src} \
			--name=webserver \
			--hostname=webserver \
			-t ${nginx_image_name}

in-nginx:
	docker exec -ti webserver bash

# $> make build-php php_base_image_name=app:base
build-php:
	docker build -t ${php_base_image_name} \
		--build-arg DEFAULT_USER=app \
		--build-arg DEFAULT_USER_UID=${user_UID} \
		--build-arg DEFAULT_USER_GID=${user_GID} \
	- < ./php/Dockerfile

build-full-php:
	docker build -t app:base \
		--build-arg DEFAULT_USER=app \
		--build-arg DEFAULT_USER_UID=${user_UID} \
		--build-arg DEFAULT_USER_GID=${user_GID} \
		--build-arg INSTALL_PHP_AMQP=true \
		--build-arg INSTALL_PHP_SWOOLE=true \
		--build-arg INSTALL_PHP_MONGO=true \
		--build-arg INSTALL_PHP_SQLSRV=true \
		--build-arg INSTALL_PHP_IGBINARY=true \
		--build-arg INSTALL_PHP_LZF=true \
		--build-arg INSTALL_PHP_MESSAGEPACK=true \
		--build-arg INSTALL_PHP_REDIS=true \
		--build-arg INSTALL_PHP_DS=true \
		--build-arg INSTALL_PHP_XDEBUG=true \
	- < ./php/Dockerfile

# $> make build-app app_env__project_environment=production||development app_image_name=app:3.0 domain_app=mydomain.com
build-app:
	docker build -t ${app_image_name} -f ./app/Dockerfile \
		--build-arg DOMAIN_APP=${domain_app} \
		--build-arg APP_PATH_PREFIX=${app_path_prefix} \
		--build-arg PHP_BASE_IMAGE=${php_base_image_name} \
		--build-arg APP_ENV=${app_env__project_environment} \
		--build-arg DOCKER_FOLDER_PATH=${docker_folder_path} \
		--build-arg PROJECT_ENVIRONMENT=${app_env__project_environment} \
	./../

# $> php artisan serve --port=8080 --host=0.0.0.0
run-app:
	docker run \
			--rm \
			-p 9001:9001 \
			-p 8081:8080 \
		-v $(shell pwd)/../:${remote_src} \
		-v $(shell pwd)/app/docker-entrypoint.sh:/entrypoint.sh:ro \
				--env "REMOTE_SRC=${remote_src}" \
				--env "APP_KEY=SomeRandomString" \
				--env "PROJECT_ENVIRONMENT=${app_env__project_environment}" \
				--env "APP_ENV=${app_env__project_environment}" \
				--env "APP_DEBUG=true" \
				--env "DB_CONNECTION=mysql" \
				--env "DB_HOST=database" \
				--env "DB_PORT=3306" \
				--env "DB_DATABASE=app" \
				--env "DB_USERNAME=root" \
				--env "DB_PASSWORD=5?qqSm3_@mqrJ_" \
				--env "REDIS_HOST=redis" \
				--env "REDIS_PASSWORD=HQD3{9S-u(qnxK@" \
				--env "REDIS_PORT=6379" \
				--env "REDIS_QUEUE=queue_default" \
				--env "BROADCAST_DRIVER=redis" \
				--env "CACHE_DRIVER=redis" \
				--env "QUEUE_CONNECTION=redis" \
				--env "SESSION_DRIVER=redis" \
			--user ${user_UID}:${user_GID} \
			--workdir ${remote_src} \
			--name=php-fpm \
			--hostname=php-fpm \
			-t ${app_image_name}

build-queue:
	docker build -t ${app_queue_image_name} -f ./queue/Dockerfile --build-arg APP_IMAGE=${app_image_name} ./../

build-scheduler:
	docker build -t ${app_scheduler_image_name} -f ./scheduler/Dockerfile --build-arg APP_IMAGE=${app_image_name} ./../

app-code-phpcs:
	@echo "Checking the standard code..."
	@docker exec -t app ./vendor/bin/phpcs -v --extensions=php --tab-width=4 --standard=PSR2 ./app

app-code-phpmd:
	@echo "PHPMD - PHP Mess Detector"
	@docker exec -t app ./vendor/bin/phpmd ./app text cleancode,codesize,controversial,design,naming,unusedcode

docker-clean:
	@docker rmi -f $(shell docker images | grep "<none>" | awk "{print \$$3}")

composer-up:
	@docker run \
			--rm \
			--name=composer-up \
			--interactive --tty \
			--volume $(shell pwd)/../:/app \
			--user ${user_UID}:${user_GID} \
			composer:1.8 update

docker-stop:
	@docker-compose down -v
	@make docker-clean

# $> make gen-certs domain_app=mydomain.com
gen-certs:
	@docker run \
			--name certbot \
			-it --rm \
		-v "$(shell pwd)/nginx/certs/etc/letsencrypt:/etc/letsencrypt" \
		-v "$(shell pwd)/nginx/certs/var/lib/letsencrypt:/var/lib/letsencrypt" \
			certbot/certbot \
				certonly \
					--manual \
					--manual-public-ip-logging-ok \
					--eff-email \
					-d "*.${domain_app}" -d ${domain_app} \
					--agree-tos \
					--cert-name ${domain_app} \
					--preferred-challenges dns-01 \
					--server https://acme-v02.api.letsencrypt.org/directory \
					--email support@${domain_app} \
					--rsa-key-size 4096 \
					--no-bootstrap

get-certs:
	@docker run \
			-it --rm \
		-v "$(shell pwd)/nginx/certs/etc/letsencrypt:/etc/letsencrypt" \
		-v "$(shell pwd)/nginx/certs/var/lib/letsencrypt:/var/lib/letsencrypt" \
			--name certbot-certificates \
			certbot/certbot \
			certificates

mysql-dump:
	@docker exec $(shell docker-compose ps -q database) mysqldump --all-databases -u"$(MYSQL_ROOT_USER)" -p"$(MYSQL_ROOT_PASSWORD)" > ./../db-dumps/db.sql 2>/dev/null

mysql-restore:
	@docker exec -i $(shell docker-compose ps -q database) mysql -u"$(MYSQL_ROOT_USER)" -p"$(MYSQL_ROOT_PASSWORD)" < ./../db-dumps/db.sql 2>/dev/null
