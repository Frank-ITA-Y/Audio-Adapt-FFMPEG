#!/bin/bash
#Program by Lo_Re, Copyright(cc) not siutable for commercial use
# COnfig File
CONFIG_FILE=".nome_cartella.txt"

# Valori predefiniti (se il file di configurazione non esiste)
DEFAULT_CARTELLA="Pubblicabili"
DEFAULT_ESTENSIONE=".wav"
DEFAULT_FREQUENZA=44100
DEFAULT_BIT=16

# Funzione per caricare la configurazione dal file
carica_configurazione() {
    if [ -f "$CONFIG_FILE" ]; then
        # Legge le rige del file. Se mancano dei valori, usa i default di fabbrica
        NOME_CARTELLA=$(sed -n '1p' "$CONFIG_FILE")
        ESTENSIONE=$(sed -n '2p' "$CONFIG_FILE")
        FREQUENZA=$(sed -n '3p' "$CONFIG_FILE")
        BIT=$(sed -n '4p' "$CONFIG_FILE")
        
        NOME_CARTELLA=${NOME_CARTELLA:-$DEFAULT_CARTELLA}
        ESTENSIONE=${ESTENSIONE:-$DEFAULT_ESTENSIONE}
        FREQUENZA=${FREQUENZA:-$DEFAULT_FREQUENZA}
        BIT=${BIT:-$DEFAULT_BIT}
    else
        # Se il file non esiste, inizializza con i default
        NOME_CARTELLA=$DEFAULT_CARTELLA
        ESTENSIONE=$DEFAULT_ESTENSIONE
        FREQUENZA=$DEFAULT_FREQUENZA
        BIT=$DEFAULT_BIT
    fi
}

# Funzione per salvare la configurazione nel file
salva_configurazione() {
    echo "$NOME_CARTELLA" > "$CONFIG_FILE"
    echo "$ESTENSIONE" >> "$CONFIG_FILE"
    echo "$FREQUENZA" >> "$CONFIG_FILE"
    echo "$BIT" >> "$CONFIG_FILE"
}

# Carica i valori correnti prima di controllare i parametri
carica_configurazione

# FUNZIONE HELP (-h)
mostra_help() {
    echo "=== GUIDA DI UTILIZZO ==="
    echo "Uso standard: Trascina i file nel terminale per convertirli con le impostazioni attuali."
    echo ""
    echo "PARAMETRI VOLATILI (Validi solo per l'esecuzione corrente):"
    echo "  -e [estensione]  Modifica l'estensione di output (es: .wav, .mp3, .flac)"
    echo "  -fc [frequenza]  Modifica la frequenza in Hz (range accettato: 4000 - 192000)"
    echo "  -b [bit]         Modifica i bit di quantizzazione (accetta solo: 16 o 24)"
    echo ""
    echo "PARAMETRI DI CONFIGURAZIONE PERMANENTE:"
    echo "  -ec              Modifica in modo permanente le impostazioni correnti"
    echo ""
    echo "Esempio d'uso temporaneo: ./Adatta_files.sh -fc 48000 -b 24"
    exit 0
}

# FUNZIONE MODIFICA CONFIGURAZIONE (-ec)
modifica_config_permanente() {
    echo "=== MODIFICA CONFIGURAZIONE PERMANENTE ==="
    
    read -p "Inserisci nome cartella di pubblicazione (Attuale: $NOME_CARTELLA): " nuova_cartella
    NOME_CARTELLA=${nuova_cartella:-$NOME_CARTELLA}
    
    read -p "Inserisci estensione con punto (Attuale: $ESTENSIONE): " nuova_est
    ESTENSIONE=${nuova_est:-$ESTENSIONE}
    
    while true; do
        read -p "Inserisci frequenza Hz (Attuale: $FREQUENZA): " nuova_fc
        nuova_fc=${nuova_fc:-$FREQUENZA}
        if [[ "$nuova_fc" -ge 4000 && "$nuova_fc" -le 192000 ]]; then
            FREQUENZA=$nuova_fc
            break
        fi
        echo "[ERRORE] Inserisci una frequenza valida tra 4000 e 192000 Hz."
    done

    while true; do
        read -p "Inserisci bit 16 o 24 (Attuale: $BIT): " nuovi_bit
        nuovi_bit=${nuovi_bit:-$BIT}
        if [[ "$nuovi_bit" -eq 16 || "$nuovi_bit" -eq 24 ]]; then
            BIT=$nuovi_bit
            break
        fi
        echo "[ERRORE] Sono accettati solo i valori 16 o 24."
    done

    salva_configurazione
    echo "--------------------------------------------------------"
    echo "Impostazioni salvate con successo nel file '$CONFIG_FILE'!"
    exit 0
}

