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
                cron \
            && rm -rf /var/lib/apt/lists/*

## install rcon client (bercon)
RUN         cd /tmp/ \
            && curl -sSL https://github.com/WoozyMasta/bercon/releases/download/1.0.0/bercon > bercon \
            && mv bercon /usr/local/bin/ \
            && chmod +x /usr/local/bin/bercon

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

## Setup cron after user creation
RUN         mkdir -p /var/spool/cron/crontabs \
            && touch /var/spool/cron/crontabs/container \
            && chmod 600 /var/spool/cron/crontabs/container \
            && chown container:container /var/spool/cron/crontabs/container \
            && chmod g+rx /var/spool/cron \
            && chmod g+rx /var/spool/cron/crontabs

## Copy scripts before changing user
COPY        --chown=container:container ./entrypoint.sh /entrypoint.sh
COPY        --chown=container:container ./restart_dayz.sh /home/container/
RUN         chmod +x /entrypoint.sh && chmod +x /home/container/restart_dayz.sh

USER        container
ENV         USER=container HOME=/home/container
WORKDIR     /home/container

STOPSIGNAL  SIGINT

ENTRYPOINT  ["/usr/bin/tini", "-g", "--"]
CMD         ["/entrypoint.sh"]
