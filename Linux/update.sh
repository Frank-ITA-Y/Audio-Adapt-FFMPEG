#!/bin/bash

# Linux Updater by Lo_Re, Copyright(cc) all rights reserved

# CONFIG
CONFIG_UPDATE=".config_update.txt"
SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
LOG_FILE="$HOME/.cache/ffmpeg_updater.log"

# Carica le impostazioni attuali
carica_config() {
    if [ -f "$CONFIG_UPDATE" ]; then
        ATTIVO=$(sed -n '1p' "$CONFIG_UPDATE")
        GIORNI=$(sed -n '2p' "$CONFIG_UPDATE")
        DISTRO=$(sed -n '3p' "$CONFIG_UPDATE")
    else
        ATTIVO="no"
        GIORNI=7
        DISTRO="debian" # Valore di ripiego predefinito
    fi
}

# Salva le impostazioni e configura CRON
salva_e_applica_config() {
    echo "$ATTIVO" > "$CONFIG_UPDATE"
    echo "$GIORNI" >> "$CONFIG_UPDATE"
    echo "$DISTRO" >> "$CONFIG_UPDATE"

    # Rimuove vecchie pianificazioni
    crontab -l 2>/dev/null | grep -v "$SCRIPT_PATH" | crontab -

    if [ "$ATTIVO" = "si" ]; then
        # Configura Cron per eseguire lo script alle 12:00 ogni X giorni
        # Sintassi cron: Minuti Ore GiornoDelMese Mese GiornoDellaSettimana Comando
        (crontab -l 2>/dev/null; echo "0 12 */$GIORNI * * /bin/bash $SCRIPT_PATH --run-silently") | crontab -
        echo "Automatismo ATTIVATO via Cron: il controllo avverrà ogni $GIORNI giorni."
    else
        echo "Automatismo DISATTIVATO: nessun controllo periodico impostato."
    fi
}

# --- GUIDA UTENTE (-h) ---
mostra_help() {
    echo "=== GUIDA DI UTILIZZO (update.sh - Linux) ==="
    echo "Uso standard: Esegue subito un controllo e aggiorna ffmpeg in base alla tua distro."
    echo ""
    echo "PARAMETRI DISPONIBILI:"
    echo "  -h   Mostra questa schermata di aiuto."
    echo "  -ec  Modifica la pianificazione (attiva/disattiva o cambia l'intervallo di giorni)."
    echo "  -Dis Disabilita gli aggiornamenti periodici(instantaneamente)"
    echo ""
    echo "Nota: I controlli automatici salvano lo storico in: $LOG_FILE"
    exit 0
}

# --- MENU MODIFICA CONFIGURAZIONE (-ec) ---
modifica_config() {
    echo "=== MODIFICA PIANIFICAZIONE AGGIORNAMENTI (LINUX) ==="
    carica_config
    echo "Stato attuale: Automatico=$ATTIVO | Ogni=$GIORNI giorni | Gestore=$DISTRO"
    echo "------------------------------------------------------------------------"
    
    while true; do
        read -p "Vuoi attivare il controllo automatico periodico? [S/n]: " scelta_attiva
        scelta_attiva=${scelta_attiva:-S}
        if [[ "$scelta_attiva" =~ ^[Ss]$ ]]; then
            ATTIVO="si"
            break
        elif [[ "$scelta_attiva" =~ ^[Nn]$ ]]; then
            ATTIVO="no"
            break
        fi
    done

    if [ "$ATTIVO" = "si" ]; then
        while true; do
            read -p "Ogni quanti giorni vuoi eseguire la scansione? (default: 7): " scelta_giorni
            scelta_giorni=${scelta_giorni:-7}
            if [[ "$scelta_giorni" =~ ^[0-9]+$ ]] && [ "$scelta_giorni" -gt 0 ]; then
                GIORNI=$scelta_giorni
                break
            fi
            echo "[ERRORE] Inserisci un numero di giorni valido (maggiore di 0)."
        done
    fi

    salva_e_applica_config
    exit 0
}

# CONTROLLO PARAMETRI CORRENTI
if [ "$1" = "-h" ]; then
    mostra_help
