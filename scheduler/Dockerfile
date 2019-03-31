#####
## APPLICATION SCHEDULER
#####

ARG APP_IMAGE
FROM ${APP_IMAGE}

# Add label for documentation
LABEL   maintainer="Allyson Silva <support@allyson.tech>" \
        description="Image for manipulation/handling of Scheduler/Cron" \
        version="scheduler"

# Define the running user
USER root

# Path docker SCHEDULER folder
# Path Config/Dockerfile SCHEDULER
ARG DOCKER_SCHEDULER_PATH=${DOCKER_FOLDER_PATH}/scheduler
ENV DOCKER_SCHEDULER_PATH ${DOCKER_SCHEDULER_PATH}

####
## SUPPORT PACKAGES
####

RUN set -ex \
        && apt-get update \
        && apt-get install --no-install-recommends -y \
                cron \
        && apt-get purge -y --auto-remove && rm -rf /var/lib/apt/lists/* \
        && rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin

## Add crontab file in the cron directory
COPY ${DOCKER_SCHEDULER_PATH}/cron-jobs/* /etc/cron.d/
# Give execution rights on the cron job
RUN find /etc/cron.d/ -type f -exec chmod 644 {} \;
# Create the log file to be able to run tail
RUN touch /var/log/cron.log

## ENTRYPOINT
COPY $DOCKER_SCHEDULER_PATH/docker-entrypoint.sh /start.sh
RUN chmod +x /start.sh

####
## PERMISSION
####

RUN set -ex \
        && echo "---> Changing permissions" \
        && chown -R $DEFAULT_USER:$DEFAULT_USER /usr/local/var/log \
                                                /var/log \
                                                /var/run \
        && chown -R $DEFAULT_USER:$DEFAULT_USER /home/$DEFAULT_USER \
        && chown $DEFAULT_USER:$DEFAULT_USER /start.sh

# Define the running USER
# USER $DEFAULT_USER

#############
## ENTRYPOINT
#############

ENTRYPOINT ["/start.sh"]

# As non daemon and single base image, it may be used as cli container
# CMD ["/bin/bash"]

CMD ["/usr/sbin/cron", "-f", "-L", "/var/log/cron.log"]

# vim:set ft=dockerfile:
