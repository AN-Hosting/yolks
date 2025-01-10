#!/bin/bash
cd /home/container

# Affichage des variables d'environnement de base
export INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')

# Configuration du port React
export PORT=${REACT_PORT}

# Conversion des variables d'environnement en majuscules en minuscules
PARSED=$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g' | eval echo "$(cat -)")

# Affichage des informations de démarrage
echo "🟦 Démarrage du conteneur React..."
echo "🟦 Port configuré: ${PORT}"

# Installation des dépendances si nécessaire
if [ -f package.json ]; then
    echo "📦 Installation des dépendances..."
    npm install
    
    # Build de l'application
    echo "🏗️ Construction de l'application..."
    npm run build
    
    # Démarrage du serveur de preview
    echo "🚀 Démarrage du serveur..."
    PORT=${REACT_PORT} npm run preview -- --host --port ${REACT_PORT}
else
    echo "❌ Aucun package.json trouvé"
    exit 1
fi 