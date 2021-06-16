ARG TAG_APP_IMAGE
FROM ${TAG_APP_IMAGE} as APP_IMAGE

FROM nginx:1.20-alpine

# Remove default files
RUN set -xe \
    && rm /etc/nginx/fastcgi_params \
    && rm /etc/nginx/scgi_params \
    && rm /etc/nginx/uwsgi_params \
    && rm -rf /etc/nginx/conf.d \
    && mkdir -p /usr/local/etc

RUN set -xe; \
    \
    echo; \
    echo "#####################################"; \
    echo "---> Installing Packages Dependencies"; \
    echo "#####################################"; \
    echo; \
    \
    apk --update upgrade --no-cache -q; \
    \
    apk add --no-cache \
    # --repository=http://dl-cdn.alpinelinux.org/alpine/edge/main \
    # --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community \
        git \
        exa \
        fzf \
        zsh \
        zsh-autosuggestions \
        zsh-syntax-highlighting \
        sudo \
        vim \
        curl \
        wget \
        bash \
        tzdata \
        openssl \
        openssh \
        coreutils \
        logrotate \
        moreutils \
        ca-certificates \
        bash-completion; \
    \
    rm -rf /tmp/* /var/cache/apk/*

RUN set -e; \
    \
    sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"; \
    \
    echo >> ~/.zshrc; \
    echo "source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ~/.zshrc; \
    echo "source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" >> ~/.zshrc; \
    \
    sed -i \
        -e "/^ZSH_THEME.*/c\\ZSH_THEME=\"agnoster\"" \
        -e "/^plugins=.*/c\\plugins=(git fzf)" \
    ~/.zshrc

ARG MAXMIND_VERSION=1.6.0
ENV MAXMIND_VERSION $MAXMIND_VERSION

ARG GEOIPUPDATE_VERSION=4.7.1
ENV GEOIPUPDATE_VERSION $GEOIPUPDATE_VERSION

RUN set -xe; \
    \
    echo; \
    echo "###################################################"; \
    echo "---> Install C Library For Reading MaxMind DB Files"; \
    echo "###################################################"; \
    echo; \
    \
    apk update; \
    # echo "http://dl-cdn.alpinelinux.org/alpine/v3.13/main" >> /etc/apk/repositories; \
    # echo "http://dl-cdn.alpinelinux.org/alpine/v3.13/community" >> /etc/apk/repositories; \
    # # echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories; \
    \
    apk add --no-cache --virtual .build-deps \
        perl-dev \
        alpine-sdk \
    ; \
    mkdir -p /usr/local/etc /usr/local/share/GeoIP \
    ; \
    # Install C library for reading MaxMind DB files
    wget https://github.com/maxmind/libmaxminddb/releases/download/${MAXMIND_VERSION}/libmaxminddb-${MAXMIND_VERSION}.tar.gz \
    && tar xf libmaxminddb-${MAXMIND_VERSION}.tar.gz \
    && cd libmaxminddb-${MAXMIND_VERSION} \
    && ./configure \
    && make \
    && make check \
    && make install \
    && cd .. ; rm -rf ./libmaxminddb* \
    ; \
    # `geoipupdate` automatically updates GeoIP2, GeoLite2, and GeoIP Legacy databases.
    # The program connects to the MaxMind GeoIP Update server to check for new databases.
    # If a new database is available, the program will download and install it.
    wget https://github.com/maxmind/geoipupdate/releases/download/v${GEOIPUPDATE_VERSION}/geoipupdate_${GEOIPUPDATE_VERSION}_linux_amd64.tar.gz -O geoipupdate-${GEOIPUPDATE_VERSION}.tar.gz \
    && tar xf geoipupdate-${GEOIPUPDATE_VERSION}.tar.gz \
    && cp geoipupdate_${GEOIPUPDATE_VERSION}_linux_amd64/geoipupdate /usr/local/bin \
    && cp geoipupdate_${GEOIPUPDATE_VERSION}_linux_amd64/GeoIP.conf /usr/local/etc \
    && rm -rf ./geoipupdate* \
    && which mmdblookup && which geoipupdate \
    \
    ; \
    apk add --no-cache --virtual .gettext gettext; \
    mv /usr/bin/envsubst /tmp/; \
    runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' --recursive /usr/local /usr/sbin/nginx /usr/lib/nginx/modules/*.so /tmp/envsubst \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )"; \
    apk add --no-cache $runDeps; \
    apk del --no-network .build-deps; \
    apk del --no-network .gettext; \
    mv /tmp/envsubst /usr/local/bin/; \
    rm -rf /tmp/* /var/cache/apk/*

# TODO: fix issue with non zero return code
RUN ldconfig || :

ARG NGX_GEOIP2_MODULE_TAG=3.3
ENV NGX_GEOIP2_MODULE_TAG $NGX_GEOIP2_MODULE_TAG

