# My Docker Environment ⚡️

> This is a personal collection of Docker tools and images.

## Install Docker

- [Ubuntu](https://docs.docker.com/engine/installation/linux/ubuntu/)
- [Windows](https://docs.docker.com/docker-for-windows/install/)
- [MacOS](https://docs.docker.com/docker-for-mac/install/)

> Download and install [Docker](https://docs.docker.com/engine/installation/) (**>= 18.03**) for your platform and you also have to install [Docker compose](https://docs.docker.com/compose/install/) (**>= 1.20.0**).

## Project structure

```
├── app
└── docker
    ├── docker-compose.yml
    ├── nginx
    │   ├── Dockerfile
    │   ├── config
    │   │   ├── fastcgi.conf
    │   │   ├── mime.types
    │   │   ├── nginx.conf
    │   │   └── servers
    │   │       └── app.conf
    │   └── docker-entrypoint.sh
    └── php
        └── 7.2
            ├── Dockerfile
            ├── config
            │   ├── extensions
            │   │   ├── opcache.ini
            │   │   └── xdebug.ini
            │   ├── fpm
            │   │   ├── php-fpm.conf
            │   │   └── www.conf
            │   └── php.ini-development.ini
            ├── docker-entrypoint.sh
            └── samples
                ├── bashrc
                └── composer.json
```

## Softwares included:

- *`Nginx`* 1.13.x
- *`PHP`* 7.2.x [**Installed PHP extensions**] (The following modules and extensions have been enabled,
in addition to those you can already find in the [official PHP image](https://hub.docker.com/r/_/php/))
    - **`amqp`**
    - `bcmath`
    - `calendar`
    - `Core`
    - `ctype`
    - `curl`
    - `date`
    - `dom`
    - **`ds`**
    - `exif`
    - `fileinfo`
    - `filter`
    - `ftp`
    - `gd`
    - `gettext`
    - `gmp`
    - `hash`
    - `iconv`
    - **`igbinary`**
    - `intl`
    - `json`
    - `libxml`
    - **`lzf`**
    - `mbstring`
    - **`meminfo`**
    - **`mongodb`**
    - `mysqli`
    - `mysqlnd`
    - `openssl`
    - `pcntl`
    - `pcre`
    - `PDO`
    - `pdo_mysql`
    - `pdo_sqlite`
    - **`pdo_sqlsrv`**
    - `Phar`
    - `posix`
    - `readline`
    - **`redis`**
    - **`ref`**
    - `Reflection`
    - `session`
    - `shmop`
    - `SimpleXML`
    - `soap`
    - `sockets`
    - `sodium`
    - `SPL`
    - `sqlite3`
    - **`sqlsrv`**
    - `standard`
    - **`swoole`**
    - `tidy`
    - `tokenizer`
    - **`xdebug`**
    - `xml`
    - `xmlreader`
    - `xmlwriter`
    - `xsl`
    - `zip`
    - `zlib`
    - **`Xdebug`**
    - **`Zend OPcache`**

You are able to find all installed PHP extensions by running `php -m` inside your workspace.

### Available tools

*Composer* - https://getcomposer.org/

> Composer helps you declare, manage and install dependencies of PHP projects.

*PHPUnit – The PHP Testing Framework* - https://phpunit.de/

> PHPUnit is a programmer-oriented testing framework for PHP. It is an instance of the xUnit architecture for unit testing frameworks.

*prestissimo* - https://github.com/hirak/prestissimo

> composer parallel install plugin.

*PHP Coding Standards Fixer* - http://cs.sensiolabs.org/

> The PHP Coding Standards Fixer tool fixes most issues in your code when you want to follow the PHP coding standards
as defined in the PSR-1 and PSR-2 documents and many more.

*PHP CodeSniffer* - https://github.com/squizlabs/PHP_CodeSniffer

> PHP_CodeSniffer is a set of two PHP scripts; the main `phpcs` script that tokenizes PHP, JavaScript and CSS files to detect violations of a defined coding standard, and a second `phpcbf` script to automatically correct coding standard violations. PHP_CodeSniffer is an essential development tool that ensures your code remains clean and consistent.

## Getting Started

If this was your app, to start local development you would:

 - Running `docker-compose up` is all you need. It will:
 - Build custom local image enabled for development.
 - Start container from that image with ports `8800:80` and `8443:443` open (on localhost or docker-machine).
 - Mounts the pwd to the app dir in container.
 - If you need other services like databases, just add to compose file and they'll be added to the custom Docker network for this app on `up`.
 - If you need to add packages to Composer, npm, bower, etc. then stop docker-compose and run `docker-compose up --build` to ensure image is updated.
 - Be sure to use `docker-compose down` to cleanup after your done dev'ing.

## Assumptions

 - You have Docker and Docker-Compose installed (Docker for Mac, Docker for Windows, get.docker.com and manual Compose installed for Linux).
 - You want to use Docker for local development (i.e. never need to install php or npm on host) and have dev and prod Docker images be as close as possible.
 - You don't want to lose fidelity in your dev workflow. You want a easy environment setup, using local editors, debug/inspect, local code repo, while web server runs in a container.
 - You use `docker-compose` for local development only (docker-compose was never intended to be a production deployment tool anyway).
 - The `docker-compose.yml` is not meant for `docker stack deploy` in Docker Swarm, it's meant for happy local development.

## Contributing

If you find an issue, or have a special wish not yet fulfilled, please [open an issue on GitHub](https://github.com/AllysonSilva/docker/issues) providing as many details as you can (the more you are specific about your problem, the easier it is for us to fix it).

Pull requests are welcome, too 😁! Also, it would be nice if you could stick to the [best practices for writing Dockerfiles](https://docs.docker.com/articles/dockerfile_best-practices/).

## License

[MIT License](https://github.com/AllysonSilva/docker/blob/master/LICENSE)