# --- GESTIONE DEI PARAMETRI DA TERMINALE ---
while [[ .# -gt 0 ]]; do
    case "$1" in
        -h)
            mostra_help
            ;;
        -ec)
            modifica_config_permanente
            ;;
        -e)
            ESTENSIONE="$2"
            shift 2
            ;;
        -fc)
            if [[ "$2" -ge 4000 && "$2" -le 192000 ]]; then
                FREQUENZA="$2"
            else
                echo "[ATTENZIONE] Frequenza '$2' non valida. Utilizzo valore predefinito: $FREQUENZA Hz."
            fi
            shift 2
            ;;
        -b)
            if [[ "$2" -eq 16 || "$2" -eq 24 ]]; then
                BIT="$2"
            else
                echo "[ATTENZIONE] Bit '$2' non validi. Vengono accettati solo 16 o 24. Utilizzo valore predefinito: $BIT bit."
            fi
            shift 2
            ;;
        *)
            echo "Parametro sconosciuto: $1. Usa -h per la guida."
            exit 1
            ;;
    esac
done

# --- PRIMA CONFIGURAZIONE ASSOLUTA (Se il file non esiste ancora) ---
if [ ! -f "$CONFIG_FILE" ]; then
    echo "=== CONFIGURAZIONE INIZIALE ==="
    echo "Premi INVIO se vuoi saltare e usare i valori predefiniti."
    read -p "Inserisci il nome per la cartella di pubblicazione (default: Pubblicabili): " scelta_utente
    NOME_CARTELLA=${scelta_utente:-$DEFAULT_CARTELLA}
    salva_configurazione
    echo "Cartella impostata su: '$NOME_CARTELLA'. Non ti verrà più richiesto."
    echo "Usa il parametro -h per scoprire come modificare le impostazioni audio."
    echo "------------------------------------------------------------------------"
fi

# Crea la cartella di destinazione
mkdir -p "$NOME_CARTELLA"

# Configura il codec corretto per ffmpeg in base ai bit scelti
if [ "$BIT" -eq 24 ]; then
    CODEC="pcm_s24le"
else
    CODEC="pcm_s16le"
fi

# --- INTERFACCIA PRINCIPALE ---
echo "=== CONVERTITORE AUDIO FFMPEG (Estensione: '$ESTENSIONE', Frequenza: '$FREQUENZA' Hz, Bit: '$BIT' bit) ==="
echo "I files verranno salvati nella cartella '$NOME_CARTELLA'"
echo "Lancia lo script con il parametro -h se vuoi le info per modificare la configurazione!"
echo "Trascina qui dentro i file che vuoi convertire (anche tutti insieme) e premi INVIO:"
echo "--------------------------------------------------------"
read -r -p "> " input_files

echo ""
echo "=== RIEPILOGO FILES SELEZIONATI ==="
eval "for file in $input_files; do
    if [ -f \"\$file\" ]; then
        echo \"- \$(basename \"\$file\")\"
    fi
done"
echo "--------------------------------------------------"

# Gestione della conferma con INVIO predefinito su SI
read -p "Vuoi procedere con la finalizzazione dei files? [S/n]: " conferma
# Se l'utente preme invio, la variabile "conferma" è vuota, quindi la impostiamo a "S"
conferma=${conferma:-S}

if [[ ! "$conferma" =~ ^[Ss]$ ]]; then
    echo ""
    echo "Operazione annullata dall'utente."
    read -n 1 -s -r -p "Premere un tasto per uscire..."
    exit 0
fi

echo ""
echo "=== INIZIO CONVERSIONE ==="

eval "for file in $input_files; do 
    if [ -f \"\$file\" ]; then
        nome_completo=\$(basename \"\$file\")
        nome_s_estensione=\"\${nome_completo%.*}\"
        
        echo \"Elaborazione di: \$nome_completo...\"
        
        # Esecuzione dinamica
        ffmpeg -i \"\$file\" -ar $FREQUENZA -ac 2 -c:a $CODEC \"$NOME_CARTELLA/\${nome_s_estensione}_pubblicazione$ESTENSIONE\" -y
        
    else
        echo \"[ERRORE] File non trovato o non valido: \$file (Salto al prossimo...)\"
    fi
done"

echo "------------------------------------------------------------------------"
echo "=== CONVERSIONE COMPLETATA CON SUCCESSO! ==="
echo ""

read -n 1 -s -r -p "Premere un tasto per continuare..."
echo ""
