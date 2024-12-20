#!/bin/bash

# Configuration par défaut
INTERNAL_IP=${INTERNAL_IP:-"127.0.0.1"}  # Utilise 127.0.0.1 si INTERNAL_IP n'est pas défini

# Fonction pour envoyer un message au serveur
send_message() {
    bercon -i "${INTERNAL_IP}" -p "${RCON_PORT}" -P "${RCON_PASSWORD}" exec -- "say -1 \"$1\""
}

# Fonction pour verrouiller le serveur
lock_server() {
    bercon -i "${INTERNAL_IP}" -p "${RCON_PORT}" -P "${RCON_PASSWORD}" exec -- '#lock'
    send_message "Le serveur est maintenant verrouillé. Plus aucune nouvelle connexion possible."
}

# Vérification des variables requises
if [ -z "${RCON_PORT}" ] || [ -z "${RCON_PASSWORD}" ]; then
    echo "Erreur: RCON_PORT et RCON_PASSWORD doivent être définis"
    echo "RCON_PORT actuel: ${RCON_PORT}"
    echo "RCON_PASSWORD défini: $( [ -n "${RCON_PASSWORD}" ] && echo "oui" || echo "non" )"
    exit 1
fi

# Fonction de redémarrage avec notifications
dayz_restart() {
    echo "Démarrage de la séquence de redémarrage"
    echo "Utilisation de: IP=${INTERNAL_IP}, PORT=${RCON_PORT}"

    # 30 minutes avant
    send_message "Le serveur redémarrera dans 30 minutes"
    sleep 600  # Attendre 10 minutes

    # 20 minutes avant
    send_message "Le serveur redémarrera dans 20 minutes"
    sleep 600  # Attendre 10 minutes

    # 10 minutes avant
    send_message "Le serveur redémarrera dans 10 minutes"
    sleep 300  # Attendre 5 minutes

    # 5 minutes avant
    send_message "Le serveur redémarrera dans 5 minutes"
    sleep 120  # Attendre 2 minutes

    # 3 minutes avant
    send_message "Le serveur redémarrera dans 3 minutes"
    sleep 60   # Attendre 1 minute

    # 2 minutes avant - Verrouillage du serveur
    lock_server
    send_message "Le serveur redémarrera dans 2 minutes"
    sleep 60   # Attendre 1 minute

    # 1 minute avant
    send_message "Le serveur redémarrera dans 1 minute"
    sleep 30   # Attendre 30 secondes

    # 30 secondes avant
    send_message "Le serveur redémarrera dans 30 secondes"
    sleep 20   # Attendre 20 secondes

    # 10 secondes avant
    send_message "Le serveur redémarrera dans 10 secondes"
    sleep 10   # Attendre 10 secondes

    # Arrêt du serveur
    send_message "Redémarrage du serveur..."
    bercon -i "${INTERNAL_IP}" -p "${RCON_PORT}" -P "${RCON_PASSWORD}" exec -- '#shutdown'
}

# Exécution du redémarrage
dayz_restart