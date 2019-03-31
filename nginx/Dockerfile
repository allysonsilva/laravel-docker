ARG TAG_APP_IMAGE
FROM ${TAG_APP_IMAGE} as APP_IMAGE

FROM nginx:1.15

ARG BUILD_DATE
ARG VCS_REF

# If an ARG instruction has a default value and if there is no value passed at build-time, the builder uses the default
ARG DOMAIN_APP
# Unlike an ARG instruction, ENV values are always persisted in the built image
ENV DOMAIN_APP ${DOMAIN_APP:-app.com}

# Application prefix path
ARG APP_PATH_PREFIX
ENV APP_PATH_PREFIX ${APP_PATH_PREFIX:-/var/www}

COPY --from=APP_IMAGE ${APP_PATH_PREFIX}/${DOMAIN_APP} ${APP_PATH_PREFIX}/${DOMAIN_APP}

LABEL   maintainer="Allyson Silva <support@allyson.tech>" \
        description="Image for handling requests, server requests" \
        version="nginx" \
        org.label-schema.build-date=$BUILD_DATE \
        org.label-schema.name="nginx" \
        org.label-schema.description="Image for handling requests, server requests" \
        org.label-schema.vcs-ref=$VCS_REF \
        org.label-schema.vcs-url="https://github.com/AllysonSilva/docker"

RUN set -x \
        && apt-get update \
        && apt-get install --no-install-recommends --no-install-suggests -y vim wget curl openssl \
        && apt-get remove --purge --auto-remove -y && rm -rf /var/lib/apt/lists/*

COPY ./certs/ /etc/nginx/certs
COPY ./config/ /etc/nginx/
COPY ./helpers/ /usr/local/bin/

# Remove default files
RUN set -ex \
        && rm /etc/nginx/fastcgi_params \
        && rm /etc/nginx/koi-utf \
        && rm /etc/nginx/koi-win \
        && rm /etc/nginx/scgi_params \
        && rm /etc/nginx/uwsgi_params \
        && rm /etc/nginx/win-utf \
        && rm -rf /etc/nginx/conf.d

# Expose webserver port
EXPOSE 80 443

COPY ./docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /etc/nginx/

# Environment variables
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

ENTRYPOINT ["/entrypoint.sh"]

CMD ["nginx", "-g", "daemon off;"]

# vim:set ft=dockerfile:
