#!/bin/bash

# Instller by Lo_Re, Copyright(cc) all rights reserved

# scripts permissions
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
chmod +x "$SCRIPT_DIR/Adatta_files.sh" 2>/dev/null
chmod +x "$SCRIPT_DIR/updater.sh" 2>/dev/null

echo "=== INIZIO INSTALLAZIONE FFMPEG ==="
echo "Il processo potrebbe richedere qualche minuto..."

# Check if homebrew is installed
if ! command -v brew &> /dev/null; then
	echo "Home Brew non trovato. Installazione in corso..."
	NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	#configurazione Homebrew
	echo "confugurazione in corso..."
	if [ -f /opt/homebrew/bin/brew ]; then
		echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
		eval "$(/opt/homebrew/bin/brew shellenv)";
	elif [ -f /usr/local/bin/brew ]; then
		echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
		eval "$(/usr/local/bin/brew shellenv)"
	fi
else
	echo "Homebrew è già installato!"
	echo "Aggiornamento dei pacchetti di Homebrew..."
	brew update
fi 

echo "installazione ffmpeg in corso..."
brew install ffmpeg

echo ""
echo "=== INSTALLAZIONE COMPLETATA CON SUCCESSO! ==="
echo ""

echo ""
echo "=== CONFIGURAZIONE AGGIORNAMENTI ==="
read -p "Vuoi attivare il controllo automatico degli aggiornamenti? [s/N]: " scelta_up
scelta_up=${scelta_up:-N}

if [[ "$scelta_up" =~ ^[Ss]$ ]]; then
	SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    if [ -f "$SCRIPT_DIR/updater.sh" ]; then
        while true; do
        	read -p "Ogni quanti giorni vuoi eseguire la scansione? (default: 7): " giorni_scelti
		giorni_scelti=${giorni_scelti:-7}
		#verifica > 0
		if [[ "$giorni_scelti" =~ ^[0-9]+$ ]] && [ "$giorni_scelti" -gt 0 ]; then
			break
		fi
		echo "[ERRORE] Inserisci un numero di giorni valido (maggiore di 0)."
        done
	echo "Attivazione updater in corso..."
        # Lancia update.sh passandogli parametro per l'attivazione rapida
        bash "$SCRIPT_DIR/updater.sh" --setup-auto "$giorni_scelti"
    else
        echo "[ERRORE][ATTENZIONE] File updater.sh non trovato nella cartella."
    fi
    else
    	echo "Aggiornamenti automatici disattivati, potrai attivarli quando vuoi lanciando updater.sh"
fi

echo "=== SETUP COMPLETATO ==="

# Blocca il terminale e aspetta l'input dell'utente
read -n 1 -s -r -p "Premere un tasto per continuare..."
echo ""
