FROM docker.n8n.io/n8nio/n8n:1.0.0

LABEL author="AN-Hosting" maintainer="contact@an-hosting.fr"

# Passage en root pour l'installation des paquets
USER root

# Installation des dépendances système nécessaires
RUN apk add --no-cache \
    curl

# Création du dossier pour les données persistantes
RUN mkdir -p /home/node/.n8n && \
    chown -R node:node /home/node/.n8n

# Copie et configuration de l'entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && \
    chown node:node /entrypoint.sh

# Retour à l'utilisateur node
USER node

# Configuration des variables d'environnement par défaut
ENV NODE_ENV=production \
    DB_TYPE=sqlite \
    N8N_PORT=5678 \
    WEBHOOK_URL=http://localhost:5678/ \
    GENERIC_TIMEZONE="UTC"

# Exposition du port
EXPOSE 5678

ENTRYPOINT ["/entrypoint.sh"] 