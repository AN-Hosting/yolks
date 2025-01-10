#!/bin/bash
cd /home/container

# Affichage des variables d'environnement de base
export INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')

# Configuration du port React
export PORT=${SERVER_PORT}

# Conversion des variables d'environnement en majuscules en minuscules
PARSED=$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g' | eval echo "$(cat -)")

# Affichage des informations de démarrage
echo "🟦 Démarrage du conteneur React..."
echo "🟦 Port configuré: ${PORT}"
echo "🟦 Exécution de la commande: ${PARSED}"

# Installation des dépendances si nécessaire
if [ -f package.json ]; then
    echo "📦 Installation des dépendances..."
    npm install
fi

# Exécution du serveur
eval ${PARSED} 