RUN set -xe; \
    \
    echo; \
    echo "###################################################"; \
    echo "---> Installing GeoIP2/Ngx Header More Module NGINX"; \
    echo "###################################################"; \
    echo; \
    \
    git clone --branch ${NGX_GEOIP2_MODULE_TAG} --single-branch https://github.com/leev/ngx_http_geoip2_module /ngx_http_geoip2_module >/dev/null 2>&1; \
    git clone --branch v0.33 --depth 1 https://github.com/openresty/headers-more-nginx-module /headers-more-nginx-module >/dev/null 2>&1; \
    \
    apk update; \
    \
    apk add --no-cache --virtual .build-deps \
        gcc \
        make \
        gnupg1 \
        pcre-dev \
        libc-dev \
        zlib-dev \
        perl-dev \
        alpine-sdk \
        linux-headers \
    \
    && curl -fSL https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz -o nginx.tar.gz \
    && curl -fSL https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz.asc -o nginx.tar.gz.asc \
    # && curl -fSL https://github.com/leev/ngx_http_geoip2_module/archive/$NGX_GEOIP2_MODULE_TAG.tar.gz -o geoip2.tar.gz \
    \
    && tempDir="$(mktemp -d)" \
    && export GNUPGHOME=$tempDir \
    && curl -sS https://nginx.org/keys/mdounin.key | gpg --import \
    && gpg --batch --verify nginx.tar.gz.asc nginx.tar.gz \
    && rm -rf "$GNUPGHOME" nginx.tar.gz.asc && unset GNUPGHOME \
    \
    && mkdir -p /usr/src \
    && tar -zxC /usr/src -f nginx.tar.gz \
    && rm nginx.tar.gz \
    \
    && cd /usr/src/nginx-$NGINX_VERSION \
    && ./configure --add-dynamic-module=/ngx_http_geoip2_module --add-dynamic-module=/headers-more-nginx-module $(nginx -V) --with-stream --with-compat \
    && make -j$(getconf _NPROCESSORS_ONLN) && make modules \
    && modulesPath="/usr/lib/nginx/modules" \
    && mv objs/ngx_http_geoip2_module.so $modulesPath \
    && mv objs/ngx_stream_geoip2_module.so $modulesPath \
    && mv objs/ngx_http_headers_more_filter_module.so $modulesPath \
    \
    && cd / \
    && rm -rf /usr/src/nginx-$NGINX_VERSION /ngx_http_geoip2_module \
    \
    # Bring in gettext so we can get `envsubst`, then throw
    # the rest away. To do this, we need to install `gettext`
    # then move `envsubst` out of the way so `gettext` can
    # be deleted completely, then move `envsubst` back.
    && apk add --no-cache --virtual .gettext gettext \
    && mv /usr/bin/envsubst /tmp/ \
    \
    && runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' --recursive /usr/local /usr/sbin/nginx /usr/lib/nginx/modules/*.so /tmp/envsubst \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )" \
    && apk add --no-cache $runDeps \
    && apk del --no-network .build-deps \
    && apk del --no-network .gettext \
    && mv /tmp/envsubst /usr/local/bin/ \
    && rm -rf /tmp/* /var/cache/apk/*

ARG USER_NAME=app
ENV USER_NAME $USER_NAME

ARG GROUP_NAME=app
ENV GROUP_NAME $GROUP_NAME

ARG USER_UID=1000
ARG USER_GID=1000

ARG APP_PATH_SRC
ENV APP_PATH_SRC $APP_PATH_SRC

ENV HOME_USER=/home/$USER_NAME

ENV LANG="en_US.UTF-8" \
    LANGUAGE="en_US:en" \
    LC_ALL="en_US.UTF-8" \
    TERM=xterm-256color \
    COLORTERM=truecolor

RUN if [ "$USER_UID" != 1000 ]; then \
        set -xe \
            && echo \
            && echo "---> Adding the www-data(1000) user" \
            && echo \
            && deluser --remove-home www-data || true \
            && delgroup www-data || true \
            && addgroup --gid 1000 www-data \
            && adduser --gecos "" --disabled-password --uid 1000 --ingroup www-data --shell /bin/bash www-data \
            && echo "www-data ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers \
            && chown -R www-data:www-data /home/www-data \
    ;fi

RUN set -xe; \
    addgroup --gid ${USER_GID:-1000} $GROUP_NAME; \
    addgroup root $GROUP_NAME; \
    adduser --gecos "" --disabled-password --uid ${USER_UID:-1000} --ingroup $GROUP_NAME --home $HOME_USER --shell /bin/bash $USER_NAME; \
    echo "$USER_NAME ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers

