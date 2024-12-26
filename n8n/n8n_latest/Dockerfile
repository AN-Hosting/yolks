FROM docker.n8n.io/n8nio/n8n:latest 

LABEL author="AN-Hosting" maintainer="contact@an-hosting.fr"

USER root

# Installation des dépendances système nécessaires
RUN apk add --no-cache \
    curl \
    openssh

# Création de l'utilisateur et des dossiers nécessaires
RUN adduser -D -h /home/container container && \
    mkdir -p /home/container/.n8n && \
    chown -R container:container /home/container

USER container

# Configuration des variables d'environnement par défaut
ENV NODE_ENV=production \
    DB_TYPE=sqlite \
    WEBHOOK_URL="http://${SERVER_IP}:${SERVER_PORT}/" \
    GENERIC_TIMEZONE="UTC" \
    HOME=/home/container \
    USER=container \
    N8N_USER_FOLDER=/home/container/.n8n \
    N8N_SECURE_COOKIE=false \
    N8N_PROTOCOL=http \
    NODE_TLS_REJECT_UNAUTHORIZED=0 \
    N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true

# Exposition du port (sera remplacé par Pterodactyl)
EXPOSE ${SERVER_PORT}

WORKDIR /home/container 