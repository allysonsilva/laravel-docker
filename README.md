<h1 align="center">
    <br>
    <a href="https://laravel.com/"><img src="assets/laravel.svg" alt="Laravel" width="100"></a>
    &nbsp;&nbsp;
    <a href="https://www.docker.com/"><img src="assets/docker.svg" alt="Docker" width="100"></>
    &nbsp;
    <a href="https://doc.traefik.io/traefik/"><img src="assets/traefik.svg" alt="traefik proxuy" width="100"></a>
    <br>
        Laravel Dockerized
    <br>
</h1>

> <h4 align="center">Use this repository to get started with developing your Laravel application in a Docker container.</h4>

This is a personal collection of Docker images and services(**Nginx**, **PHP-FPM**, **Traefik**, **Authelia**, **Netdata**, **New Relic**, **Portainer**, **MySQL**, **Redis**, **MongoDB**, **Queue**, **Scheduler**, and **GoAccess**) for applications in <a href="https://laravel.com/" target="_blank">Laravel</a>.

## Overview

- [Getting Started](#getting-started)
  - [Organization](#organization)
  - [Initial setup / clone the project](#initial-setup--clone-the-project)
  - [Build the image of the Laravel/APP PHP-FPM application](#build-the-image-of-the-laravelapp-php-fpm-application)
  - [Build the NGINX/Webserver image](#build-the-nginxwebserver-image)
  - [Create Let’s Encrypt certificates](#create-lets-encrypt-certificates)
    - [Generating with DNS challenge](#generating-with-dns-challenge)
  - [Before up the application](#before-up-the-application)
    - [Create the default container networks](#create-the-default-container-networks)
  - [UP APP Application + NGINX/Webserver](#up-app-application--nginxwebserver)
    - [APP/Laravel with New Relic](#applaravel-with-new-relic)
    - [NGINX/Webserver with GeoIP2](#nginxwebserver-with-geoip2)
- [Run Containers](#run-containers)
  - [Run Redis Container](#run-redis-container)
  - [Run Authelia Container](#run-authelia-container)
  - [Run Netdata Container](#run-netdata-container)
  - [Run MongoDB Container](#run-mongodb-container)
  - [Run MySQL Container](#run-mysql-container)
  - [Run Portainer Container](#run-portainer-container)
  - [Run Queue/Scheduler Container](#run-queuescheduler-container)
  - [Run GoAccess Container](#run-goaccess-container)
- [Makefile Commands](#makefile-commands)
- [Scripts](#scripts)
  - [`./scripts/cron-renew-certs.sh`](#scriptscron-renew-certssh)
  - [`./scripts/deploy-version.sh`](#scriptsdeploy-versionsh)
  - [`./scripts/loadbalancer-nginx.sh`](#scriptsloadbalancer-nginxsh)
  - [`./scripts/update-app.sh`](#scriptsupdate-appsh)
- [Setup Auto-Renew Let's Encrypt SSL Certificates](#setup-auto-renew-lets-encrypt-ssl-certificates)
  - [Generate SSL certificates manually](#generate-ssl-certificates-manually)
    - [Configure `renew.env` to generate certificates via HTTP challenge](#configure-renewenv-to-generate-certificates-via-http-challenge)
    - [Configure `renew.env` to generate certificates via DNS challenge](#configure-renewenv-to-generate-certificates-via-dns-challenge)
    - [Configure `renew.env` to generate the certificates via the DNS plugin certbot-dns-cloudflare](#configure-renewenv-to-generate-the-certificates-via-the-dns-plugin-certbot-dns-cloudflare)
  - [Configure CRON to automatically generate SSL certificates](#configure-cron-to-automatically-generate-ssl-certificates)

## Project Structure/Tree

```bash
tree --sort=name --dirsfirst -a -I ".git|.DS_Store"
```

```
.
├── nginx
│   ├── configs
│   │   ├── addon.d
│   │   │   └── 10-realip.conf
│   │   ├── nginx.d
│   │   │   ├── 10-deny-ips.conf
│   │   │   ├── 10-security-headers.conf
│   │   │   ├── 20-gzip-compression.conf
│   │   │   ├── 20-open-file-descriptors.conf
│   │   │   ├── 30-buffers.conf
│   │   │   ├── 40-logs.conf
│   │   │   ├── 50-timeouts.conf
│   │   │   ├── 60-misc.conf
│   │   │   └── 70-proxy.conf
│   │   ├── snippets
│   │   │   ├── cache-static.conf
│   │   │   ├── deny.conf
│   │   │   ├── http-to-https-non-www.conf
│   │   │   ├── no-caching.conf
│   │   │   ├── php-fpm-common.conf
│   │   │   ├── php-fpm.conf
│   │   │   ├── resolver-docker.conf
│   │   │   ├── resolver-global.conf
│   │   │   ├── ssl-certificates.conf
│   │   │   ├── ssl.conf
│   │   │   └── www-to-non-www.conf
│   │   ├── .gitignore
│   │   ├── fastcgi.conf
│   │   ├── mime.types
│   │   └── nginx.conf
│   ├── geoip2
│   │   └── cronjob
│   ├── logrotate
│   │   ├── conf.d
│   │   │   └── nginx
│   │   ├── cronjob
│   │   └── logrotate.conf
│   ├── .dockerignore
│   ├── Dockerfile
│   ├── DockerfileCertbot
│   └── docker-entrypoint.sh
├── php
│   ├── configs
│   │   ├── conf.d
│   │   │   ├── opcache.ini
│   │   │   └── xdebug.ini
│   │   ├── fpm
│   │   │   ├── pools
│   │   │   │   └── www.conf
│   │   │   └── global.conf
│   │   ├── php-local.ini
│   │   └── php-production.ini
│   ├── logrotate
│   │   ├── conf.d
│   │   │   ├── php
│   │   │   ├── php-fpm
│   │   │   └── storage-app
│   │   ├── cronjob
│   │   └── logrotate.conf
│   ├── queue
│   │   ├── templates
│   │   │   ├── laravel-horizon.conf.tpl
│   │   │   └── laravel-worker.conf.tpl
│   │   └── supervisord.conf
│   ├── vscode
│   │   └── launch.json
│   ├── Dockerfile
│   └── docker-entrypoint.sh
├── scripts
│   ├── envs
│   │   ├── deploy.env
│   │   ├── docker.env
│   │   └── renew.env
│   ├── cloudflare-ips-ufw.sh
│   ├── cron-renew-certs.sh
│   ├── deploy-version.sh
│   ├── loadbalancer-nginx.sh
│   ├── renew-certs.sh
│   ├── self-signed-SSL.sh
│   └── update-app.sh
├── services
│   ├── app
│   │   ├── .env.compose
│   │   ├── .env.container
│   │   ├── Makefile
│   │   ├── docker-compose.webserver.yml
│   │   └── docker-compose.yml
│   ├── authelia
│   │   ├── configs
│   │   │   ├── .gitignore
│   │   │   ├── configuration.yml
│   │   │   └── users.yml
│   │   ├── data
│   │   │   └── .gitignore
│   │   ├── secrets
│   │   │   ├── jwt
│   │   │   ├── redis
│   │   │   └── session
│   │   └── docker-compose.yml
│   ├── goaccess
│   │   ├── html
│   │   │   └── .gitignore
│   │   ├── .env.compose
│   │   ├── docker-compose.webserver.yml
│   │   ├── docker-compose.yml
│   │   ├── entrypoint.sh
│   │   └── goaccess.conf
│   ├── mongodb
│   │   ├── ssl
│   │   │   └── .gitignore
│   │   ├── .env.container
│   │   ├── docker-compose.yml
│   │   └── mongod.conf
│   ├── mysql
│   │   ├── ssl
│   │   │   └── .gitignore
│   │   ├── .env.container
│   │   ├── docker-compose.yml
│   │   └── my.cnf
│   ├── netdata
│   │   ├── configs
│   │   │   ├── alarms
│   │   │   │   ├── cgroups.conf
│   │   │   │   ├── cpu.conf
│   │   │   │   ├── mysql.conf
│   │   │   │   ├── nginx.conf
│   │   │   │   ├── phpfpm.conf
│   │   │   │   ├── ram.conf
│   │   │   │   └── web_log.conf
│   │   │   ├── modules
│   │   │   │   └── go.d
│   │   │   │       ├── mysql.conf
│   │   │   │       ├── nginx.conf
│   │   │   │       ├── phpfpm.conf
│   │   │   │       ├── prometheus.conf
│   │   │   │       ├── redis.conf
│   │   │   │       └── web_log.conf
│   │   │   ├── orchestrators
│   │   │   │   └── go.d.conf
│   │   │   ├── health.conf
│   │   │   └── netdata.conf
│   │   └── docker-compose.yml
│   ├── newrelic
│   │   ├── docker-compose.yml
│   │   └── infrastructure.sh
│   ├── nginx
│   │   ├── certs
│   │   │   └── .gitignore
│   │   ├── servers
│   │   │   ├── additional
│   │   │   │   └── goaccess.conf
│   │   │   ├── shared
│   │   │   │   └── letsencrypt.conf
│   │   │   ├── templates
│   │   │   │   ├── app.conf.tpl
│   │   │   │   └── spa.conf.tpl
│   │   │   ├── app.conf
│   │   │   ├── healthcheck.conf
│   │   │   ├── nginx-status.conf
│   │   │   └── phpfpm-status.conf
│   │   ├── .env.compose
│   │   ├── .env.container
│   │   ├── Makefile
│   │   ├── docker-compose.certs.yml
│   │   └── docker-compose.yml
│   ├── portainer
│   │   └── docker-compose.yml
│   ├── queue
│   │   ├── .env.compose
│   │   ├── .env.container
│   │   └── docker-compose.yml
│   ├── redis
│   │   ├── ssl
│   │   │   └── .gitignore
│   │   ├── docker-compose.yml
│   │   └── redis.conf
│   ├── scheduler
│   │   ├── .env.compose
│   │   ├── .env.container
│   │   └── docker-compose.yml
│   └── traefik
│       ├── .env.compose
│       └── docker-compose.yml
├── traefik
│   ├── dynamic
│   │   ├── 10-tls.yml
│   │   ├── WRR-service.yml
│   │   ├── dashboard.yml
│   │   ├── middlewares.yml
│   │   ├── routers.yml
│   │   └── services.yml
│   ├── .gitignore
│   └── traefik.yml
├── .dockerignore
├── .editorconfig
├── .env.example
├── .gitignore
├── Makefile
├── README.md
├── docker-compose.yml
└── systemd.services
```

## Docker Images Included:

- **PHP** *`8.0-fpm-alpine`*
- **Traefik** *`v2.4`*
- **Nginx** *`1.20-alpine`*
- **MySQL** *`8.0`*
- **MongoDB** *`4.4`*
- **Redis** *`6.2`*
- **Authelia** *`4.29`*
- **Netdata** *`v1.31`*
- **Portainer** *`2.5.1-alpine`*

### `[PHP Modules/Extensions]`

[**Installed PHP extensions**](The following modules and extensions have been enabled, in addition to those you can already find in the [official PHP image](https://hub.docker.com/r/_/php/))

You are able to find all installed PHP extensions by running `php -m` inside your workspace.

`bcmath` `calendar` `Core` `ctype` `curl` `date` `dom` `exif` `fileinfo` `filter` `ftp` `gd` `gmp` `hash` `iconv` `intl` `json` `libxml` `mbstring` `mysqli` `mysqlnd` `openssl` `pcntl` `pcre` `PDO` `pdo_mysql` `pdo_sqlite` `Phar` `posix` `readline` `Reflection` `session` `SimpleXML` `soap` `sockets` `sodium` `SPL` `sqlite3` `standard` `tokenizer` `xml` `xmlreader` `xmlwriter` `xsl` `zip` `zlib`

**Additional non-core php extensions:**

_`amqp`_ _`mongodb`_ _`ds`_ _`igbinary`_ _`msgpack`_ _`redis`_

#### `[Zend Modules]`

_`Xdebug`_ _`Zend OPcache`_

## Getting Started

### Organization

- **`docker` folder must match _current repository folder_**
    - The folder name is configurable via the `LOCAL_DOCKER_FOLDER` variable of the `.env` environment file
- **`app` folder should contain _Laravel application_**
    - The folder name is configurable via the `APP_LOCAL_FOLDER` variable of the `.env` environment file

**The organization of the folders should serve as a reference for organizing this repository Docker + Laravel Application:**

```
.
└── /var/www/
            ├── docker
            ├── your-app
            └── your-app-2
```

### Initial setup / clone the project

```bash
$ git clone https://github.com/AllysonSilva/laravel-docker docker && cd docker
```

- Execute command `make config-env docker_folder=./docker`
- The `LOCAL_DOCKER_FOLDER` variable in the `.env` file must be the folder name of the docker project

*Obs: The `.env` file is a copy of the `.env.example` file, which is created from the initial `make config-env` command*

#### *Important:*

- **Open `.env` file and edit `PROJECT_NAME` and `DOMAIN` variables**
    - The value of the `DOMAIN` variable from the [scripts/envs/deploy.env](scripts/envs/deploy.env) file must match the same value as the same variable from the `.env` file
- **Search for `yourdomain.tld` within that same Docker folder and replace with your company's domain**
- Copy `scripts/envs/docker.env` file to root `docker` folder
    - Use the command to make the copy: `cp scripts/envs/docker.env .`
    - Edit the variable `COMPOSE_PROJECT_NAME`, where it should have the same value as the variable `PROJECT_NAME` in the `.env` file

### Build the image of the Laravel/APP PHP-FPM application

- Copy the contents of the `services/app/.env.compose` file and place at the end of the `.env` file
- Open the `.env` file and edit the variables `APP_IMAGE`, `APP_LOCAL_FOLDER`, `APP_LIMITS_CPU`, `APP_LIMITS_MEMORY` and `APP_RESERVATIONS_MEMORY`
- Download the _Laravel_ application repository. The `APP_LOCAL_FOLDER` variable in the `.env` file must have the same name as the Laravel application folder
- If it's in the Docker root folder, go back up one folder to clone the Laravel application repository(`cd ..`)
    - Download the Laravel application: `git clone --branch 8.x --single-branch https://github.com/laravel/laravel.git app`
    - Return to Docker folder: `cd docker`
- To install *composer* dependencies, use the command: `make -f Makefile -f services/app/Makefile composer-install`
    - It is not necessary in the image building process, only if using volumes/bind in Docker
    - After installing the composer dependencies, the `vendor` folder will be with `root` permission. To change the permission of the Laravel application folder to the machine user, use the command: `sudo chown -R $USER:$USER ../app/`
- To install *npm* dependencies run:
    - `make -f Makefile -f services/app/Makefile npm-handle`
    - `make -f Makefile -f services/app/Makefile npm-handle npm_command="npm run prod"`
--------------------
- Use the command to build the image: **`make -f Makefile -f services/app/Makefile docker-build-app`**
--------------------

### Build the NGINX/Webserver image

*If the server is not using Cloudflare as protection/Load balancing, then change the value of the `real_ip_header` directive in the `nginx/configs/addon.d/10-realip.conf` file from `CF-Connecting-IP` to ` X-Forwarded-For`.*

- Copy the contents of the `services/nginx/.env.compose` file and place at the end of the `.env` file
- Open the `.env` file and edit the variables `WEBSERVER_IMAGE`, `WEBSERVER_PORT_HTTP`, `WEBSERVER_PORT_HTTPS`, `WEBSERVER_LIMITS_CPU`, `WEBSERVER_LIMITS_MEMORY` and `WEBSERVER_RESERVATIONS_MEMORY`
--------------------
- Use the command to build the image: **`make -f Makefile -f services/nginx/Makefile docker-build-webserver`**
--------------------

### Create Let’s Encrypt certificates

#### Generating with DNS challenge

- Copy the `scripts/envs/renew.env` file to the docker root folder(same value as the `DOCKER_PATH` variable in the `.env` file)
    - `cp scripts/envs/renew.env .`
- Open `renew.env` file and edit the following variables:
    - `RENEW_CERT_DOMAINS`: Domains/subdomains that will be in the certificate (separated by comma)
    - Some CAs (such as Let's Encrypt) require that domain validation for wildcard domains be done through DNS record modifications, which means that the DNS-01 challenge type must be used. According to Let's Encrypt policy, wildcard identifiers must be validated by DNS-01 challenge, therefore, authorizations corresponding to wildcard identifiers will only offer DNS-01 challenge
    - `RENEW_CERT_COMMAND_TARGET`: Command that will be executed on the file in the `services/nginx/Makefile` file, which can be:
        - `gen-certs-cloudflare`: It uses the cloudflare DNS API to automatically insert the DNS TXTs records and thus generate the certificates
            - To use this challenge, you must create a file in the `services/nginx/certs` folder named `cloudflare.ini` containing [`dns_cloudflare_api_token = YOUR_TOKEN_AQUI`](https://certbot-dns-cloudflare.readthedocs.io/en/stable/#credentials)
        - `gen-certs`: Used for both HTTP and DNS validation
            - [`Webroot/HTTP`](https://certbot.eff.org/docs/using.html?highlight=webroot#webroot):
                - Used for HTTP challenge
                - It should be used after first generating the certificates through DNS challenge, as the domain is not active on the internet so that the challenge can be successfully performed
                - Need to set variable `RENEW_CERT_IS_CHALLENGE_WEBROOT` to `true` and variable `RENEW_CERT_COMMAND_OPTIONS` to `webroot=yes preferred_challenge=http-01`
            - [`DNS`](https://certbot.eff.org/docs/using.html?highlight=Manual+DNS#manual): Use this validation to generate DNS TXT records and enter manually. The value of the variable `RENEW_CERT_COMMAND_OPTIONS` should be `manual=yes preferred_challenge=dns-01`

To create the certificates for the first time, as the domain is not active/available on the internet, then it is necessary to use the DNS challenge/plugin manually.

After correctly setting the variables, the `renew.env` file should look like this:

```
RENEW_CERT_DOMAINS="domainA.tld,sub.domainB.tld,domainC.tld"
RENEW_CERT_EMAIL=certs@yourdomain.tld

RENEW_CERT_COMMAND_TARGET=gen-certs
RENEW_CERT_COMMAND_OPTIONS="manual=yes \
                            preferred_challenge=dns-01"
```

You must build a custom certbot image, adding the host/server user so that the certificates don't have `root` but server user permissions:

```bash
cd nginx/

docker build \
   --tag company/certbot:v1 \
   --build-arg TAG_IMAGE="certbot/certbot:v1.15.0" \
   --file DockerfileCertbot \
   .

# Back to docker root folder
cd ..
```

The above image was generated with the `tag` `company/certbot:v1`. This value must be updated in the `WEBSERVER_CERTBOT_IMAGE` variable in the `.env` file.

After, update the variable `WEBSERVER_CERTBOT_IMAGE` with the name of the newly created image, **then run the script `./scripts/renew-certs.sh` and follow the steps to create the first certificates for the application**.

To see the domains and certificate validity, run the command `make -f Makefile -f services/nginx/Makefile get-certs`.

### Before up the application

> Before running the application, you must configure the _docker networks_ for connection between containers

#### Create the default container networks

- Two networks are created by default. One for all containers(`compose_network`) and one for connecting `traefik` to containers for proxy(`traefik_network`), in the file [`docker-compose.yml`](docker-compose.yml)

- To run the `docker-compose --compatibility up` command to create the networks and then the application containers, `traefik`, `nginx` and others to connect, it is necessary first to copy the contents of the file [`services/traefik/.env.compose`](services/traefik/.env.compose) and place at the end of the `.env` file

- After performing the above step, run the command `docker-compose --compatibility up` to create the networks so that the containers can connect and traefik act as a proxy
    - Run the command `docker network ls` and see if there are two networks with the name: `${VARIABLE_VALUE_PROJECT_NAME}_network` e `${VARIABLE_VALUE_PROJECT_NAME}_traefik_network`

- The `traefik` network name, must be updated in the `traefik/traefik.yml` file in the `providers.docker.network` directive. Replacing `company_traefik_network` with the value `${VARIABLE_VALUE_PROJECT_NAME}_traefik_network`
    - The `providers.docker.network` directive of the [`traefik/traefik.yml`](traefik/traefik.yml) file, must have the same value as the `TRAEFIK_DOCKER_NETWORK` variable in the `.env` file

### UP APP Application + NGINX/Webserver

- **If the server is not behind some proxy like cloudflare, then remove the `websecure.forwardedHeaders.trustedIPs` directive**

- **After the HTTPs certificates are created, run the command `make docker-up context=traefik version=v0`**

- Create the `dhparam.pem` file for NGINX to use in the `ssl_dhparam` directive, with the following command:

    ```bash
    $ cd services/nginx/certs/
    $ openssl dhparam -out dhparam.pem 4096
    # Back to docker root folder
    $ cd ../../../
    ```

- Create `rotate` folder in `./../app/storage/logs/` for log rotation, using `logrotate`

- Copy `scripts/envs/deploy.env` file to docker root folder
    - Use the command to make the copy: `cp scripts/envs/deploy.env .`
    - Edit the variable `DOMAIN` with the same value of the same variable in the `.env` file

- Edit the `./services/app/.env.container` file, setting the variables for the laravel project, mainly `APP_KEY` and `APP_ENV`, which are mandatory in the `entrypoint` docker of the application container
    - `APP_KEY`: If the application key is not set, user sessions and other encrypted data will not be secure!
    - Use `APP_ENV=production` and `APP_DEBUG=false` for production, and `APP_ENV=local` `APP_DEBUG=true` for development
    - Configure the variables `PHPFPM_MAX_CHILDREN`, `PHPFPM_START_SERVERS`, `PHPFPM_MIN_SPARE_SERVERS` and `PHPFPM_MAX_SPARE_SERVERS` according to the capacity of the machine/server

- Run the `./scripts/deploy-version.sh` script to create the Laravel/PHP-FPM and Webserver/NGINX containers
    - The script uses `git checkout ./services/nginx/servers`, so any changes to the NGINX virtualhost must be committed so that they cannot be lost

- See if the domain is correct in the `server_name` directive in the `services/nginx/servers/app.conf` file

- Access the application's domain and view the website in the browser with *`https://yourdomain.tld`*

*When there are new changes in the code and with that, a new image is built, then, it is necessary to run or rerun the deploy script to update the PHP/APP containers with the new code of the new images.*

#### APP/Laravel with New Relic

- Access the address [https://docs.newrelic.com/docs/apis/intro-apis/new-relic-api-keys/#license-key-create](https://docs.newrelic.com/docs/apis/intro-apis/new-relic-api-keys/#license-key-create) so i can generate a new license
- Open the file [services/app/.env.container](services/app/.env.container#L31) and edit the section `# # NEW RELIC ENVs`
    - Edit the variable `NEW_RELIC_ENABLED` to `true`
    - Edit the variable `NEW_RELIC_APPNAME` which represents the name of the application that will be rendered in the New Relic panel
    - Update `NEW_RELIC_LICENSE_KEY` variable with the license value generated previously. [40-character New Relic User Account Key](https://docs.newrelic.com/docs/apis/intro-apis/new-relic-api-keys/#license-key-create)
- Run container with command: `make docker-up context=newrelic`

#### NGINX/Webserver with GeoIP2

- Access your user account on the website [www.maxmind.com](https://www.maxmind.com/)
    - If you don't have a registered account, you need to create a new account
- Go to menu *"Manage License Keys"*
- Click in *"Generate new license key"*
- In the *"License key description"* field enter a license name so you can remember
- In the message *"Old versions of our GeoIP Update program use a different license key format. Will this key be used for GeoIP Update?"*, mark the option *"No"* and click *"Confirm"*
- On the next page, the *Account/User ID* and *License key* credentials will appear
    - Open file [services/nginx/.env.container](services/nginx/.env.container)
        - Set the value of the `WITH_GEOIP2` variable to `true`
        - Set the value of the `GEOIPUPDATE_ACCOUNT_ID` variable to the value that appears in *Account/User ID*
        - Set the value of the `GEOIPUPDATE_LICENSE_KEY` variable to the value that appears in *License key*

## Run Containers

### Run Redis Container

- Change the redis password in the **`requirepass`** directive in the [*services/redis/redis.conf*](services/redis/redis.conf#L885) file
- Configuration file, uses default port `6379` for non *TLS/SSL* connections, and port `6380` for encrypted *TLS/SSL* connections. To generate the certificates to use in the *TLS/SSL* connection, the following command must be run:

    ```bash
    ./scripts/self-signed-SSL.sh \
        --service=redis \
        --cert-ca-pass=keypassword \
        --cert-server-pass=keypassword \
        --cert-server-host=redis.yourdomain.tld \
        --with-dhparam
    ```

    - Add `127.0.0.1 redis.yourdomain.tld` to `/etc/hosts`
    - Change the value of the `tls-key-file-pass` directive in the [*services/redis/redis.conf*](services/redis/redis.conf#L140) file to the value of the `--cert-server- pass`

- Run the container using the command: `make docker-up context=redis version=v1`

- To access the Redis container database:

    ``bash
    docker exec -it redis redis-cli -n 0 -p 6379 -a 'YOUR_REDIS_PASSWORD' --no-auth-warning
    ```

### Run Authelia Container

- Uncomment the line containing `authelia-forwardAuth@docker` in the [traefik/dynamic/middlewares.yml](traefik/dynamic/middlewares.yml#L20) file
    - *`traefik` dynamic settings are updated in real time. No need to restart the `traefik` container*
- Open the file [services/authelia/configs/configuration.yml](services/authelia/configs/configuration.yml) and configure the following points:
    - Search and replace the example domain `yourdomain.tld` to the real domain of the company
    - Change the name of the redis container `v1_company_redis_1`
- Edit the passwords in the [services/authelia/secrets](services/authelia/secrets) folder
    - [`jwt`](https://www.authelia.com/docs/configuration/miscellaneous.html#jwt_secret): Defines the secret used to craft JWT tokens leveraged by the identity verification process
    - [`session`](https://www.authelia.com/docs/configuration/session/): Authelia relies on session cookies to authenticate users
    - [`redis`](https://www.authelia.com/docs/configuration/session/redis.html): This is a session provider
- Edit the user and password in the [services/authelia/configs/users.yml](services/authelia/configs/users.yml) file. [See documentation](https://www.authelia.com/docs/configuration/authentication/file.html)

- Run the container using the command: `make docker-up context=authelia version=v0`

- *Access Authelia with `https://authelia.yourdomain.tld`*

### Run Netdata Container

- The settings applied to the *Netdata* container are found in [services/netdata/configs/netdata.conf](services/netdata/configs/netdata.conf)
    - See the settings at [https://learn.netdata.cloud/docs/agent/daemon/config](https://learn.netdata.cloud/docs/agent/daemon/config)

- Edit the `ExecStart` setting in the Docker service file `/lib/systemd/system/docker.service` to the value `ExecStart=/usr/bin/dockerd -H fd:// -H tcp://127.0.0.1:2375 --containerd=/run/containerd/containerd.sock`
    - Update the new changes with `sudo systemctl daemon-reload` and `sudo services restart docker`

- Run the container using the command: `make docker-up context=netdata`

- *Access Netdata with `https://netdata.yourdomain.tld`*

### Run MongoDB Container

- Run the script to generate the certificates for use in the *TLS/SSL* connection:
    ```bash
    ./scripts/self-signed-SSL.sh \
        --service=mongodb \
        --cert-ca-pass=keypassword \
        --cert-server-pass=keypassword \
        --cert-server-host=mongodb.yourdomain.tld
    ```
    - **Obs:** *The mongo shell verifies that the hostname (specified in --host option or the connection string) matches the SAN (or, if SAN is not present, the CN) in the certificate presented by the mongod or mongos. If SAN is present, mongo does not match against the CN. If the hostname does not match the SAN (or CN), the mongo shell will fail to connect.*
    - Add `127.0.0.1 mongodb.yourdomain.tld` to `/etc/hosts`

- Open the [services/mongodb/mongod.conf](services/mongodb/mongod.conf#L21) file and edit the `certificateKeyFilePassword` setting which should match the `--cert-server-pass` argument of the above script

- Open the file [services/mongodb/.env.container](services/mongodb/.env.container#L6) and edit the password, replacing `YOUR_MONGODB_ROOT_PASSWORD` with the new password

- Run the container using the command: `make docker-up context=mongodb`

- Run the script below to retrieve the full name of the `mongodb` container:

    ```bash
    MONGODB_CONTAINER_NAME=$(docker ps -q --filter name="mongodb" --filter status=running --no-trunc --format="{{.Names}}")
    ```

- Recover the external port to connect outside the server:

    ```bash
    docker port ${MONGODB_CONTAINER_NAME} 27017/tcp
    # `0.0.0.0:OUTSIDE_PORT`
    ```

    - To verify that the connection supports TLS in version 1.3, run the command: `openssl s_client -connect 127.0.0.1:OUTSIDE_PORT -tls1_3`

- To access the database using the container's own mongodb client, run the command:

    ```bash
    docker exec -ti ${MONGODB_CONTAINER_NAME} mongo \
        --username 'root' \
        --authenticationDatabase 'admin' \
        --password 'YOUR_MONGODB_ROOT_PASSWORD'
    ```

    - To create a user, use the following command:

        ```bash
        $ use admin
        $ db.createUser({user: 'app', pwd: 'passw0rd1', roles: ["userAdminAnyDatabase", "dbAdminAnyDatabase", "readWriteAnyDatabase"]})
        # mongo --username "app" --password "passw0rd1" --authenticationDatabase "admin"
        ```

- To access the database using the machine's mongodb client inside or outside the server, run the command:

    ```bash
    mongo --tls \
        --tlsCAFile ca.pem \
        --tlsCertificateKeyFile client.pem \
        --host localhost||SERVER_IP||SERVER_DATABASE_DNS \
        --port MONGODB_PUBLIC_PORT \
        --username 'app||root' \
        --authenticationDatabase 'admin' \
        --password 'passw0rd1||${MONGO_INITDB_ROOT_PASSWORD}'
    ```

### Run MySQL Container

- Run the script to generate the certificates for use in the *TLS/SSL* connection:
    ```bash
    ./scripts/self-signed-SSL.sh \
        --service=mysql \
        --cert-server-host=mysql.yourdomain.tld
    ```

    - Add `127.0.0.1 mysql.yourdomain.tld` to `/etc/hosts`

- Open the file [services/mysql/my.cnf](services/mysql/my.cnf) and edit the MySQL settings

- Open the [services/mysql/.env.container](services/mysql/.env.container) file and edit the environment variable credentials

- Run the container using the command: `make docker-up context=mysql`

- To access the MySQL container database:

    ```bash
    mysql -h 127.0.0.1||mysql.yourdomain.tld -P {OUTSIDE_PORT/3306} -uapp -p'YOUR_MYSQL_PASSWORD' \
        --ssl-ca=services/mysql/ssl/ca.pem \
        --ssl-key=services/mysql/ssl/client-key.pem \
        --ssl-cert=services/mysql/ssl/client-cert.pem
    ```

### Run Portainer Container

- Run the container using the command: `make docker-up context=portainer`
- *Access Portainer with `https://portainer.yourdomain.tld`*

### Run Queue/Scheduler Container

- Open `.env.container` file in `queue` or `scheduler` folders edit as needed
- Run the container using the command: `make docker-up context=queue||scheduler`

### Run GoAccess Container

- Open file [services/nginx/.env.compose](services/nginx/.env.compose) and edit the variable `DOCKER_COMPOSE_WEBSERVER_OPTIONS`, adding the value of: `-f services/goaccess/docker-compose.webserver.yml`

- Open file [deploy.env](deploy.env)(if it exists), and edit the variable `DOCKER_COMPOSE_WEBSERVER_OPTIONS`, adding the value of: `-f services/goaccess/docker-compose.webserver.yml`

- Copy the file [services/nginx/servers/additional/goaccess.conf](services/nginx/servers/additional/goaccess.conf) to a folder level, it should be in `services/nginx/servers/goaccess.conf`
    - Edit the `server_name goaccess.yourdomain.tld` line, replacing `yourdomain.tld` with the correct company domain

- Restart the NGINX/Webserver container with the command: `make -f Makefile -f services/nginx/Makefile docker-up-webserver`

- Check and edit the GoAccess configuration file as preferred [services/goaccess/goaccess.conf](services/goaccess/goaccess.conf)

- Run the container *GoAccess* using the command: `make docker-up context=goaccess`

- *Access GoAccess with `https://goaccess.yourdomain.tld`*

## Makefile Commands

**Install PHP Composer Dependencies in Project**

```bash
make -f Makefile -f services/app/Makefile composer-install
```

**Run NPM Commands**

```bash
make -f Makefile -f services/app/Makefile npm-handle npm_command="npm run prod"
```

*Replace "npm run prod" with "npm anything"*

**Build the APP/Laravel Image**

```bash
make -f Makefile -f services/app/Makefile docker-build-app
```

**Run/Recreate APP/Laravel containers**

```bash
make -f Makefile -f services/app/Makefile docker-up-app
```

With the following options:

- `version`: Option used to specify a new version other than the currently running containers
- `scale`: Total number of containers NGINX will use as *HTTP load balancer* in the `upstream` directive
    - After passing these options, it is necessary to run the command `./scripts/loadbalancer-nginx.sh` so that you can update the `app.conf` file of NGINX with the names/version of the new containers
- `up_options`: Options that will be passed to the `up` command. By default the options are: `--force-recreate --no-build --no-deps --detach`
- `options`: Options that are passed to the `docker-compose` command like `--verbose` or `--log-level` for example

**Run/Recreate NGINX/Webserver containers**

```bash
make -f Makefile -f services/nginx/Makefile docker-up-webserver
```

With the following options:

- `version`: Option used to specify a new version other than the currently running containers
- `scale`: Total number of containers that will be executed, will be running ready to receive and handle requests through `traefik`
- `up_options`: Options that will be passed to the `up` command. By default the options are: `--force-recreate --no-build --no-deps --detach`
- `options`: Options that are passed to the `docker-compose` command like `--verbose` or `--log-level` for example

**Build the NGINX/Webserver Image**

```bash
make -f Makefile -f services/nginx/Makefile docker-build-webserver
```

## Scripts

**Important:** Before running the scripts/commands below it is necessary:

- Copy the files in the `scripts/envs` folder to the docker root folder
- Edit the `COMPOSE_PROJECT_NAME` environment variable in the `docker.env` file with the same value as the same variable in the `.env` file

### `./scripts/cron-renew-certs.sh`

> Use this command to set up a CRON schedule for automatic renewal of Let's Encrypt certificates

**To add a schedule in CRON to renew HTTPs certificates every Sunday at 02:00, run the following command:**

```bash
./scripts/cron-renew-certs.sh --timer=\"0 2 * * MON\" --path=/var/www/docker/ --add
```

Where:

- `--timer=`: *Scheduling expression in CRON*
- `--path=`: *Docker folder path*
- `-add`: *Add a command that will execute `./scripts/renew-certs.sh` to CRON which will be executed every time set in the `--timer` option*

**To remove the schedule from CRON, run the command:**

```bash
./scripts/cron-renew-certs.sh --remove
```

### `./scripts/deploy-version.sh`

> Use this command to update the number of running PHP/Laravel and NGINX/Webserver containers or to update the version of the containers with a new updated PHP/Laravel or NGINX/Webserver image

Before running the script/command it is necessary to update the environment variable `DOMAIN` in the file `deploy.env`, which must have the same value as the same variable in the file `.env`

*To create 4 APP/Laravel and 2 Nginx/Webserver containers, run the following command:*

```bash
./scripts/deploy-version.sh --new-version=v9 --num-nginx-scale=2 --num-php-scale=4
```

By default, if no option is passed as an argument in the command, then they will have the following values:

- `--new-version=`: Previous version + 1
- `--num-nginx-scale=`: Value that is in the variable `DOCKER_COMPOSE_WEBSERVER_SCALE` of the file [services/nginx/.env.compose](services/nginx/.env.compose#L8)
- `--num-php-scale=`: Value that is in the variable `DOCKER_COMPOSE_APP_SCALE` of the file [services/app/.env.compose](services/app/.env.compose#L9)

### `./scripts/loadbalancer-nginx.sh`

> Use this command to update the [`services/nginx/servers/app.conf`](services/nginx/servers/app.conf) file or any other (web server, server blocks) in NGINX, with the names of the APP/Laravel containers that will be used in the NGINX `upstream` directive used in HTTP load balancer handling

**The script/command has the following options/arguments:**

- `--not-reload-nginx`: If this option is not passed, then the NGINX processes inside the container will be reloaded, causing updates to the (web server, server blocks) `.conf` files located in `services/nginx/servers` to be published/visible on the internet

- `--php-container-name=`: Option used so that Docker can filter PHP/Laravel containers with the command `docker ps --filter name="$PHP_CONTAINER_NAME"`
    - By default the name of PHP/Laravel containers filtered by the docker will be: `^/v([0-9]+)${COMPOSE_PROJECT_NAME}_app_\d+`
    - This option is only needed when containers are not generated by the `./scripts/deploy-version.sh` script or `docker-up-app` command

- `--nginx-container-name=`: Option used so that Docker can filter NGINX/Webserver containers with the command `docker ps --filter name="$NGINX_CONTAINER_NAME"`
    - By default the name of the NGINX/Webserver containers filtered by the docker will be: `^v\d+${COMPOSE_PROJECT_NAME}_webserver`
    - This option should only be used in the script if the `--not-reload-nginx` option is not passed. Because NGINX containers will have to be retrieved to be updated
    - This option is only needed when containers are not generated by the `./scripts/deploy-version.sh` script or `docker-up-webserver` command

- `--loadbalancer-name=`: The value of this argument/option will be used to name the NGINX `upstream` directive in the `.conf` file

- `--filename-server=`: Name of the `.conf` file that will be used to edit and add the `upstream` directive with the names of the PHP/Laravel containers
    - It is only necessary the name of the `.conf` file found in the `services/nginx/servers` folder
    - Before the `server` directive, it must have the following content so that the file can be updated and the information will be added between the lines
        ```
        ###SET_UPSTREAM
        ###END_SET_UPSTREAM
        ```

The following is an example of using the script:

```bash
./scripts/loadbalancer-nginx.sh --loadbalancer-name=loadbalancer-xyz --filename-server=site.conf
```

### `./scripts/update-app.sh`

> - Use this command when **OPcache** is enabled in PHP/Laravel containers and you are also using volumes in the docker in Laravel application with the same PHP/Laravel containers
> - In executing this script, a set of artisan commands will also be executed, such as: `route:cache`, `config:cache`, `view:cache` and `migrate` (if the `--force-migrations` option is passed in script/command)
> - Also use to automate the project update process on the local machine using GIT

**The script contains the following options/arguments:**

- `--with-reload-phpfpm`: By default GIT updates in the project(`git pull`), do not update PHP-FPM in containers so that *OPcache* is also updated, so passing this option will update PHP-FPM processes inside the container, through the sign `SIGUSR2`

- `--force-migrations`: By default the `php artisan migrate --force` command will not be executed. Passing this option then the script also runs `artisan migrate` on the project

- `--container-name=`: Name of the container that will be used in the docker command `docker ps --filter name="$LARAVEL_CONTAINER_NAME"` to run the PHP-FPM process update and also run the `artisan` commands
    - By default the name of PHP/Laravel containers filtered by the docker will be: `^/v([0-9]+)${COMPOSE_PROJECT_NAME}_app_\d+`
    - This option is only needed when containers are not generated by the `./scripts/deploy-version.sh` script or `docker-up-app` command

- `--container-workdir=`: Option used in the `--workdir` argument in the `docker exec` command, which has the same value as the `--path` argument, if `--container-workdir` is not present in the command

- `--path=`: Absolute path to the folder where the Laravel project is located, so the script can perform a simple `cd $WEBPATH_GIT`

- `--branch=`: Name of the GIT branch the script will perform `git checkout $BRANCH`

- `--npm-run=`: NPM commands that will run on the machine itself within the Laravel project

The following is an example of using the script:

```bash
./scripts/update-app.sh --with-reload-phpfpm --force-migrations --path="/var/www/app" --branch=main
```

## Setup Auto-Renew Let's Encrypt SSL Certificates

- Before generating the certificates it is necessary to configure the `renew.env` file in the docker root folder
    - Edit the variable `RENEW_CERT_DOMAINS`, adding the domains, subdomain, separated by comma that will be generated/renewed
    - Edit `RENEW_CERT_EMAIL` variable for the email that should be sent certificate expiration notification by Let's Encrypt
- Let's Encrypt certificates (`cert.pem`, `chain.pem`, `fullchain.pem` and `privkey.pem`) must be in the `./services/nginx/certs` folder
- There should also be a file called `dhparam.pem` in the same folder as the certificates
    - Use the following command to generate this file: `openssl dhparam -out ./services/nginx/certs/dhparam.pem 4096`

### Generate SSL certificates manually

#### Configure `renew.env` to generate certificates via [HTTP challenge](https://certbot.eff.org/docs/using.html?highlight=webroot%20path#webroot)

- Add the following content to the `renew.env` file:
    ```
    RENEW_CERT_COMMAND_TARGET=gen-certs
    RENEW_CERT_IS_CHALLENGE_WEBROOT=true
    RENEW_CERT_COMMAND_OPTIONS="webroot=yes preferred_challenge=http-01"
    ```

- Run the `./scripts/renew-certs.sh` script and follow the steps of *certbot* certificate generation

#### Configure `renew.env` to generate certificates via [DNS challenge](https://certbot.eff.org/docs/using.html?highlight=manual#manual)

- Add the following content to the `renew.env` file:
    ```
    RENEW_CERT_COMMAND_TARGET=gen-certs-cloudflare
    ```

- Run the `./scripts/renew-certs.sh` script and follow the steps of *certbot* certificate generation

#### Configure `renew.env` to generate the certificates via the DNS plugin [certbot-dns-cloudflare](https://certbot-dns-cloudflare.readthedocs.io/en/stable/)

- Add the following content to the `renew.env` file:
    ```
    RENEW_CERT_COMMAND_TARGET=gen-certs-cloudflare
    ```

- To use this challenge, you must create a file in the `services/nginx/certs` folder named `cloudflare.ini` containing [`dns_cloudflare_api_token = YOUR_TOKEN_AQUI`](https://certbot-dns-cloudflare.readthedocs.io/en/stable/#credentials)

- Run the `./scripts/renew-certs.sh` script and follow the steps of *certbot* certificate generation

### Configure CRON to automatically generate SSL certificates

- Configure `renew.env` file with one of the three modes in the [above menu](#generate-ssl-certificates-manually)
- Configure CRON to generate certificates every time according to the scheduling expression through the command [`./scripts/cron-renew-certs.sh`](#scriptscron-renew-certssh)

## Contributing

If you find an issue, or have a special wish not yet fulfilled, please [open an issue on GitHub](https://github.com/AllysonSilva/laravel-docker/issues) providing as many details as you can (the more you are specific about your problem, the easier it is for us to fix it).

Pull requests are welcome, too 😁! Also, it would be nice if you could stick to the [best practices for writing Dockerfiles](https://docs.docker.com/articles/dockerfile_best-practices/).

##  License

[MIT License](https://github.com/AllysonSilva/laravel-docker/blob/master/LICENSE)
