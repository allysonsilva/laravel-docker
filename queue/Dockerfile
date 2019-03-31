#####
## APPLICATION QUEUE
#####

ARG APP_IMAGE
FROM ${APP_IMAGE}

# Add label for documentation
LABEL   maintainer="Allyson Silva <support@allyson.tech>" \
        description="Image for manipulation/handling of queues" \
        version="queue"

# Path docker QUEUE folder
# Path Config/Dockerfile QUEUE
ARG DOCKER_QUEUE_PATH=${DOCKER_FOLDER_PATH}/queue
ENV DOCKER_QUEUE_PATH ${DOCKER_QUEUE_PATH}

# Define the running user
USER root

####
## SUPPORT PACKAGES
####

RUN set -ex \
        && apt-get update \
        && apt-get install --no-install-recommends -y \
                python \
                supervisor \
        && mkdir -p /usr/local/var/log/supervisor \
        && apt-get purge -y --auto-remove && rm -rf /var/lib/apt/lists/* \
        && rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin

## SUPERVISOR CONFs
COPY $DOCKER_QUEUE_PATH/config/supervisord.conf /etc/supervisor/supervisord.conf
COPY $DOCKER_QUEUE_PATH/config/templates/* /etc/supervisor/conf.d/

## ENTRYPOINT
COPY $DOCKER_QUEUE_PATH/docker-entrypoint.sh /start.sh
RUN chmod +x /start.sh

# Laravel Schedule Cron Job:
# RUN echo "* * * * * root /usr/local/bin/php /var/www/app/artisan schedule:run >> /dev/null 2>&1"  >> /etc/cron.d/laravel-scheduler
# RUN chmod 0644 /etc/cron.d/laravel-scheduler

####
## PERMISSION
####

RUN set -ex \
        && echo "---> Changing permissions" \
        && chown -R $DEFAULT_USER:$DEFAULT_USER /usr/local/var/log \
                                                /usr/local/var/run \
                                                # /etc/supervisor \
        && chown -R $DEFAULT_USER:$DEFAULT_USER /home/$DEFAULT_USER \
        && chown $DEFAULT_USER:$DEFAULT_USER /start.sh

# Define the running USER
USER $DEFAULT_USER

#############
## ENTRYPOINT
#############

ENTRYPOINT ["/start.sh"]

# Run SUPERVISOR [PID 1]
CMD ["/usr/bin/supervisord", "--nodaemon", "--configuration", "/etc/supervisor/supervisord.conf"]

# vim:set ft=dockerfile:
