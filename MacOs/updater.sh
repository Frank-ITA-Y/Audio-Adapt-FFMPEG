#!/bin/bash

#updater by Lo_Re, Copyright(cc) all rights reserved

# --- CONFIGURAZIONE ---
CONFIG_UPDATE=".config_update.txt"
PLIST_PATH="$HOME/Library/LaunchAgents/com.utente.ffmpegupdater.plist"
SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"

# Carica le impostazioni attuali
carica_config() {
    if [ -f "$CONFIG_UPDATE" ]; then
        ATTIVO=$(sed -n '1p' "$CONFIG_UPDATE")
        GIORNI=$(sed -n '2p' "$CONFIG_UPDATE")
    else
        ATTIVO="no"
        GIORNI=7
    fi
}

# Salva le impostazioni e aggiorna il LaunchAgent di macOS
salva_e_applica_config() {
    echo "$ATTIVO" > "$CONFIG_UPDATE"
    echo "$GIORNI" >> "$CONFIG_UPDATE"

    # Se l'automatismo è attivo, crea/aggiorna il file .plist del Mac
    if [ "$ATTIVO" = "si" ]; then
        # Converte i giorni in secondi (1 giorno = 86400 secondi)
        SECONDI=$((GIORNI * 86400))
        
        # Rimuove il vecchio servizio se esisteva per evitare conflitti
        launchctl unload "$PLIST_PATH" &> /dev/null
        
        # Scrive il file plist aggiornato
        cat <<EOF > "$PLIST_PATH"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.utente.ffmpegupdater</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$SCRIPT_PATH</string>
        <string>--run-silently</string>
    </array>
    <key>StartInterval</key>
    <integer>$SECONDI</integer>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF
        # Attiva il timer nel sistema macOS
        launchctl load "$PLIST_PATH" &> /dev/null
        echo "Automatismo ATTIVATO: il controllo avverrà ogni $GIORNI giorni in background."
    else
        # Se disattivato, rimuove il file plist e spegne il timer
        launchctl unload "$PLIST_PATH" &> /dev/null
        rm -f "$PLIST_PATH"
        echo "Automatismo DISATTIVATO: nessun controllo periodico in background."
    fi
}

# --- GUIDA UTENTE (-h) ---
mostra_help() {
    echo "=== GUIDA DI UTILIZZO (update.sh) ==="
    echo "Uso standard: Esegue subito un controllo e aggiorna Homebrew e ffmpeg."
    echo ""
    echo "PARAMETRI DISPONIBILI:"
    echo "  -h   Mostra questa schermata di aiuto."
    echo "  -ec  Modifica la pianificazione (attiva/disattiva o cambia i giorni)."
    echo "  -Dis Disabilità gli aggiornamenti automatici (senza avviare wizard)"
    echo ""
    echo "Nota: I controlli automatici salvano i log in ~/Library/Logs/FfmpegUpdater/"
    exit 0
}

# --- MENU MODIFICA CONFIGURAZIONE (-ec) ---
modifica_config() {
    echo "=== MODIFICA PIANIFICAZIONE AGGIORNAMENTI ==="
    carica_config
    echo "Stato attuale: Automatico=$ATTIVO | Ogni=$GIORNI giorni"
    echo "--------------------------------------------------------"
    
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

# --- CONTROLLO DEI PARAMETRI ---
if [ "$1" = "-h" ]; then
    mostra_help
elif [ "$1" = "-ec" ]; then
    modifica_config
elif [ "$1" = "-Dis" ]; then
    # Spegne l'automatismo e pulisce il sistema Mac
    ATTIVO="no"
    GIORNI=7
    salva_e_applica_config
    exit 0
elif [ "$1" = "--setup-auto" ]; then
    ATTIVO="si"
    GIORNI=${2:-7}
    salva_e_applica_config
    exit 0
elif [ "$1" = "--run-silently" ]; then
    # Questa opzione viene usata dal Mac in background: scrive l'output solo nel file log
    mkdir -p ~/Library/Logs/FfmpegUpdater
    exec >> ~/Library/Logs/FfmpegUpdater/update.log 2>&1
fi

# --- CONFIGURAZIONE AL PRIMO LANCIO ASSOLUTO ---
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

    salva_e_applica_config
    echo "Configurazione completata! Usa il parametro -h per vedere la guida."
    echo "--------------------------------------------------------"
fi

# --- ESECUZIONE AGGIORNAMENTO EFFETTIVO ---
echo "=== CONTROLLO AGGIORNAMENTI IN CORSO: $(date) ==="
echo "Verifica dei pacchetti e di ffmpeg..."

# Configura temporaneamente il PATH per trovare Homebrew
if [ -f /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -f /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

if ! command -v brew &> /dev/null; then
    echo "[ERRORE] Homebrew non è installato su questo Mac. Esegui prima install.sh!"
    exit 1
fi

# Esegue l'aggiornamento
brew update

if brew outdated | grep -q "ffmpeg"; then
    echo "Nuova versione di ffmpeg rilevata. Installazione dell'aggiornamento..."
    brew upgrade ffmpeg
    echo "Aggiornamento completato con successo!"
else
    echo "Tutto aggiornato! ffmpeg è già all'ultima versione."
fi

echo "--------------------------------------------------------"
# Mostra il blocco di chiusura solo se NON è l'esecuzione silenziosa del sistema
if [ "$1" != "--run-silently" ]; then
    read -n 1 -s -r -p "Premere un tasto per terminare..."
    echo ""
fi