COPY ./logrotate/cronjob /home/${USER_NAME}/logrotate/
COPY ./logrotate/logrotate.conf /home/${USER_NAME}/logrotate/
COPY ./logrotate/conf.d/* /home/${USER_NAME}/logrotate/conf.d/
COPY ./geoip2/cronjob /home/${USER_NAME}/geoip2/

RUN set -xe; \
    \
    # ps -ef | grep cron | grep -v grep
    echo; \
    echo "###########################"; \
    echo "---> Create Logs/Cron Files"; \
    echo "###########################"; \
    echo; \
    \
    touch /var/log/cron.log; \
    touch /var/log/commands.log; \
    touch /var/log/GeoIP.log; \
    touch /var/log/logrotate.log; \
    \
    mkdir -p /var/spool/cron/crontabs; \
    \
    touch /var/spool/cron/crontabs/$USER_NAME

RUN set -xe; \
    \
    echo; \
    echo "#####################"; \
    echo "---> Logrotate Config"; \
    echo "#####################"; \
    echo; \
    \
    LOGROTATE_PATH=/home/$USER_NAME/logrotate; \
    mkdir -p $LOGROTATE_PATH; \
    touch $LOGROTATE_PATH/status; \
    \
    mkdir -p /var/log/rotate; \
    mkdir -p /var/log/nginx/rotate; \
    \
    rm -f /etc/periodic/daily/logrotate; \
    rm -rf /etc/logrotate.*;

# UPDATE THESE TO YOUR OWN. DO NOT USE THESE, both must be in base64 format
ARG SSH_PUBLIC_KEY=UFVUX1lPVVJfUFVCTElDX0tFWV9IRVJF
ARG SSH_PRIVATE_KEY=UFVUX1lPVVJfUFVCTElDX0tFWV9IRVJF

RUN set -xe; \
    \
    echo; \
    echo "###################################"; \
    echo "---> Configuring SSL for use in GIT"; \
    echo "###################################"; \
    echo; \
    \
    mkdir ~/.ssh; \
    # Create known_hosts
    touch ~/.ssh/known_hosts; \
    # Create public and private keys
    touch ~/.ssh/id_rsa.pub && touch ~/.ssh/id_rsa; \
    # Add the keys and set permissions | Setup source ssh private and public keys
    echo ${SSH_PUBLIC_KEY} | base64 --decode >> ~/.ssh/id_rsa.pub && chmod 700 ~/.ssh/id_rsa.pub; \
    echo ${SSH_PRIVATE_KEY} | base64 --decode >> ~/.ssh/id_rsa && chmod 700 ~/.ssh/id_rsa; \
    \
    # Add github and bitbuckets key fingerprint to known hosts | Authorize SSH Host
    ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts; \
    ssh-keyscan -t rsa bitbucket.org >> ~/.ssh/known_hosts; \
    \
    # Remove host checking
    touch ~/.ssh/config && chmod 400 ~/.ssh/config; \
    echo "Host github.com\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config; \
    echo "Host bitbucket.org\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config
    # ; \
    # eval `ssh-agent`; \
    # ssh-add ~/.ssh/id_rsa ; ssh-add -l

RUN set -xe; \
    mkdir -p /var/www; \
    touch /var/run/nginx.pid; \
    # Replace it with /bin/zsh:
    sed -i "/root/s/bin\/ash/bin\/zsh/g" /etc/passwd

# Let's Encrypt
RUN set -xe; \
    mkdir -p /var/www/letsencrypt/challenges; \
    chgrp $USER_NAME /var/www/letsencrypt; \
    chmod g+s /var/www/letsencrypt

ARG TZ=America/Fortaleza

RUN set -xe \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
    && unlink /var/log/nginx/access.log \
    && unlink /var/log/nginx/error.log \
    && touch /var/log/nginx/access.stdout.log \
    && touch /var/log/nginx/error.stderr.log \
    && ln -sf /dev/stdout /var/log/nginx/access.stdout.log \
    && ln -sf /dev/stderr /var/log/nginx/error.stderr.log

COPY --from=APP_IMAGE --chown=nginx:nginx $APP_PATH_SRC/public $APP_PATH_SRC/public
COPY --from=APP_IMAGE --chown=nginx:nginx $APP_PATH_SRC/storage $APP_PATH_SRC/storage

RUN set -xe; \
    cd $APP_PATH_SRC/storage; \
    ls --hide=app | xargs rm -rf; \
    cd $APP_PATH_SRC; \
    chown -R $USER_NAME:$GROUP_NAME $APP_PATH_SRC

COPY ./configs/ /etc/nginx/

RUN set -xe; \
    chown -R $USER_NAME:$GROUP_NAME \
        /etc/nginx \
        /var/log \
        /var/run /var/run/ \
        /var/cache/nginx \
        /var/www \
        $HOME_USER

# Expose webserver port
EXPOSE 80 443 7080 8098 8099 8443

COPY ./docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /etc/nginx/

VOLUME ["/var/log", "/usr/local/share/GeoIP"]

ENTRYPOINT ["/entrypoint.sh"]

# @see https://ubuntu.com/blog/avoiding-dropped-connections-in-nginx-containers-with-stopsignal-sigquit
STOPSIGNAL SIGQUIT

CMD ["nginx", "-g", "daemon off;"]

# vim:set ft=dockerfile:
