<h1 align="center">
    <br>
    <a href="https://laravel.com/"><img src="https://konpa.github.io/devicon/devicon.git/icons/laravel/laravel-plain-wordmark.svg" alt="Laravel" width="100"></a>
    <a href="https://www.docker.com/"><img src="https://konpa.github.io/devicon/devicon.git/icons/docker/docker-original-wordmark.svg" alt="Docker" width="100"></a>
    <br>
        Laravel Dockerized
    <br>
</h1>

<h4 align="center">This is a personal collection of Docker tools and images(Nginx, PHP-FPM, MySQL, Redis, MongoDB, Queue, Scheduler, ELK and Traefik) for applications in <a href="https://laravel.com/" target="_blank">Laravel</a></h4>

<p align="center">
    <a href="#project-structuretree">Project Structure/Tree</a> •
    <a href="#whats-insidesoftwares-included">What's Inside/Softwares Included</a> •
    <a href="#getting-started">Getting Started</a> •
    <a href="#build-images">Build Images</a> •
    <a href="#use-makefile">Use Makefile</a>
</p>

---

## Key Features

- A single service, a single application per container. Containers responsible for running a single service
- Configurations and _variables of environment_ separated by service/container
- `Makefile` has the main commands for image build and container execution
- **MySQL** configured to only accept connections in _SSL/TLS_
- **MongoDB** configured to only accept _SSL/TLS_ connections
- Container of _Reverse Proxy_ **Nginx** with the best security standard:
    * _Force HTTPS_
    * _TLS best practices_
    * _Security HTTP headers_
    * _Controlling buffer overflow attacks_
    * _Control simultaneous connections_
    * _Allow access to our domain only_
    * _Limit available methods_
    * _Block referral spam_
    * _Stop image Hotlinking_
    * _Block ips attack by brute force_
- Easy use and configuration of **Traefik**, acting as _Api Gateway_, forwarding the requests to the specific destination according to the applied rule
- A single container responsible for handling **Queue**
- A single container responsible for handling **Scheduler**

## Project Structure/Tree

```
.
├── .dockerignore
├── .env.example
├── Makefile
├── docker-compose.yml
├── docker-compose.override.yml
├── php
│   └── Dockerfile
├── app
│   ├── Dockerfile
│   ├── docker-entrypoint.sh
│   ├── app.env.example
│   └── config
│       ├── php.ini-development.ini
│       ├── php.ini-production.ini
│       ├── extensions
│       │   ├── opcache.ini
│       │   └── xdebug.ini
│       ├── fpm
│       │   ├── php-fpm.conf
│       │   └── www.conf
│       └── vscode
│           └── launch.json
├── queue
│   ├── Dockerfile
│   ├── docker-entrypoint.sh
│   ├── queue.env.example
│   └── config
│       ├── supervisord.conf
│       └── templates
│           ├── laravel-horizon.conf.tpl
│           └── laravel-worker.conf.tpl
├── scheduler
│   ├── Dockerfile
│   ├── docker-entrypoint.sh
│   ├── scheduler.env.example
│   └── cron-jobs
│       └── laravel-scheduler
├── nginx
│   ├── .dockerignore
│   ├── Dockerfile
│   ├── docker-entrypoint.sh
│   ├── certs
│   │   ├── cert.pem
│   │   ├── chain.pem
│   │   ├── dhparam4096.pem
│   │   ├── fullchain.pem
│   │   └── privkey.pem
│   ├── config
│   │   ├── mime.types
│   │   ├── nginx.conf
│   │   ├── servers
│   │   │   ├── admin.conf
│   │   │   ├── api.conf
│   │   │   ├── app.conf
│   │   │   ├── site.conf
│   │   │   └── webmail.conf
│   │   └── snippets
│   │       ├── php
│   │       │   ├── fastcgi.conf
│   │       │   └── php_fpm.conf
│   │       └── server
│   │           ├── cache_expiration.conf
│   │           ├── deny_ips.conf
│   │           ├── real_ip.conf
│   │           ├── security_http_headers.conf
│   │           ├── ssl_best_practices.conf
│   │           └── ssl_common_certificates.conf
│   └── helpers
│       └── cert-status.sh
├── redis
│   └── redis.conf
├── mysql
│   ├── my.cnf
│   ├── mysql.env
│   └── ssl
│       ├── ca-key.pem
│       ├── ca.pem
│       ├── client-cert.pem
│       ├── client-key.pem
│       ├── private_key.pem
│       ├── public_key.pem
│       ├── server-cert.pem
│       └── server-key.pem
├── mongodb
│   ├── mongo-init.js
│   ├── mongod.conf
│   └── ssl
│       ├── client.crt
│       ├── client.csr
│       ├── client.key
│       ├── client.pem
│       ├── rootCA.key
│       ├── rootCA.pem
│       ├── rootCA.srl
│       ├── server.crt
│       ├── server.csr
│       ├── server.key
│       └── server.pem
├── elastic
│   ├── .env
│   ├── docker-compose-setup.yml
│   ├── docker-compose.yml
│   ├── config
│   │   ├── elasticsearch
│   │   │   └── elasticsearch.yml
│   │   ├── filebeat
│   │   │   └── filebeat.yml
│   │   ├── kibana
│   │   │   └── kibana.yml
│   │   ├── logstash
│   │   │   ├── logstash.yml
│   │   │   └── pipeline
│   │   │       └── logstash.conf
│   │   ├── metricbeat
│   │   │   └── metricbeat.yml
│   │   ├── packetbeat
│   │   │   └── packetbeat.yml
│   │   └── ssl
│   │       ├── ca
│   │       └── instances.yml
│   ├── scripts
│   │   ├── setup-beat.sh
│   │   ├── setup-elasticsearch.sh
│   │   ├── setup-kibana.sh
│   │   ├── setup-logstash.sh
│   │   ├── setup-users.sh
│   │   └── setup.sh
│   └── setups
│       ├── docker-compose.setup.beats.yml
│       ├── docker-compose.setup.elasticsearch.yml
│       ├── docker-compose.setup.kibana.yml
│       └── docker-compose.setup.logstash.yml
└── traefik
    └── traefik.toml
```

## Install/Requirements Docker

- [Ubuntu](https://docs.docker.com/engine/installation/linux/ubuntu/)
- [Windows](https://docs.docker.com/docker-for-windows/install/)
- [MacOS](https://docs.docker.com/docker-for-mac/install/)

> Download and install [Docker Engine](https://docs.docker.com/engine/installation/) (**>= 18.09**) for your platform and you also have to install [Docker compose](https://docs.docker.com/compose/install/) (**>= 1.24.0**)

## What's Inside/Softwares Included:

- _`PHP`_ 7.3.x
- [PHP-FPM](https://php-fpm.org/)
- [_`Nginx`_ 1.15.x](https://nginx.org/)
- [_`MySQL`_ 5.7](https://www.mysql.com/)
- [_`MongoDB`_ 4.1](https://www.mongodb.org/)
- [ _`Redis`_ 5.x](https://redis.io/)
- [_`Elasticsearch`_ | _`Logstash`_ | _`Kibana`_ 6.6.x](https://www.elastic.co/)
- [_`Traefik`_ 1.7.x](https://traefik.io/)

### `[PHP Modules]`

[**Installed PHP extensions**](The following modules and extensions have been enabled, in addition to those you can already find in the [official PHP image](https://hub.docker.com/r/_/php/))

You are able to find all installed PHP extensions by running `php -m` inside your workspace.

`bcmath` `Core` `ctype` `curl` `date` `dom` `fileinfo` `filter` `ftp` `gd` `gmp` `hash` `iconv` `intl` `json` `libxml` `mbstring` `mysqli` `mysqlnd` `openssl` `pcntl` `pcre` `PDO` `pdo_mysql` `pdo_sqlite` `Phar` `posix` `readline` `Reflection` `session` `SimpleXML` `soap` `sockets` `sodium` `SPL` `sqlite3` `standard` `tokenizer` `xml` `xmlreader` `xmlwriter` `zip` `zlib`

**Optional modules that can be installed according to the compilation/build of the _PHP base image_(`make build-php`)**

_`amqp`_ _`swoole`_ _`mongodb`_ _`sqlsrv`_ _`pdo_sqlsrv`_ _`ds`_ _`igbinary`_ _`lzf`_ _`msgpack`_ _`redis`_ _`xdebug`_

#### `[Zend Modules]`

**`Xdebug`** **`Zend OPcache`**

## Getting Started

- **The folder name of the repository must be `docker` and not `laravel-docker`(original repository name)**
- _Folder `docker` must be in the root folder of the Laravel project_
- _Copy `.dockerignore` to the project's root folder_

### Clone the project

To install [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git), _download_ to the root folder of the laravel project it and install following the instructions:

```bash
$ git clone https://github.com/AllysonSilva/laravel-docker docker && cd docker
```

- **Rename the `.env.example` file to `.env`**
- **Uncomment the `pwd` variable and fill it with result `echo $PWD`**
- **Use the `DOCKER_FOLDER_PATH` variable in the `.env` file for the folder name `docker`**

**Customize Running in Development**

```bash
docker-compose -f docker-compose.yml -f docker-compose.override.yml up database redis app webserver queue
```

### Init build(Local or Development)

- To generate SSL certificates using the [minica](https://github.com/jsha/minica) package, use the following command:

```bash
make app-ssl-certs domain_app=yourdomain.tld
```

- To build all the images that will be used by `docker-compose`, use the following initialization:

```bash
make build \
    domain_app=yourdomain.tld \
    app_path_prefix=/var/www \
    remote_src=/var/www/yourdomain.tld/ \
    app_env=local \
    project_environment=development \
    docker_folder_path=./docker
```

- Add the domain in `/etc/hosts`

```bash
sudo tee -a /etc/hosts >/dev/null <<EOF
127.0.0.1  yourdomain.tld
127.0.0.1  www.yourdomain.tld
EOF
```

### Download docker images

Run the `make pull` command to download the images that will be used in `docker-compose.yml` or `make` commands.

---

## Build Images

### BASE PHP

> Image(`app:base`) used to be as BASE in the first `FROM` instruction of `Dockerfile`. Used as a more generic image for any application in _PHP_. It has the responsibility to act only as a BASE image for more specific images according to the type of the framework/application _PHP_(Laravel, Symfony, CakePHP ...)

- By default [`php.ini`](/php/Dockerfile#L323) corresponds to the `php.ini-production` file of the source code in the default repository in GitHub [_PHP_](https://github.com/php/php-src/blob/php-7.3.4/php.ini-production)

    ```
    mv /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini
    ```

- **Composer**: Installed globally in the path of the `$PATH` `/usr/local/bin/composer`

- **PHPUnit**: Installed globally in the path of the `$PATH` `/usr/local/bin/phpunit`

- `WORKDIR` in _Dockerfile_ corresponds to the value of the argument `--build-arg REMOTE_SRC=/var/www/app/`

Use the following command to build the image:

```bash
$ make build-php php_base_image_name=app:base
```

If you want to customize the image construction according to your arguments, use the `docker build` command directly:

```bash
docker build -t app:base \
    --build-arg DEFAULT_USER=app \
    --build-arg DEFAULT_USER_UID=$UID \
    --build-arg DEFAULT_USER_GID=$(id -g) \
- < ./php/Dockerfile
```

Use the `--build-arg` option to customize/install specific _PHP_ extensions according to the arguments in the `Dockerfile` of the image.

See Docker's [documentation]([https://docs.docker.com/engine/reference/builder/#arg](https://docs.docker.com/engine/reference/builder/#arg)) the `ARG` statement in `Dockerfile`

_The values of the arguments below represent default arguments that are used when the `docker build` command is executed without any custom arguments._

```bash
docker build -t app:base \
    --build-arg DEFAULT_USER=app \
    --build-arg DEFAULT_USER_UID=$UID \
    --build-arg DEFAULT_USER_GID=$(id -g) \
    --build-arg INSTALL_PHP_AMQP=false \
    --build-arg INSTALL_PHP_SWOOLE=false \
    --build-arg INSTALL_PHP_MONGO=false \
    --build-arg INSTALL_PHP_SQLSRV=false \
    --build-arg INSTALL_PHP_IGBINARY=true \
    --build-arg INSTALL_PHP_LZF=true \
    --build-arg INSTALL_PHP_MESSAGEPACK=true \
    --build-arg INSTALL_PHP_REDIS=true \
    --build-arg INSTALL_PHP_DS=true \
    --build-arg INSTALL_PHP_XDEBUG=true \
- < ./php/Dockerfile
```

To create the image with all extensions enabled by default, use the following command:

```bash
$ make build-full-php php_base_image_name=app:base
```

### Laravel APP/PHP-FPM

> - The construction/configuration of this image is used for applications in _Laravel_
> - Extend the image [BASE PHP](#base-php) by means of instruction `FROM $PHP_BASE_IMAGE` in your `Dockerfile`
> - Used [multi-stage builds](https://docs.docker.com/develop/develop-images/multistage-build/) in your `Dockerfile`
>     * In the first stage use the image of [Composer](https://hub.docker.com/_/composer) to manage the system dependencies (To speed up the download process [hirak/prestissimo](https://github.com/hirak/prestissimo) is used)
>     * In the second stage use the [Node.js](https://hub.docker.com/_/node) image to build the dependencies of the Front-end using the yarn manager
>     * In the third and final stage, the results of the previous stages are used to copy the necessary files to the project image

#### How to use

- `$PROJECT_ENVIRONMENT`: Can be set to two values: ([`production`](/app/docker-entrypoint.sh#L170) and [`development`](/app/docker-entrypoint.sh#L182)). Its purpose is to define the flow in the ENTRYPOINT (`/entrypoint.sh`)
    * Can be defined at the moment of image creation through argument: `--build-arg PROJECT_ENVIRONMENT=production||development`)
    * Can be updated at the time of executing the container through environment variables: `--env "PROJECT_ENVIRONMENT=production||development"`

- `$APP_ENV`: Set the environment where the _Laravel_ application will be configured. This variable can be defined at the moment of image build through arguments(`--build-arg APP_ENV=production||local`), or if the image is already created, then it can be replaced by the parameter `--env "APP_ENV=production||local"` when running the container

- The environment variables `${APP_PATH_PREFIX}` and `${DOMAIN_APP}` only serve at the time of creation/build of the image. After the image is created, then these variables have no significance in ENTRYPOINT. It aims to define at the time of image build the value of the `$REMOTE_SRC` variable that this same value will be used in the `WORKDIR $REMOTE_SRC` statement

- `$REMOTE_SRC`
    - Matches the value `${APP_PATH_PREFIX:-/var/www}/${DOMAIN_APP:-appxyz.dev}/`
    - Used in instruction `WORKDIR $REMOTE_SRC` on `Dockerfile`

- `WORKDIR` corresponds to the variable `$REMOTE_SRC` that at the time of image build has its value `${APP_PATH_PREFIX}/${DOMAIN_APP}/`, where the value of `${DOMAIN_APP}` is equal to the value of the `domain_app` argument in the command `make build-app ...`

- `php.ini`: Configured at the time of image build and is set according to the value passed to `$PROJECT_ENVIRONMENT`. If the value of `$PROJECT_ENVIRONMENT` is `development` then `php.ini` will match the files [`php.ini-development.ini`](/app/config/php.ini-development.ini), if the value of `$PROJECT_ENVIRONMENT` is `production` then the contents of `php.ini` will correspond to the file [`php.ini-production.ini`](/app/config/php.ini-production.ini)
    * Can be overridden by volume pointing to the `php.ini` file path: `/usr/local/etc/php/php.ini`

- `php-fpm.conf`: GLOBAL PHP-FPM configuration found `/usr/local/etc/php-fpm.conf`

- `www.conf`: Specific configuration for pool `[www]` found `/usr/local/etc/php-fpm.d/www.conf`

#### Configure/Build

Use the following command to build the image:

```bash
make build-app \
    domain_app=mydomain.com \
    app_env=production||local \
    project_environment=production||development \
    app_image_name=app:3.0 \
    php_base_image_name=app:base
```

If you want to customize the image construction according to your arguments, use the `docker build` command directly:

```bash
docker build -t app:3.0 -f ./app/Dockerfile \
    --build-arg DOMAIN_APP=mydomain.com \
    --build-arg APP_ENV=production \
    --build-arg PHP_BASE_IMAGE=app:base \
    --build-arg APP_PATH_PREFIX=/var/www \
    --build-arg DOCKER_FOLDER_PATH=./docker \
    --build-arg PROJECT_ENVIRONMENT=production \
./../
```

#### Run the application(`docker run`)

> Edit the [ENV variables](/app/app.env) to match the project settings. You can edit/add the environment variables in the `docker-compose.yml` file itself, which has priority over the same variable defined else where (Shell environment variables, Environment file, `Dockerfile`).

To run the service/container through the `run` command of _Docker_ use/customize the following script:

**Note:** You must specify a unique `APP_KEY` including `base64:` prefix generated by `php artisan key:generate` within the container.

```bash
docker run \
        --rm \
        -p 9001:9001 \
        -p 8081:8080 \
            -v $(pwd)/../:/var/www/mydomain.com/ \
            -v $(pwd)/app/docker-entrypoint.sh:/entrypoint.sh:ro \
    --env "REMOTE_SRC=/var/www/mydomain.com/" \
    --env "APP_KEY=SomeRandomString" \
    --env "PROJECT_ENVIRONMENT=development" \
    --env "APP_ENV=local" \
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
        --user 1000:1000 \
        --workdir "/var/www/mydomain.com/" \
        --name=php-fpm \
        --hostname=php-fpm \
        -t app:3.0
```

To run a server with `artisan serve` access the container first:

```bash
docker exec -ti php-fpm bash
```

Inside the container, run the following command to run the PHP built-in server with `artisan serve`:

```bash
php artisan serve --port=8080 --host=0.0.0.0
```

---

- The `--workdir` option of the `docker run` command must have the same value as the variable `$REMOTE_SRC`

- The volume configuration destination `-v $(pwd)/../:/var/www/mydomain.com/` must match the same value of the variable `$REMOTE_SRC`, which must match the same value as `--workdir` in `docker run` or `WORKDIR` statement in _Dockerfile_

### Nginx Webserver

> Image will be used as _REVERSE PROXY_.

- Configuration `ssl_best_practices.conf` and `ssl_common_certificates.conf` to allow only connections over the protocol **HTTPS**
- _Snippet_ `security_http_headers.conf` for best security practices for settings **HTTP HEADERS**
- _Snippet_ `deny_ips.conf` to block brute force attacks or _IPs_ in the blacklist globally on the internet
- _Snippet_ `real_ip.conf` for _PROXY_ configuration. Configuring the real client _IP_
- Control, concurrent connection limitation, to block _HOST_ attacks through `limit_conn` and` limit_req` instructions of _NGINX_
- Use the [Let's Encrypt](https://letsencrypt.org/) to generate SSL certificates and perform the NGINX SSL configuration to use the **HTTPS** protocol
    * Folder `nginx/certs/` should contain the files created by _Let's Encrypt_. It should contain the files: `cert.pem`, `chain.pem`, `dhparam4096.pem`, `fullchain.pem`, `privkey.pem`
- To generate the certificates use or customize the script: `make gen-certs domain_app=mydomain.com`
- There are 4 configurations of _virtual server_, which are: `mydomain.com`, `api.mydomain.com`, `admin.mydomain.com`, `webmail.mydomain.com`. All within the folder `nginx/servers/`

Use the following command to build the image:

```bash
make build-nginx \
    domain_app=mydomain.com \
    nginx_image_name=webserver:3.0 \
    app_image_name=app:3.0
```

- `nginx_image_name`: Parameter used for TAG of the image

- `domain_app`: Domain to be used on the path `${APP_PATH_PREFIX}/${DOMAIN_APP}/`
    * `${APP_PATH_PREFIX}`: Application path prefix that matches the same value in the image [Laravel APP/PHP-FPM](#laravel-appphp-fpm) and its default value is `/var/www`
    * `${DOMAIN_APP}`: Parameter value `domain_app` used in the command `make build-nginx`
    * The same value for the `domain_app` parameter of this same image should match the same value used in the same `domain_app` parameter in the image compilation [Laravel APP/PHP-FPM](#laravel-appphp-fpm), so there is no conflict in the communication of the services of the reverse proxy (NGINX) with the service CGI (PHP-FPM)

To run the service using the `run` command of _Docker_ use/customize the following script:

```bash
docker run \
        --rm \
        -p 80:80 \
        -p 443:443 \
            -v $(pwd)/../:/var/www/mydomain.com/ \
            -v $(pwd)/nginx/docker-entrypoint.sh:/entrypoint.sh:ro \
            -v $(pwd)/nginx/config/nginx.conf:/etc/nginx/nginx.conf:ro \
            -v $(pwd)/nginx/config/servers/:/etc/nginx/servers \
    --env "DOMAIN_APP=mydomain.com" \
    --env "APP_PATH_PREFIX=/var/www" \
        --workdir "/var/www/mydomain.com/" \
        --name=webserver \
        --hostname=webserver \
        -t webserver:3.0
```

To use only the `servers/app.conf`(single domain) configuration of the serves use the [`ONLY_APP`](nginx/docker-entrypoint.sh#L45) option as the environment variable passing its value to `true`:

```bash
docker run \
        --rm \
        -p 80:80 \
        -p 443:443 \
    --env "DOMAIN_APP=mydomain.com" \
    --env "APP_PATH_PREFIX=/var/www" \
    --env "ONLY_APP=true" \
        --workdir "/var/www/mydomain.com/" \
        --name=webserver \
        --hostname=webserver \
        -t webserver:3.0
```

### MySQL

> Container/service will be used to manage the MySQL database.

- The _MySQL_ (my.cnf) settings are set to use [SSL](https://dev.mysql.com/doc/refman/5.7/en/mysql-ssl-rsa-setup.html), then the following instructions are to create the SSL configuration files:

**Creating SSL and RSA Certificates and Keys using MySQL**

```bash
mysql_ssl_rsa_setup --datadir=$(pwd)/mysql/ssl
# Verify a certificate chain
openssl verify -CAfile $(pwd)/mysql/ssl/ca.pem $(pwd)/mysql/ssl/server-cert.pem $(pwd)/mysql/ssl/client-cert.pem
```

[**Creating SSL Certificates and Keys Using openssl**](https://dev.mysql.com/doc/refman/5.7/en/creating-ssl-files-using-openssl.html)

**Important**

_Whatever method you use to generate the certificate and key files, the Common Name value used for the server and client certificates/keys must each differ from the Common Name value used for the CA certificate. Otherwise, the certificate and key files will not work for servers compiled using OpenSSL._

_Use the following information when completing the certificates `CN`:_

```
ca.pem CN/=MySQL_CA_Certificate
server-cert.pem CN/=database
client-cert.pem CN/=MySQL_Client_Certificate
```

```bash
# Create CA certificate
openssl genrsa 2048 > ca-key.pem
openssl req -new -x509 -nodes -days 3600 \
        -key ca-key.pem -out ca.pem \
        -subj "/C=BR/ST=State/L=Locality/O=Organization Name/OU=root/CN=MySQL_CA_Certificate"

# Create server certificate, remove passphrase, and sign it
# server-cert.pem = public key, server-key.pem = private key
openssl req -newkey rsa:2048 -days 1095 \
        -nodes -keyout server-key.pem -out server-req.pem \
        -subj "/C=BR/ST=State/L=Locality/O=Organization Name/OU=server/CN=database"
openssl rsa -in server-key.pem -out server-key.pem
openssl x509 -req -in server-req.pem -days 1095 \
        -CA ca.pem -CAkey ca-key.pem -set_serial 01 -out server-cert.pem

# Create client certificate, remove passphrase, and sign it
# client-cert.pem = public key, client-key.pem = private key
openssl req -newkey rsa:2048 -days 1095 \
        -nodes -keyout client-key.pem -out client-req.pem \
        -subj "/C=BR/ST=State/L=Locality/O=Organization Name/OU=client/CN=MySQL_Client_Certificate"
openssl rsa -in client-key.pem -out client-key.pem
openssl x509 -req -in client-req.pem -days 1095 \
        -CA ca.pem -CAkey ca-key.pem -set_serial 01 -out client-cert.pem
```

- To see the contents of an SSL certificate (for example, to check the range of dates over which it is valid), run openssl directly:

```bash
openssl x509 -text -in ca.pem
openssl x509 -text -in server-cert.pem
openssl x509 -text -in client-cert.pem
```

- It is also possible to check SSL certificate expiration information using this SQL statement:

```bash
mysql> SHOW STATUS LIKE 'Ssl_server_not%';
```

- To find out if SSL is enabled in MySQL, use one of the following commands after logging in to Client-MySQL.

```bash
mysql> SHOW SESSION STATUS LIKE 'Ssl_version';
mysql> show variables like '%ssl%';
mysql> SHOW GLOBAL VARIABLES LIKE '%ssl%';
```

- To run the service/container using the _Docker_ `run` command, use/customize the following script:

```bash
docker run \
        --rm \
        -p 30061:3306 \
            -v $(pwd)/./mysql/ssl/ca.pem:/etc/mysql-ssl/ca.pem:ro \
            -v $(pwd)/./mysql/ssl/server-cert.pem:/etc/mysql-ssl/server-cert.pem:ro \
            -v $(pwd)/./mysql/ssl/server-key.pem:/etc/mysql-ssl/server-key.pem:ro \
            -v $(pwd)/./mysql/my.cnf:/etc/mysql/conf.d/my.cnf:ro \
    --env "MYSQL_DATABASE=app" \
    --env "MYSQL_USER=app" \
    --env "MYSQL_ROOT_PASSWORD=5?qqSm3_@mqrJ_" \
    --env "MYSQL_PASSWORD=TxdITs=CgN9e7+p" \
        --name=database \
        --hostname=database \
        -t mysql:5.7
```

- To access the database via Terminal/Console, use:

```bash
mysql -h 127.0.0.1 -P 30061 -uapp -p'TxdITs=CgN9e7+p' \
        --ssl-ca=mysql/ssl/ca.pem \
        --ssl-cert=mysql/ssl/client-cert.pem \
        --ssl-key=mysql/ssl/client-key.pem
```

### Redis

> Container/service will be used to manage the Redis database. Used for Management of _Queue_, _Sessions_, _Cache_, and many other things in the application that require speed in retrieving/writing information;

- Use the following command to run the Redis container/service via _Docker_ `run` option.

```bash
docker run \
        --rm \
        -p 63781:6379 \
            -v $(pwd)/./redis/redis.conf:/usr/local/etc/redis/redis.conf:ro \
        --name=redis \
        --hostname=redis \
        -t redis:5-alpine redis-server /usr/local/etc/redis/redis.conf --appendonly yes
```

- To access the database _Redis_:

```bash
redis-cli -h 127.0.0.1 -p 63781 -a 'HQD3{9S-u(qnxK@'
```

### MongoDB

> Container/service responsible for managing MongoDB database.

**Creating SSL Files from the Command Line on Unix**

```bash
# Creating own SSL CA to dump our self-signed certificate
openssl genrsa -out rootCA.key 4096
openssl req -nodes -x509 -new -key rootCA.key -days 1825 -out rootCA.pem -subj "/C=BR/ST=State/L=Locality/O=Organization Name/OU=root/CN=MongoDB_CA_Certificate"

# Generate SERVER certificates
openssl genrsa -out server.key 4096
openssl req -new -key server.key -out server.csr -subj "/C=BR/ST=State/L=Locality/O=Organization Name/OU=server/CN=127.0.0.1"
openssl x509 -req -in server.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out server.crt -days 500 -sha256
cat server.key server.crt > server.pem

# Generate client cert to be signed
openssl req -nodes -newkey rsa:4096 -keyout client.key -out client.csr -subj "/C=BR/ST=State/L=Locality/O=Organization Name/OU=client/CN=MongoDB_Client_Certificate"

# Sign the client cert
openssl x509 -req -in client.csr -CA rootCA.pem -CAkey rootCA.key -CAserial rootCA.srl -out client.crt -days 500 -sha256

# Create client PEM file
cat client.key client.crt > client.pem
```

- To run the container using the `run` option in Docker, use the following script:

```bash
docker run \
        --rm \
        -p 29019:27017 \
            -v $(pwd)/./mongodb/mongod.conf:/etc/mongo/mongod.conf:ro \
            -v $(pwd)/./mongodb/mongo-init.js:/docker-entrypoint-initdb.d/mongo-init.js:ro \
            -v $(pwd)/./mongodb/ssl/rootCA.pem:/etc/ssl/ca.pem:ro \
            -v $(pwd)/./mongodb/ssl/server.pem:/etc/ssl/server.pem:ro \
    --env "MONGO_INITDB_ROOT_USERNAME=root" \
    --env "MONGO_INITDB_ROOT_PASSWORD=Y601=lN!JbL6yj18" \
        --name=mongodb \
        --hostname=mongodb \
        -t mongo:4.1 mongod --config /etc/mongo/mongod.conf
```

[Secure your MongoDB connections - SSL/TLS](https://medium.com/@rajanmaharjan/secure-your-mongodb-connections-ssl-tls-92e2addb3c89)

- To access the MongoDB container database:

```bash
mongo --ssl \
      --sslCAFile ./mongodb/ssl/rootCA.pem --sslPEMKeyFile ./mongodb/ssl/client.pem \
      --host 127.0.0.1 --port 29019 -u 'root' -p 'Y601=lN!JbL6yj18' --authenticationDatabase admin
```

### Queue

> Container/service responsible for managing _Queue_ in the application.

Container with **PID 1** executed by **supervisor** to manage processes. Can have two configurations:

- Many processes running in the Laravel `artisan queue:work` for queue management
- Used for debugging and development, the _Horizon_ is a robust and simplistic queue management panel. A single process in a _supervisor_ configuration by running the `artisan horizon` command

**Mandatory environment variables**

- `LARAVEL_QUEUE_MANAGER`: This environment variable defines the container context, and can have the following values:
    *  **worker**:  Configure the _supervisor_ to run many processes in the Laravel command `artisan queue:work`
    * **horizon**: Configure the _supervisor_ to run a single Horizon process `artisan horizon`
- `APP_KEY`: If the application key is not set, your user sessions and other encrypted data will not be secure!
- `APP_ENV`: Configures the environment in which the application will run
- `PROJECT_ENVIRONMENT`: Can be set to two values: `production` and `development`. It aims to define the flow in the file of ENTRYPOINT (`/start.sh`)

**Build**

Use the following script to build the image:

```bash
$ make build-queue app_queue_image_name=app:queue app_image_name=app:3.0
```

**Run**

To run the queue container use the `run` command from docker:

```bash
docker run \
        --rm \
        -p 8081:8080 \
        --workdir "/var/www/mydomain.com/" \
            -v $(pwd)/../:/var/www/mydomain.com/ \
            -v $(pwd)/queue/docker-entrypoint.sh:/start.sh \
            -v $(pwd)/app/config/php.ini-production.ini:/usr/local/etc/php/php.ini:ro \
    --env "APP_ENV=production" \
    --env "PROJECT_ENVIRONMENT=production" \
    --env "APP_KEY=SomeRandomString" \
    --env "CACHE_DRIVER=redis" \
    --env "QUEUE_CONNECTION=redis" \
    --env "BROADCAST_DRIVER=redis" \
    --env "REDIS_PASSWORD=HQD3{9S-u(qnxK@" \
    --env "REDIS_HOST=redis" \
    --env "REDIS_PORT=6379" \
    --env "REDIS_QUEUE=queue_default" \
    --env "DB_HOST=database" \
    --env "DB_PORT=3306" \
    --env "DB_DATABASE=app" \
    --env "DB_USERNAME=app" \
    --env "DB_PASSWORD=TxdITs=CgN9e7+p" \
        --name=app-queue \
        -t app:queue
```

### Scheduler

> Container/service responsible for managing _Scheduler_ in the application.

- Container with **PID 1** executed by **cron**
- Environment variables `APP_KEY` and `APP_ENV` are required when executing the container
- Environment variables available for PHP processes thanks to the `printenv > /etc/environment` script in container entrypoint
- Container run as `root` as a _cron_ service request

_Running a single scheduling command_

```bash
* * * * * {{USER}} /usr/local/bin/php {{REMOTE_SRC}}artisan schedule:run --no-ansi >> /usr/local/var/log/php/cron-laravel-scheduler.log 2>&1
```

**Build**

```bash
$ make build-scheduler app_scheduler_image_name=app:scheduler app_image_name=app:3.0
```

---

## ELK

A set of services that are not in the main `docker-compose.yml` at the root of the project, but is located in the `elastic` folder with its own settings, its own `docker-compose.yml` because it has a level of complexity higher than the other services (MySQL, PHP, Redis ...). It has the following services: `elasticsearch`, `kibana`, `logstash`, `metricbeat`, `filebeat` and `packetbeat`.

### Starting stack

First we need to:

1. Set default password
2. Create keystores to store passwords
3. Install dashboards, index patterns, etc.. for beats and apm

This is accomplished using the `docker-compose-setup.yml` file:

```bash
cd elastic && docker-compose -f docker-compose-setup.yml up && docker-compose up
```

Please take note after the setup completes it will output the password that is used for the `elastic` login.

Now we can launch the stack with `docker-compose up -d` to create a demonstration Elastic Stack with **Elasticsearch**, **Kibana**, **Logstash**, **Metricbeat**, **Filebeat** and **Packetbeat**.

Point a browser at [`http://localhost:56011`](http://localhost:56011) to see the results.

> *NOTE*: Elasticsearch is now setup with self-signed certs.

Log in with `elastic` and what ever your auto generated elastic password is from the setup.

### [Change users password](https://www.elastic.co/guide/en/elastic-stack-overview/master/built-in-users.html#set-built-in-user-passwords)

Login in container:

```bash
docker exec -ti elasticsearch bash
```

Change users password:

```bash
bin/elasticsearch-setup-passwords interactive
```

or

```bash
/usr/local/bin/setup-users.sh
```

### Problems solution

**Deleting the volume from the `elasticsearch` service**

If the main volume of the `elasticsearch` service data is deleted, you should run the` /usr/local/bin/setup-users.sh` script so that users of services that were once configured in the initial SETUP (Kibana, Logstash ...), can be configured again.

_Note: Before running the above script, you must uncomment the environment variable `ELASTIC_PASSWORD: ${ELASTIC_PASSWORD}` from the `elasticsearch` service, so that the password can be configured on users of services that are experiencing connection problems._

_The password in `ELASTIC_PASSWORD` should be the same as the one configured in the initial SETUP, otherwise, there will still be problems in the connections between the service._

## Use Makefile

When developing, you can use [Makefile](https://en.wikipedia.org/wiki/Make_(software)) for doing the following operations:

| Name                | Description                                               |
|---------------------|-----------------------------------------------------------|
| build               | Initializes and configures docker in the application      |
| app-ssl-certs       | Generate LOCAL SSL certificates for single domain         |
| pull                | Download images                                           |
| build-nginx         | Build the NGINX image to act as a reverse proxy           |
| run-nginx           | Create a container for the webserver with docker run      |
| in-nginx            | Access the NGINX container                                |
| build-php           | Build the base image of projects in PHP                   |
| build-full-php      | Build the base image of projects in PHP with all extensions and components enabled by default |
| build-app           | Build the image with settings for Laravel/PHP projects                                        |
| run-app             | Create a container for the application with docker run                                        |
| build-queue         | Build the image to act as queue management. Extends the default project image (build-app)     |
| build-scheduler     | Build the image to act as scheduler management. Extends the default project image (build-app) |
| app-code-phpcs      | Check the APP with PHP Code Sniffer (`PSR2`)                |
| app-code-phpmd      | Analyse the APP with PHP Mess Detector                      |
| docker-clean        | Remove docker images with filter `<none> `                  |
| docker-stop         | Stop and execute $> make docker-clean                       |
| composer-up         | Update PHP dependencies with composer                       |
| gen-certs           | Generate SSL certificates                                   |
| get-certs           | Retrieves certificate expiration dates                      |
| mysql-dump          | Create backup of all databases                              |
| mysql-restore       | Restore backup of all databases                             |

## Troubleshooting

### GNU sed on MAC OS

In Makefile need GNU sed to work so replace BSD sed with GNU sed using:

```bash
brew install gnu-sed
```

Update the default shell (bashrc or zshrc):

```bash
if brew ls --versions gnu-sed > /dev/null; then
  export PATH="$(brew --prefix gnu-sed)/libexec/gnubin:$PATH"
fi
# or
export PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"
```

_Reload shell:_

```bash
source ~/.bashrc
# or
source ~/.zshrc
```

Check you version of sed with:

```bash
man sed
```

sed GNU version path is:

```
$ which sed
/usr/local/opt/gnu-sed/libexec/gnubin/sed
```

Instead of default path of BSD sed (installed by default on MAC OS):

```bash
/usr/bin/sed
```

## Assumptions

- You have **Docker** and **Docker-Compose** installed (Docker for Mac, Docker for Windows, get.docker.com and manual Compose installed for Linux).
- You want to use Docker for local development (i.e. never need to install php or npm on host) and have dev and prod Docker images be as close as possible.
- You don't want to lose fidelity in your dev workflow. You want a easy environment setup, using local editors, debug/inspect, local code repo, while web server runs in a container.
- You use `docker-compose` for local development only (docker-compose was never intended to be a production deployment tool anyway).
- The `docker-compose.yml` is not meant for `docker stack deploy` in Docker Swarm, it's meant for happy local development.

## Helpers commands / Use Docker commands

### Install PHP modules

```bash
docker exec -t -i app /bin/bash
# After
$ /usr/local/bin/docker-php-ext-configure xdebug
$ /usr/local/bin/docker-php-ext-install xdebug
```

### Installing package with composer

```bash
docker run --rm -v $(pwd):/app composer require laravel/horizon
```

### Updating PHP dependencies with composer

```bash
docker run --rm -v $(pwd):/app composer update
```

### Testing PHP application with PHPUnit

```bash
docker-compose exec -T app ./vendor/bin/phpunit --colors=always --configuration ./app
```

### Fixing standard code with [PSR2](https://www.php-fig.org/psr/psr-2/)

```bash
docker-compose exec -T app ./vendor/bin/phpcbf -v --standard=PSR2 ./app
```

### Analyzing source code with [PHP Mess Detector](https://phpmd.org/)

```bash
docker-compose exec -T app ./vendor/bin/phpmd ./app text cleancode,codesize,controversial,design,naming,unusedcode
```

## Contributing

If you find an issue, or have a special wish not yet fulfilled, please [open an issue on GitHub](https://github.com/AllysonSilva/laravel-docker/issues) providing as many details as you can (the more you are specific about your problem, the easier it is for us to fix it).

Pull requests are welcome, too 😁! Also, it would be nice if you could stick to the [best practices for writing Dockerfiles](https://docs.docker.com/articles/dockerfile_best-practices/).

## License

[MIT License](https://github.com/AllysonSilva/laravel-docker/blob/master/LICENSE)
