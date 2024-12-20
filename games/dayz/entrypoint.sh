#!/bin/bash

# Définition des couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction de log
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

cd /home/container || exit 1

# Vérification des variables d'environnement
log_info "Vérification des variables d'environnement:"
log_info "AUTO_RESTART_HOURS=${AUTO_RESTART_HOURS}"
log_info "RCON_PORT=${RCON_PORT}"
log_info "RCON_PASSWORD est défini: $( [ -n "${RCON_PASSWORD}" ] && echo "oui" || echo "non" )"

# Déplacer les anciens logs
log_info "Déplacement des anciens logs..."
mkdir -p save_logs
find . -name "*.log" -exec mv {} ./save_logs/ \; 2>/dev/null
find . -name "*.adm" -exec mv {} ./save_logs/ \; 2>/dev/null
find . -name "*.RPT" -exec mv {} ./save_logs/ \; 2>/dev/null
find . -name "*.mdmp" -exec mv {} ./save_logs/ \; 2>/dev/null

# Configuration du redémarrage automatique
if [ -n "${AUTO_RESTART_HOURS}" ]; then
    log_info "Configuration du redémarrage automatique..."
    
    # Vérification du format de AUTO_RESTART_HOURS
    if ! [[ "${AUTO_RESTART_HOURS}" =~ ^[0-9]+(,[0-9]+)*$ ]]; then
        log_error "Format AUTO_RESTART_HOURS invalide: ${AUTO_RESTART_HOURS}"
        log_error "Format attendu: nombres séparés par des virgules (ex: 0,4,8,12,18)"
    else
        log_success "Format AUTO_RESTART_HOURS valide: ${AUTO_RESTART_HOURS}"
    fi

    # Configuration cron avec busybox
    echo "0 ${AUTO_RESTART_HOURS} * * * /home/container/restart_dayz.sh" > /etc/cron.d/container-cron
    chmod 0644 /etc/cron.d/container-cron
    log_success "Configuration cron créée: $(cat /etc/cron.d/container-cron)"
    
    # Démarrage du service cron
    log_info "Démarrage du service cron avec busybox..."
    busybox crond -L /dev/null -f &
    log_success "Service cron démarré"
else
    log_warning "Redémarrage automatique désactivé (AUTO_RESTART_HOURS non défini)"
fi

# Vérification de la présence de la modlist
if [ ! -f "modlist.html" ]; then
    log_warning "DayZ Modlist file \"modlist.html\" could not be found, or is invalid!"
    log_warning "Ensure your uploaded modlist's file name matches your Startup Parameter."
    log_warning "Only files exported from a DayZ Launcher are permitted."
fi

# Mise à jour du serveur
log_info "Starting checks for all updates..."
log_info "(It is okay to ignore any \"SDL\" and \"thread priority\" errors during this process)"

if [ "${STEAM_USER}" = "" ]; then
    log_warning "STEAM_USER is not set, defaulting to anonymous"
    STEAM_USER=anonymous
    STEAM_PASS=""
    STEAM_AUTH=""
fi

# Mise à jour avec SteamCMD
log_info "Checking for game server updates with App ID: ${STEAMCMD_APPID}..."
./steamcmd/steamcmd.sh +force_install_dir /home/container \
    +login ${STEAM_USER} ${STEAM_PASS} ${STEAM_AUTH} \
    +app_update ${STEAMCMD_APPID} \
    +quit

# Vérification de l'installation
if [ ! -f "DayZServer" ]; then
    log_error "DayZ Server installation failed!"
    exit 1
fi

# Démarrage du serveur
log_info "Starting server with the following startup command:"
log_info "./DayZServer -port=${SERVER_PORT} -profiles=profiles -bepath=./ -config=serverDZ.cfg -mod=${MODS} -serverMod=${SERVER_MODS}"

# Préparation de l'environnement LD_LIBRARY_PATH
export LD_LIBRARY_PATH=.

# Exécution du serveur
exec ./DayZServer \
    -port=${SERVER_PORT} \
    -profiles=profiles \
    -bepath=./ \
    -config=serverDZ.cfg \
    -mod=${MODS} \
    -serverMod=${SERVER_MODS}
