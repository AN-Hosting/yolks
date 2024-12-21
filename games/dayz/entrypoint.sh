#!/bin/bash

## File: DayZ Image - entrypoint.sh
## Author: David Wolfe (Red-Thirten)
## Contributors: Aussie Server Hosts (https://aussieserverhosts.com/)
## Date: 2024/06/05
## License: MIT License

## === CONSTANTS ===
STEAMCMD_DIR="./steamcmd"                       # SteamCMD's directory containing steamcmd.sh
WORKSHOP_DIR="./Steam/steamapps/workshop"       # SteamCMD's directory containing workshop downloads
STEAMCMD_LOG="${STEAMCMD_DIR}/steamcmd.log"     # Log file for SteamCMD
GAME_ID=221100                                  # SteamCMD ID for the DayZ GAME (not server). Only used for Workshop mod downloads.

# Color Codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

## === ENVIRONMENT VARS ===
# STARTUP, STARTUP_PARAMS, STEAM_USER, STEAM_PASS, SERVER_BINARY, MOD_FILE, MODIFICATIONS, SERVERMODS, UPDATE_SERVER, VALIDATE_SERVER, MODS_LOWERCASE, STEAMCMD_EXTRA_FLAGS, STEAMCMD_APPID, SERVER_PASSWORD, STEAMCMD_ATTEMPTS, DISABLE_MOD_UPDATES
# DISCORD_WEBHOOK_URL - L'URL du webhook Discord pour les notifications

## === GLOBAL VARS ===
# validateServer, extraFlags, updateAttempt, modifiedStartup, allMods, CLIENT_MODS
# Vérifier si le dossier save_logs existe, sinon le créer
SAVE_LOGS_DIR="./save_logs"
PROFILE_DIR="./profiles"

if [ ! -d "$SAVE_LOGS_DIR" ]; then
    echo "Le dossier save_logs n'existe pas. Création en cours..."
    mkdir -p "$SAVE_LOGS_DIR"
fi

# Déplacer les fichiers de log dans save_logs
LOG_EXTENSIONS=("log" "amd" "RPT" "mdmp")
for ext in "${LOG_EXTENSIONS[@]}"; do
    # Utilisation de find pour trouver et déplacer les fichiers
    find "$PROFILE_DIR" -type f -name "*.$ext" -exec mv {} "$SAVE_LOGS_DIR" \;
    
    # Vérification si des fichiers ont été déplacés
    if [ $? -eq 0 ]; then
        echo "Fichiers .$ext déplacés avec succès vers $SAVE_LOGS_DIR."
    else
        echo "Aucun fichier .$ext trouvé à déplacer."
    fi
done

## === DEFINE FUNCTIONS ===

