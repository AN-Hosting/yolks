FROM        --platform=$TARGETOS/$TARGETARCH debian:bookworm-slim

LABEL       author="David Wolfe (Red-Thirten)" maintainer="red_thirten@yahoo.com"

LABEL       org.opencontainers.image.source="https://github.com/pelican-eggs/yolks"
LABEL       org.opencontainers.image.licenses=MIT

## Update base packages and install dependencies
ENV         DEBIAN_FRONTEND=noninteractive
RUN         dpkg --add-architecture i386 \
            && apt update \
            && apt upgrade -y \
            && apt install -y \
                curl \
                tzdata \
                locales \
                iproute2 \
                gettext-base \
                ca-certificates \
                libssl-dev \
                lib32gcc-s1 \
                libsdl2-2.0-0 \
                libsdl2-2.0-0:i386 \
                libstdc++6 \
                libstdc++6:i386 \
                lib32stdc++6 \
                libcap2 \
                libnss-wrapper \
                tini \
                procps \
            && rm -rf /var/lib/apt/lists/*

## Install and configure busybox
RUN         apt update \
            && apt install -y busybox-static \
            && mkdir -p /usr/local/bin \
            && ln -sf /bin/busybox /usr/local/bin/crond \
            && ln -sf /bin/busybox /usr/local/bin/crontab \
            && rm -rf /var/lib/apt/lists/*

## Install bercon directly from GitHub releases
RUN         curl -#SfLo /usr/bin/bercon \
            https://github.com/WoozyMasta/bercon/releases/latest/download/bercon \
            && chmod +x /usr/bin/bercon

## Configure locale
RUN         update-locale lang=en_US.UTF-8 \
            && dpkg-reconfigure --frontend noninteractive locales

## Prepare NSS Wrapper for the entrypoint as a workaround for DayZ requiring a valid UID
ENV         NSS_WRAPPER_PASSWD=/tmp/passwd NSS_WRAPPER_GROUP=/tmp/group
RUN         touch ${NSS_WRAPPER_PASSWD} ${NSS_WRAPPER_GROUP} \
            && chgrp 0 ${NSS_WRAPPER_PASSWD} ${NSS_WRAPPER_GROUP} \
            && chmod g+rw ${NSS_WRAPPER_PASSWD} ${NSS_WRAPPER_GROUP}
ADD         passwd.template /passwd.template

## Setup user and working directory
RUN         useradd -m -d /home/container -s /bin/bash container

## Setup cron directories and permissions
RUN         mkdir -p /home/container/cron \
            && chown -R container:container /home/container/cron \
            && chmod -R 755 /home/container/cron \
            && mkdir -p /var/spool/cron/crontabs \
            && chown -R container:container /var/spool/cron \
            && chmod -R 0777 /var/spool/cron/crontabs

## Copy scripts before changing user
COPY        --chown=container:container ./entrypoint.sh /entrypoint.sh
RUN         chmod +x /entrypoint.sh

## Create log directory
RUN         mkdir -p /home/container/logs \
            && chown -R container:container /home/container/logs

USER        container
ENV         USER=container HOME=/home/container
WORKDIR     /home/container

## Add environment variables for bercon
## Note: RCON_PORT and RCON_PASSWORD are provided by Pterodactyl
ENV         BERCON_IP=127.0.0.1
ENV         BERCON_TIMEOUT=5000
ENV         BERCON_KEEPALIVE=30

## Create required cron directories
RUN         mkdir -p /home/container/cron/crontabs \
            && mkdir -p /home/container/cron/cronstamps

STOPSIGNAL  SIGINT

ENTRYPOINT  ["/usr/bin/tini", "-g", "--"]
CMD         ["/entrypoint.sh"]
