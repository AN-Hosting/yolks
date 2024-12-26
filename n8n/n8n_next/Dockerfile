FROM docker.n8n.io/n8nio/n8n:next 
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
    N8N_PORT=5678 \
    WEBHOOK_URL=http://localhost:5678/ \
    GENERIC_TIMEZONE="UTC" \
    HOME=/home/container \
    USER=container \
    N8N_USER_FOLDER=/home/container/.n8n \
    N8N_SECURE_COOKIE=false \
    N8N_PROTOCOL=http \
    NODE_TLS_REJECT_UNAUTHORIZED=0 \
    N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true

# Exposition du port
EXPOSE 5678

WORKDIR /home/container 