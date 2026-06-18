#!/bin/bash

# Linux Multi-Distro & Flatpak Installer by Lo_Re, Copyright(cc) all rights reserved

# Permessi script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
chmod +x "$SCRIPT_DIR/adatta_files.sh" 2>/dev/null
chmod +x "$SCRIPT_DIR/update.sh" 2>/dev/null

echo "=== INIZIO INSTALLAZIONE FFMPEG (LINUX) ==="
echo "------------------------------------------------------------------------------------------"
echo "Scegli il metodo di installazione desiderato:"
echo "1) Flatpak [CONSIGLIATO] (Permette aggiornamenti automatici in background senza password)"
echo "2) Package Manager Nativo del sistema (Richiede privilegi di amministratore/sudo)"
echo "------------------------------------------------------------------------------------------"
read -p "Seleziona un'opzione (1-2, default: 1): " metodo_scelto
metodo_scelto=${metodo_scelto:-1}

installa_flatpak() {
    echo ""
    echo "=== INSTALLAZIONE TRAMITE FLATPAK ==="
    if ! command -v flatpak &> /dev/null; then
        echo "[ERRORE] Flatpak non è installato su questo sistema."
        echo "Installa il pacchetto 'flatpak' tramite il software store della tua distro e riprova."
        exit 1
    fi
    echo "Aggiunta del repository Flathub..."
    flatpak remote-add --user --if-not-exists flathub https://flathub.org
    echo "Installazione del runtime Freedesktop FFmpeg..."
    flatpak install --user flathub org.freedesktop.Platform.ffmpeg-full -y

    echo "Configurazione dell'alias di sistema..."
    if ! grep -q "alias ffmpeg=" ~/.bashrc; then
        echo "alias ffmpeg='flatpak run --command=ffmpeg org.freedesktop.Platform.ffmpeg-full'" >> ~/.bashrc
        [ -f ~/.zshrc ] && echo "alias ffmpeg='flatpak run --command=ffmpeg org.freedesktop.Platform.ffmpeg-full'" >> ~/.zshrc
    fi
    alias ffmpeg='flatpak run --command=ffmpeg org.freedesktop.Platform.ffmpeg-full'
    DISTRO="flatpak"
}

if [ "$metodo_scelto" -eq 1 ]; then
    installa_flatpak
else
    #  IDENTIFICAZIONE AUTOMATICA DISTRIBUZIONE
    DISTRO=""
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        DISTRO=$(echo "$ID" | tr '[:upper:]' '[:lower:]')
        DISTRO_LIKE=$(echo "$ID_LIKE" | tr '[:upper:]' '[:lower:]')
    fi

    # INSTALLAZIONE NATIVA
    case "$DISTRO" in
        ubuntu|debian|mint|pop|zorin|kali)
            echo "[RILEVATO] Sistema nativo Debian/Ubuntu ($ID)"
            sudo apt-get update -y && sudo apt-get install ffmpeg -y
            ;;
        arch|manjaro|endeavouros)
            echo "[RILEVATO] Sistema nativo Arch Linux ($ID)"
            sudo pacman -Syu --noconfirm ffmpeg
            ;;
        fedora|rhel|centos)
            echo "[RILEVATO] Sistema nativo Fedora/RedHat ($ID)"
            sudo dnf install ffmpeg -y
            ;;
        *)
            if [[ "$DISTRO_LIKE" =~ "ubuntu" || "$DISTRO_LIKE" =~ "debian" ]]; then
                echo "[RILEVATO] Sistema derivato da Debian/Ubuntu"
                sudo apt-get update -y && sudo apt-get install ffmpeg -y
            elif [[ "$DISTRO_LIKE" =~ "arch" ]]; then
                echo "[RILEVATO] Sistema derivato da Arch Linux"
                sudo pacman -Syu --noconfirm ffmpeg
            elif [[ "$DISTRO_LIKE" =~ "fedora" ]]; then
                echo "[RILEVATO] Sistema derivato da Fedora"
                sudo dnf install ffmpeg -y
            else
                echo "[ATTENZIONE] Impossibile rilevare automaticamente la tua distribuzione Linux."
                echo "Seleziona manualmente la famiglia del tuo sistema operativo:"
                echo "1) Debian / Ubuntu based (Usa APT)"
                echo "2) Arch Linux based (Usa PACMAN)"
                echo "3) Fedora based (Usa DNF)"
                echo "--------------------------------------------------------"
                read -p "Inserisci una scelta (1-3): " scelta_scuderia
                case "$scelta_scuderia" in
                    1) DISTRO="debian"; sudo apt-get update -y && sudo apt-get install ffmpeg -y ;;
                    2) DISTRO="arch"; sudo pacman -Syu --noconfirm ffmpeg ;;
                    3) DISTRO="fedora"; sudo dnf install ffmpeg -y ;;
                    *) echo "[ERRORE] Scelta non valida."; exit 1 ;;
                esac
            fi
            ;;
    esac
fi


# Verifica
if [ $? -eq 0 ] || [ "$DISTRO" = "flatpak" ]; then
    echo ""
    echo "=== INSTALLAZIONE COMPLETATA CON SUCCESSO! ==="
    [ "$DISTRO" = "flatpak" ] && echo "[INFO] Riavvia il terminale dopo il setup per attivare i comandi Flatpak."
    echo ""
else
    echo "[ERRORE] Errore critico durante l'installazione di ffmpeg."
    exit 1
fi
# UPDATER
echo "=== CONFIGURAZIONE AGGIORNAMENTI ==="
read -p "Vuoi attivare il controllo automatico degli aggiornamenti? [s/N]: " scelta_up
scelta_up=${scelta_up:-N}

if [[ "$scelta_up" =~ ^[Ss]$ ]]; then
    if [ -f "$SCRIPT_DIR/update.sh" ]; then
        while true; do
            read -p "Ogni quanti giorni vuoi eseguire la scansione? (default: 7): " giorni_scelti
            giorni_scelti=${giorni_scelti:-7}
            if [[ "$giorni_scelti" =~ ^[0-9]+$ ]] && [ "$giorni_scelti" -gt 0 ]; then
                break
            fi
            echo "[ERRORE] Inserisci un numero di giorni valido (maggiore di 0)."
        done
        echo "Attivazione updater in corso..."
        bash "$SCRIPT_DIR/update.sh" --setup-auto "$giorni_scelti" "$DISTRO"
    else
        echo "[ERRORE][ATTENZIONE] File update.sh non trovato nella cartella."
    fi
else
    echo "Aggiornamenti automatici disattivati. Potrai attivarli quando vuoi lanciando update.sh"
fi

echo ""
echo "=== SETUP COMPLETATO ==="
echo ""
read -n 1 -s -r -p "Premere un tasto per continuare..."
echo ""
