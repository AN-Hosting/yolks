#!/bin/bash
cd /home/container

# Configuration npm
export NPM_CONFIG_PREFIX=/home/container/.npm
export PATH=$PATH:/home/container/.npm/bin
mkdir -p /home/container/.npm

# Affichage des variables d'environnement de base
export INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')

# Configuration du port React
export PORT=${REACT_PORT}

# Conversion des variables d'environnement en majuscules en minuscules
PARSED=$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g' | eval echo "$(cat -)")

# Affichage des informations de démarrage
echo "🟦 Démarrage du conteneur React..."
echo "🟦 Port configuré: ${PORT}"
echo "🟦 Exécution de la commande: ${PARSED}"

# Installation des dépendances si nécessaire
if [ -f package.json ]; then
    echo "📦 Installation des dépendances..."
    # Configuration de npm pour utiliser le répertoire local
    npm config set prefix '/home/container/.npm'
    npm install --prefix /home/container
fi

# Exécution du serveur
eval ${PARSED} 