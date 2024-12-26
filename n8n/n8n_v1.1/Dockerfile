FROM docker.n8n.io/n8nio/n8n:1.1.0

LABEL author="AN-Hosting" maintainer="contact@an-hosting.fr"

# Installation des dépendances système nécessaires
RUN apt-get update && apt-get install -y \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Création du dossier pour les données persistantes
RUN mkdir -p /home/node/.n8n

# Configuration des variables d'environnement par défaut
ENV NODE_ENV=production \
    DB_TYPE=sqlite \
    N8N_PORT=5678 \
    WEBHOOK_URL=http://localhost:5678/ \
    GENERIC_TIMEZONE="UTC"

# Exposition du port
EXPOSE 5678

# Point d'entrée pour démarrer n8n
COPY ../entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"] 