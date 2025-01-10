FROM ghcr.io/an-hosting/installers:debian

LABEL maintainer="your-email@example.com"
LABEL org.opencontainers.image.source="https://github.com/your-repo/your-project"

USER root
ENV DEBIAN_FRONTEND=noninteractive

# Installation de Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get update \
    && apt-get install -y \
        nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Vérification des versions
RUN node --version && npm --version

# Copie et configuration de l'entrypoint avant de changer d'utilisateur
COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Configuration de l'utilisateur à la fin
USER container
WORKDIR /home/container

CMD ["/bin/bash", "/entrypoint.sh"] 