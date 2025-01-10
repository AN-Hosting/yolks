FROM ghcr.io/an-hosting/yolks:nodejs_23

LABEL maintainer="your-email@example.com"
LABEL org.opencontainers.image.source="https://github.com/your-repo/your-project"

USER root
ENV DEBIAN_FRONTEND=noninteractive

# Mise à jour des paquets et nettoyage
RUN apt-get update \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copie et configuration de l'entrypoint
COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Configuration de l'utilisateur
USER container
ENV HOME=/home/container
WORKDIR /home/container

CMD ["/bin/bash", "/entrypoint.sh"] 