elif [ "$1" = "-ec" ]; then
    modifica_config
elif [ "" = "-Dis" ]; then
    ATTIVO="no"
    GIORNI=7
    DISTRO="flatpak"
    salva_e_applica_config
    exit 0
elif [ "$1" = "--setup-auto" ]; then
    # Cattura le impostazioni passate direttamente dall'installer Linux
    ATTIVO="si"
    GIORNI=${2:-7}
    # Se l'installer passa la distro ($3), la memorizza, altrimenti tenta il rilevamento rapido
    if [ -n "$3" ]; then
        DISTRO="$3"
    else
        DISTRO="debian"
        [ -f /etc/os-release ] && DISTRO=$(grep -E '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
    fi
    salva_e_applica_config
    exit 0
elif [ "$1" = "--run-silently" ]; then
    mkdir -p "$(dirname "$LOG_FILE")"
    exec >> "$LOG_FILE" 2>&1
fi

# Carica le configurazioni
carica_config

# CONFIGURAZIONE PRIMO LANCIO MANUALE
if [ ! -f "$CONFIG_UPDATE" ]; then
    echo "=== CONFIGURAZIONE INIZIALE AGGIORNAMENTI ==="
    echo "Configura il comportamento del software per il futuro."
    echo "--------------------------------------------------------"
    
    while true; do
        read -p "Vuoi attivare la scansione automatica periodica? [S/n]: " scelta_attiva
        scelta_attiva=${scelta_attiva:-S}
        if [[ "$scelta_attiva" =~ ^[Ss]$ ]]; then
            ATTIVO="si"
            break
        elif [[ "$scelta_attiva" =~ ^[Nn]$ ]]; then
            ATTIVO="no"
            break
        fi
    done

    if [ "$ATTIVO" = "si" ]; then
        while true; do
            read -p "Ogni quanti giorni vuoi che venga eseguita? (default: 7): " scelta_giorni
            scelta_giorni=${scelta_giorni:-7}
            if [[ "$scelta_giorni" =~ ^[0-9]+$ ]] && [ "$scelta_giorni" -gt 0 ]; then
                GIORNI=$scelta_giorni
                break
            fi
            echo "[ERRORE] Inserisci un numero di giorni valido."
        done
    fi

    # Tenta di capire la distro se viene lanciato in standalone la prima volta
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        DISTRO=$(echo "$ID" | tr '[:upper:]' '[:lower:]')
    fi

    salva_e_applica_config
    echo "Configurazione completata! Usa il parametro -h per vedere la guida."
    echo "--------------------------------------------------------"
fi

# ESECUZIONE AGGIORNAMENTO
echo "=== CONTROLLO AGGIORNAMENTI LINUX: $(date) ==="
echo "Verifica disponibilità nuove versioni di ffmpeg via $DISTRO..."

# Esegue l'aggiornamento
case "$DISTRO" in
    ubuntu|debian|mint|pop|zorin|kali)
        # Nota: L'aggiornamento automatico via cron di pacchetti di sistema 
        # richiede che sudo sia configurato senza password, altrimenti funzionerà solo se lanciato a schermo.
        sudo apt-get update -y && sudo apt-get install --only-upgrade ffmpeg -y
        ;;
    arch|manjaro|endeavouros)
        sudo pacman -Syu --noconfirm ffmpeg
        ;;
    fedora|rhel|centos)
        sudo dnf upgrade ffmpeg -y
        ;;
    flatpak)
        # Flatpak non richiede sudo se configurato con il flag --user
        flatpak update org.freedesktop.Platform.ffmpeg-full -y
        ;;
    *)
        echo "[ERRORE] Gestore pacchetti '$DISTRO' sconosciuto o non supportato per gli aggiornamenti automatici."
        exit 1
        ;;
esac

echo "Controllo completato."
echo "--------------------------------------------------------"

# Mostra il blocco di chiusura interattivo solo se non è Cron in background
if [ "$1" != "--run-silently" ]; then
    read -n 1 -s -r -p "Premere un tasto per terminare..."
    echo ""
fi