# Runs SteamCMD with specified variables and performs error handling.
function RunSteamCMD { #[Input: int server=0 mod=1; int id]
    # Clear previous SteamCMD log
    if [[ -f "${STEAMCMD_LOG}" ]]; then
        rm -f "${STEAMCMD_LOG:?}"
    fi
    
    updateAttempt=0
    while (( $updateAttempt < $STEAMCMD_ATTEMPTS )); do # Loop for specified number of attempts
        # Increment attempt counter
        updateAttempt=$((updateAttempt+1))
        
        if (( $updateAttempt > 1 )); then # Notify if not first attempt
            echo -e "\t${YELLOW}Nouvelle tentative de téléchargement/mise à jour dans 3 secondes...${NC} (Tentative ${CYAN}${updateAttempt}${NC} sur ${CYAN}${STEAMCMD_ATTEMPTS}${NC})\n"
            sleep 3
        fi
        
        # Check if updating server or mod
        if [[ $1 == 0 ]]; then # Server
            ${STEAMCMD_DIR}/steamcmd.sh +force_install_dir /home/container "+login \"${STEAM_USER}\" \"${STEAM_PASS}\"" +app_update $2 $extraFlags $validateServer +quit | tee -a "${STEAMCMD_LOG}"
        else # Mod
            ${STEAMCMD_DIR}/steamcmd.sh "+login \"${STEAM_USER}\" \"${STEAM_PASS}\"" +workshop_download_item $GAME_ID $2 +quit | tee -a "${STEAMCMD_LOG}"
        fi
        
        # Error checking for SteamCMD
        steamcmdExitCode=${PIPESTATUS[0]}
        if [[ -n $(grep -i "error\|failed" "${STEAMCMD_LOG}" | grep -iv "setlocal\|SDL\|steamservice\|thread\|libcurl") ]]; then # Catch errors (ignore setlocale, SDL, and thread priority warnings)
            # Soft errors
            if [[ -n $(grep -i "Timeout downloading item" "${STEAMCMD_LOG}") ]]; then # Mod download timeout
                echo -e "\n${YELLOW}[MISE À JOUR]: ${NC}Délai d'attente dépassé pour le téléchargement du mod: \"${CYAN}${modName}${NC}\" (${CYAN}${2}${NC})"
                echo -e "\t(Ceci est normal pour les mods particulièrement volumineux)"
            elif [[ -n $(grep -i "0x402\|0x6\|0x602" "${STEAMCMD_LOG}") ]]; then # Connection issue with Steam
                echo -e "\n${YELLOW}[MISE À JOUR]: ${NC}Problème de connexion avec les serveurs Steam."
                echo -e "\t(Les serveurs Steam peuvent être indisponibles ou la connexion est instable)"
            # Hard errors
            elif [[ -n $(grep -i "Password check for AppId" "${STEAMCMD_LOG}") ]]; then # Incorrect beta branch password
                echo -e "\n${RED}[MISE À JOUR]: ${YELLOW}Mot de passe incorrect donné pour la branche bêta. ${CYAN}Téléchargement annulé...${NC}"
                echo -e "\t(Vérifiez votre \"[ADVANCED] EXTRA FLAGS FOR STEAMCMD\" paramètre de démarrage)"
                break
            # Fatal errors
            elif [[ -n $(grep -i "Invalid Password\|two-factor\|No subscription" "${STEAMCMD_LOG}") ]]; then # Wrong username/password, Steam Guard is turned on, or host is using anonymous account
                echo -e "\n${RED}[MISE À JOUR]: Impossible de se connecter à Steam - Compte utilisateur/mot de passe non configuré correctement"
                echo -e "\t${YELLOW}Veuillez contacter votre administrateur/hôte et leur donner le message suivant :${NC}"
                echo -e "\t${CYAN}Votre Egg, ou le serveur de votre client, n'est pas configuré avec des identifiants Steam valides.${NC}"
                echo -e "\t${CYAN}Soit le nom d'utilisateur/mot de passe est incorrect, soit Steam Guard n'est pas configuré correctement\n\tconformément à la documentation/README.${NC}\n"
                exit 1
            elif [[ -n $(grep -i "Download item" "${STEAMCMD_LOG}") ]]; then # Steam account does not own base game for mod downloads, or unknown
                echo -e "\n${RED}[MISE À JOUR]: Impossible de télécharger le mod - Téléchargement annulé"
                echo -e "\t${YELLOW}Tandis que cela est inconnu, cette erreur est probablement due à votre compte Steam hôte n'appartenant pas au jeu de base.${NC}"
                echo -e "\t${YELLOW}(Veuillez contacter votre administrateur/hôte si ce problème persiste)${NC}\n"
                exit 1
            elif [[ -n $(grep -i "0x202\|0x212" "${STEAMCMD_LOG}") ]]; then # Not enough disk space
                echo -e "\n${RED}[MISE À JOUR]: Impossible de terminer le téléchargement - Pas assez d'espace disque"
                echo -e "\t${YELLOW}Vous avez utilisé tout votre espace disque alloué.${NC}"
                echo -e "\t${YELLOW}Veuillez contacter votre administrateur/hôte pour des mises à jour possibles de l'espace disque.${NC}\n"
                exit 1
            elif [[ -n $(grep -i "0x606" "${STEAMCMD_LOG}") ]]; then # Disk write failure
                echo -e "\n${RED}[MISE À JOUR]: Impossible de terminer le téléchargement - Erreur d'écriture disque"
                echo -e "\t${YELLOW}Cela est généralement dû à des problèmes d'autorisations de répertoire,\n\tmais pourrait être un problème matériel plus grave.${NC}"
                echo -e "\t${YELLOW}(Veuillez contacter votre administrateur/hôte si ce problème persiste)${NC}\n"
                exit 1
            else # Unknown caught error
                echo -e "\n${RED}[MISE À JOUR]: ${YELLOW}Une erreur inconnue s'est produite avec SteamCMD. ${CYAN}Téléchargement annulé...${NC}"
                echo -e "\t(Veuillez contacter votre administrateur/hôte si ce problème persiste)"
                break
            fi
        elif [[ $steamcmdExitCode != 0 ]]; then # Unknown fatal error
            echo -e "\n${RED}[MISE À JOUR]: SteamCMD s'est arrêté pour une raison inconnue!${NC} (Code de sortie: ${CYAN}${steamcmdExitCode}${NC})"
            echo -e "\t${YELLOW}(Veuillez contacter votre administrateur/hôte pour obtenir de l'aide)${NC}\n"
            cp -r /tmp/dumps /home/container/dumps
            exit $steamcmdExitCode
        else # Success!
            if [[ $1 == 0 ]]; then # Server
                echo -e "\n${GREEN}[MISE À JOUR]: Le serveur de jeu est à jour!${NC}"
            else # Mod
                # Move the downloaded mod to the root directory, and replace existing mod if needed
                mkdir -p ./@$2
                rm -rf ./@$2/*
                mv -f ${WORKSHOP_DIR}/content/$GAME_ID/$2/* ./@$2
                rm -d ${WORKSHOP_DIR}/content/$GAME_ID/$2
                # Make the mods contents all lowercase
                ModsLowercase @$2
                # Move any .bikey's to the keys directory
                echo -e "\tMoving any mod ${CYAN}.bikey${NC} files to the ${CYAN}~/keys/${NC} folder..."
                find ./@$2 -name "*.bikey" -type f -exec cp {} ./keys \;
                echo -e "${GREEN}[MISE À JOUR]: Téléchargement/mise à jour du mod réussi!${NC}"
            fi
            break
        fi
        if (( $updateAttempt == $STEAMCMD_ATTEMPTS )); then # Notify if failed last attempt
            if [[ $1 == 0 ]]; then # Server
                echo -e "\t${RED}Dernière tentative effectuée! ${YELLOW}Impossible de terminer la mise à jour du serveur de jeu. ${CYAN}Téléchargement annulé...${NC}"
                echo -e "\t(Veuillez réessayer plus tard)"
                sleep 3
            else # Mod
                echo -e "\t${RED}Dernière tentative effectuée! ${YELLOW}Impossible de terminer le téléchargement/mise à jour du mod. ${CYAN}Téléchargement annulé...${NC}"
                echo -e "\t(Vous pouvez réessayer plus tard, ou télécharger ce mod manuellement sur votre serveur via SFTP)"
                sleep 3
            fi
        fi
    done
}

# Takes a directory (string) as input, and recursively makes all files & folders lowercase.
function ModsLowercase {
    echo -e "\n\tConversion des fichiers/dossiers du mod ${CYAN}$1${NC} en minuscules..."
    for SRC in `find ./$1 -depth`
    do
        DST=`dirname "${SRC}"`/`basename "${SRC}" | tr '[A-Z]' '[a-z]'`
        if [ "${SRC}" != "${DST}" ]
        then
            [ ! -e "${DST}" ] && mv -T "${SRC}" "${DST}"
        fi
    done
}

# Removes duplicate items from a semicolon delimited string
function RemoveDuplicates { #[Input: str - Output: printf of new str]
    if [[ -n $1 ]]; then # If nothing to compare, skip to prevent extra semicolon being returned
        echo $1 | sed -e 's/;/\n/g' | sort -u | xargs printf '%s;'
    fi
}

# Fonction pour vérifier si le serveur est en ligne
function checkServer() {
    local attempts=0
    local max_attempts=30
    while [ $attempts -lt $max_attempts ]; do
        if bercon-cli -p ${RCON_PORT} -P "${RCON_PASSWORD}" "players" &>/dev/null; then
            return 0
        fi
        attempts=$((attempts + 1))
        sleep 2
    done
    return 1
}

# Fonction pour le redémarrage automatique
function AutoRestart() {
    local restart_hours=(${AUTO_RESTART_HOURS//,/ })
    local RESTART_FILE="/tmp/need_restart"
    
    # Attendre que le serveur soit complètement démarré
    echo -e "${YELLOW}[REDÉMARRAGE]:${NC} Attente du démarrage complet du serveur..."
    if ! checkServer; then
        echo -e "${RED}[ERREUR]:${NC} Impossible de se connecter au serveur via RCON"
        return 1
    fi
    echo -e "${GREEN}[REDÉMARRAGE]:${NC} Connexion RCON établie"
    
    while true; do
        for hour in "${restart_hours[@]}"; do
            # Convertir 24 en 0 pour minuit
            if [ "$hour" = "24" ]; then
                hour="0"
            fi
            
            # Vérifier si l'heure est valide (entre 0 et 23)
            if ! [[ "$hour" =~ ^[0-9]+$ ]] || [ "$hour" -gt 23 ]; then
                echo -e "${RED}[ERREUR]:${NC} Heure de redémarrage invalide: ${hour}"
                continue
            fi
            
            # Obtenir l'heure actuelle et calculer l'heure de redémarrage
            current_epoch=$(date +%s)
            current_hour=$(date +%H)
            
            # Formater l'heure avec un zéro devant si nécessaire
            formatted_hour=$(printf "%02d" $hour)
            
            # Calculer l'heure de redémarrage en epoch
            if [ "$hour" -le "$current_hour" ]; then
                # Si l'heure de redémarrage est passée, on calcule pour le lendemain
                restart_epoch=$(date -d "tomorrow $formatted_hour:00" +%s)
            else
                restart_epoch=$(date -d "today $formatted_hour:00" +%s)
            fi
            
            # Calculer les minutes restantes
            minutes_until=$(( ($restart_epoch - $current_epoch) / 60 ))
            
            # Si on est dans les 30 minutes avant le redémarrage
            if [ $minutes_until -le 30 ] && [ $minutes_until -ge 0 ]; then
                case $minutes_until in
                    30|20|10|5|4)
                        if bercon-cli -p ${RCON_PORT} -P "${RCON_PASSWORD}" \
                            "say -1 Le serveur redémarrera dans ${minutes_until} minutes"; then
                            echo -e "${GREEN}[REDÉMARRAGE]:${NC} Message envoyé: ${minutes_until} minutes"
                        else
                            echo -e "${RED}[ERREUR]:${NC} Échec de l'envoi du message RCON"
                        fi
                        ;;
                    3)
                        # Verrouiller le serveur et kicker les joueurs 3 minutes avant
                        if bercon-cli -p ${RCON_PORT} -P "${RCON_PASSWORD}" \
                            '#lock' \
                            '#kick -1 Le serveur redémarre dans 3 minutes' \
                            "say -1 Le serveur redémarrera dans 3 minutes. Serveur verrouillé."; then
                            echo -e "${YELLOW}[REDÉMARRAGE]:${NC} Serveur verrouillé et joueurs expulsés"
                        fi
                        ;;
                    2)
                        if bercon-cli -p ${RCON_PORT} -P "${RCON_PASSWORD}" \
                            "say -1 Le serveur redémarrera dans 2 minutes."; then
                            echo -e "${GREEN}[REDÉMARRAGE]:${NC} Message envoyé: 2 minutes"
                        fi
                        ;;
                    1)
                        if bercon-cli -p ${RCON_PORT} -P "${RCON_PASSWORD}" \
                            "say -1 Le serveur redémarrera dans 1 minute."; then
                            echo -e "${GREEN}[REDÉMARRAGE]:${NC} Message envoyé: 1 minute"
                        fi
                        ;;
                    0)
                        echo -e "${RED}[REDÉMARRAGE]:${NC} Début de la séquence d'arrêt"
                        # Envoyer le message final et arrêter le serveur
                        bercon-cli -p ${RCON_PORT} -P "${RCON_PASSWORD}" \
                            "say -1 Redémarrage du serveur..." \
                            '#shutdown'
                        
                        # Attendre que le serveur s'arrête complètement
                        sleep 30
                        
                        # Créer le fichier de redémarrage
                        touch "${RESTART_FILE}"
                        echo -e "${GREEN}[REDÉMARRAGE]:${NC} Redémarrage du conteneur..."
                        
                        # Tuer le processus principal
                        if [ -f /tmp/.pid ]; then
                            kill -15 $(cat /tmp/.pid)
                        fi
                        exit 0
                        ;;
                esac
            fi
        done
        sleep 60
    done
}

# Fonction pour envoyer un message à Discord
function sendDiscordNotification() {
    local mod_name="$1"
    local mod_id="$2"
    local status="$3"  # "Mise à jour" ou "installé"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Construction du message Discord avec un embed
    local json_data=$(cat << EOF
{
  "embeds": [{
    "title": "${SERVER_HOSTNAME}",
    "fields": [
      {
        "name": "Nom du mod",
        "value": "[@${mod_name}](https://steamcommunity.com/sharedfiles/filedetails/?id=${mod_id})",
        "inline": true
      },
      {
        "name": "Date de l'opération",
        "value": "<t:$(date +%s):R>",
        "inline": true
      },
      {
        "name": "Statut",
        "value": "${status}",
        "inline": true
      }
    ],
    "color": 5793266,
    "timestamp": "${timestamp}"
  }]
}
EOF
)

    # Envoi de la notification à Discord si l'URL du webhook est configurée
    if [[ -n ${DISCORD_WEBHOOK_URL} ]]; then
        curl -H "Content-Type: application/json" -X POST -d "${json_data}" ${DISCORD_WEBHOOK_URL}
    fi
}

## === ENTRYPOINT START ===

# Wait for the container to fully initialize
sleep 1

# Set environment variable that holds the Internal Docker IP
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

# Switch to the container's working directory
cd /home/container || exit 1

# Collect and parse all specified mods
if [[ -n ${MODIFICATIONS} ]] && [[ ${MODIFICATIONS} != *\; ]]; then # Add manually specified mods to the client-side mods list, while checking for trailing semicolon
    CLIENT_MODS="${MODIFICATIONS};"
else
    CLIENT_MODS=${MODIFICATIONS}
fi
# If the mod list file exists and is valid, parse and add mods to the client-side mods list
if [[ -f ${MOD_FILE} ]] && [[ -n "$(cat ${MOD_FILE} | grep 'Created by DayZ Launcher')" ]]; then
    CLIENT_MODS+=$(cat ${MOD_FILE} | grep 'id=' | cut -d'=' -f3 | cut -d'"' -f1 | xargs printf '@%s;')
elif [[ -n "${MOD_FILE}" ]]; then # If MOD_FILE is not null, warn user file is missing or invalid
    echo -e "\n${YELLOW}[STARTUP_WARN]: DayZ Modlist file \"${CYAN}${MOD_FILE}${YELLOW}\" could not be found, or is invalid!${NC}"
    echo -e "\tEnsure your uploaded modlist's file name matches your Startup Parameter."
    echo -e "\tOnly files exported from a DayZ Launcher are permitted."
    if [[ -n "${CLIENT_MODS}" ]]; then
        echo -e "\t${CYAN}Reverting to the manual mod list...${NC}"
    fi
fi
# Add server mods to the master mods list, while checking for trailing semicolon
if [[ -n ${SERVERMODS} ]] && [[ ${SERVERMODS} != *\; ]]; then
    allMods="${SERVERMODS};"
else
    allMods=${SERVERMODS}
fi
allMods+=$CLIENT_MODS # Add all client-side mods to the master mod list
CLIENT_MODS=$(RemoveDuplicates ${CLIENT_MODS}) # Remove duplicate mods from CLIENT_MODS, if present
allMods=$(RemoveDuplicates ${allMods}) # Remove duplicate mods from allMods, if present
allMods=$(echo $allMods | sed -e 's/;/ /g') # Convert from string to array

# Update everything (server and mods), if specified
if [[ ${UPDATE_SERVER} == 1 ]]; then
    echo -e "\n${GREEN}[DÉMARRAGE]: ${CYAN}Début des vérifications des mises à jour...${NC}"
    echo -e "(Il est normal d'ignorer les erreurs \"SDL\" et \"thread priority\" pendant ce processus)\n"
    
    ## Update game server
    echo -e "${GREEN}[MISE À JOUR]:${NC} Checking for game server updates with App ID: ${CYAN}${STEAMCMD_APPID}${NC}..."
    
    if [[ ${VALIDATE_SERVER} == 1 ]]; then # Validate will be added as a parameter if specified
        echo -e "\t${CYAN}File validation enabled.${NC} (This may take extra time to complete)"
        validateServer="validate"
    else
        validateServer=""
    fi
    
    # Determine what extra flags should be set
    if [[ -n ${STEAMCMD_EXTRA_FLAGS} ]]; then
        echo -e "\t(${YELLOW}Advanced${NC}) Extra SteamCMD flags specified: ${CYAN}${STEAMCMD_EXTRA_FLAGS}${NC}\n"
        extraFlags=${STEAMCMD_EXTRA_FLAGS}
    else
        echo -e ""
        extraFlags=""
    fi
    
    RunSteamCMD 0 ${STEAMCMD_APPID}
    
    ## Update mods
    if [[ -n $allMods ]] && [[ ${DISABLE_MOD_UPDATES} != 1 ]]; then
        echo -e "\n${GREEN}[MISE À JOUR]:${NC} Checking all ${CYAN}Steam Workshop mods${NC} for updates..."
        for modID in $(echo $allMods | sed -e 's/@//g')
        do
            if [[ $modID =~ ^[0-9]+$ ]]; then # Only check mods that are in ID-form
                # Get mod's latest update in epoch time from its Steam Workshop changelog page
                latestUpdate=$(curl -sL https://steamcommunity.com/sharedfiles/filedetails/changelog/$modID | grep '<p id=' | head -1 | cut -d'"' -f2)
                # If the update time is valid and newer than the local directory's creation date, or the mod hasn't been downloaded yet, download the mod
                if [[ ! -d @$modID ]] || [[ ( -n $latestUpdate ) && ( $latestUpdate =~ ^[0-9]+$ ) && ( $latestUpdate > $(find @$modID | head -1 | xargs stat -c%Y) ) ]]; then
                    # Get the mod's name from the Workshop page as well
                    modName=$(curl -sL https://steamcommunity.com/sharedfiles/filedetails/changelog/$modID | grep 'workshopItemTitle' | cut -d'>' -f2 | cut -d'<' -f1)
                    if [[ -z $modName ]]; then # Set default name if unavailable
                        modName="[NAME UNAVAILABLE]"
                    fi
                    if [[ ! -d @$modID ]]; then
                        echo -e "\n${GREEN}[MISE À JOUR]:${NC} Downloading new Mod: \"${CYAN}${modName}${NC}\" (${CYAN}${modID}${NC})"
                    else
                        echo -e "\n${GREEN}[MISE À JOUR]:${NC} Mod update found for: \"${CYAN}${modName}${NC}\" (${CYAN}${modID}${NC})"
                    fi
                    if [[ -n $latestUpdate ]] && [[ $latestUpdate =~ ^[0-9]+$ ]]; then # Notify last update date, if valid
                        echo -e "\tMod was last updated: ${CYAN}$(date -d @${latestUpdate})${NC}"
                    fi
                    
                    # Delete SteamCMD appworkshop cache before running to avoid mod download failures
                    echo -e "\tClearing SteamCMD appworkshop cache..."
                    rm -f ${WORKSHOP_DIR}/appworkshop_$GAME_ID.acf

                    echo -e "\tAttempting mod update/download via SteamCMD...\n"
                    RunSteamCMD 1 $modID
                    
                    # Après un téléchargement réussi, envoyer la notification Discord
                    if [ $? -eq 0 ]; then
                        sendDiscordNotification "${modName}" "${modID}" "Mise à jour"
                    fi
                fi
            fi
        done
        echo -e "${GREEN}[MISE À JOUR]:${NC} Steam Workshop mod update check ${GREEN}complete${NC}!"
    fi
fi

# Check if specified server binary exists.
if [[ ! -f ./${SERVER_BINARY} ]]; then
    echo -e "\n${RED}[STARTUP_ERR]: Specified DayZ server binary could not be found in the root directory!${NC}"
    echo -e "${YELLOW}Please do the following to resolve this issue:${NC}"
    echo -e "\t${CYAN}- Double check your \"Server Binary\" Startup Variable is correct.${NC}"
    echo -e "\t${CYAN}- Ensure your server has properly installed/updated without errors (reinstalling/updating again may help).${NC}"
    echo -e "\t${CYAN}- Use the File Manager to check that your specified server binary file is not missing from the root directory.${NC}\n"
    exit 1
fi

# Make mods lowercase, if specified
if [[ ${MODS_LOWERCASE} == "1" ]]; then
    for modDir in $allMods
    do
        ModsLowercase $modDir
    done
fi

# Setup NSS Wrapper for use ($NSS_WRAPPER_PASSWD and $NSS_WRAPPER_GROUP have been set by the Dockerfile)
export USER_ID=$(id -u)
export GROUP_ID=$(id -g)
envsubst < /passwd.template > ${NSS_WRAPPER_PASSWD}
export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libnss_wrapper.so

# Replace Startup Variables
modifiedStartup=`eval echo $(echo ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')`

# Sauvegarder le PID du processus principal
echo $$ > /tmp/.pid

# Démarrer le processus de redémarrage automatique en arrière-plan si AUTO_RESTART_HOURS est défini
if [[ -n ${AUTO_RESTART_HOURS} ]]; then
    echo -e "${GREEN}[DÉMARRAGE]:${NC} Configuration du redémarrage automatique pour les heures: ${CYAN}${AUTO_RESTART_HOURS}${NC}"
    AutoRestart &
fi

# Start the Server
echo -e "\n${GREEN}[DÉMARRAGE]:${NC} Démarrage du serveur avec la commande suivante:"
echo -e "${CYAN}${modifiedStartup}${NC}\n"
${modifiedStartup}

# Vérifier si un redémarrage est nécessaire
if [ -f "${RESTART_FILE}" ]; then
    rm "${RESTART_FILE}"
    exit 0
fi

if [ $? -ne 0 ]; then
    echo -e "\n${RED}[ERREUR_DÉMARRAGE]: Une erreur s'est produite lors de la tentative d'exécution de la commande de démarrage.${NC}\n"
    exit 1
fi
