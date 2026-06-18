# Converter by Lo_Re, Copyright(cc) all rights reserved

# --- PARAMETRI ACCETTATI DA TERMINALE ---
param (
    [string]$e,
    [string]$fc,
    [string]$b,
    [switch]$ec,
    [switch]$h
)

# --- FILE DI CONFIGURAZIONE PERMANENTE ---
$ConfigFile = ".nome_cartella.txt"

# Valori predefiniti di fabbrica
$DefaultCartella = "Pubblicabili"
$DefaultEstensione = ".wav"
$DefaultFrequenza = 44100
$DefaultBit = 16

# Funzione per caricare la configurazione dal file
function Carica-Configurazione {
    if (Test-Path $ConfigFile) {
        $righe = Get-Content $ConfigFile
        $global:NOME_CARTELLA = if ($righe[0]) { $righe[0] } else { $DefaultCartella }
        $global:ESTENSIONE = if ($righe[1]) { $righe[1] } else { $DefaultEstensione }
        $global:FREQUENZA = if ($righe[2]) { $righe[2] } else { $DefaultFrequenza }
        $global:BIT = if ($righe[3]) { $righe[3] } else { $DefaultBit }
    } else {
        $global:NOME_CARTELLA = $DefaultCartella
        $global:ESTENSIONE = $DefaultEstensione
        $global:FREQUENZA = $DefaultFrequenza
        $global:BIT = $DefaultBit
    }
}

# Funzione per salvare la configurazione nel file
function Salva-Configurazione {
    "$global:NOME_CARTELLA`n$global:ESTENSIONE`n$global:FREQUENZA`n$global:BIT" | Out-File $ConfigFile -Encoding utf8
}

# Carica i valori correnti prima di valutare le azioni
Carica-Configurazione

# --- FUNZIONE HELP (-h) ---
if ($h) {
    Write-Host "=== GUIDA DI UTILIZZO ===" -ForegroundColor Cyan
    Write-Host "Uso standard: Trascina i file nel terminale per convertirli con le impostazioni attuali."
    Write-Host "`nPARAMETRI VOLATILI (Validi solo per l'esecuzione corrente):"
    Write-Host "  -e [estensione]  Modifica l'estensione di output (es: .wav, .mp3, .flac)"
    Write-Host "  -fc [frequenza]  Modifica la frequenza in Hz (range accettato: 4000 - 192000)"
    Write-Host "  -b [bit]         Modifica i bit di quantizzazione (accetta solo: 16 o 24)"
    Write-Host "`nPARAMETRI DI CONFIGURAZIONE PERMANENTE:"
    Write-Host "  -ec              Modifica in modo permanente le impostazioni correnti"
    Write-Host "`nEsempio d'uso temporaneo: .\Adatta_files.ps1 -fc 48000 -b 24"
    Exit
}

# --- FUNZIONE MODIFICA CONFIGURAZIONE (-ec) ---
if ($ec) {
    Write-Host "=== MODIFICA CONFIGURAZIONE PERMANENTE ===" -ForegroundColor Cyan
    
    $nuova_cartella = Read-Host "Inserisci nome cartella di pubblicazione (Attuale: $global:NOME_CARTELLA)"
    if ($nuova_cartella) { $global:NOME_CARTELLA = $nuova_cartella }
    
    $nuova_est = Read-Host "Inserisci estensione con punto (Attuale: $global:ESTENSIONE)"
    if ($nuova_est) { $global:ESTENSIONE = $nuova_est }
    
    while ($true) {
        $nuova_fc = Read-Host "Inserisci frequenza Hz (Attuale: $global:FREQUENZA)"
        if ([string]::IsNullOrEmpty($nuova_fc)) { $nuova_fc = $global:FREQUENZA }
        if ($nuova_fc -match "^\d+$" -and [int]$nuova_fc -ge 4000 -and [int]$nuova_fc -le 192000) {
            $global:FREQUENZA = $nuova_fc
            break
        }
        Write-Host "[ERRORE] Inserisci una frequenza valida tra 4000 e 192000 Hz." -ForegroundColor Red
    }

    while ($true) {
        $nuovi_bit = Read-Host "Inserisci bit 16 o 24 (Attuale: $global:BIT)"
        if ([string]::IsNullOrEmpty($nuovi_bit)) { $nuovi_bit = $global:BIT }
        if ($nuovi_bit -eq 16 -or $nuovi_bit -eq 24) {
            $global:BIT = $nuovi_bit
            break
        }
        Write-Host "[ERRORE] Sono accettati solo i valori 16 o 24." -ForegroundColor Red
    }

    Salva-Configurazione
    Write-Host "--------------------------------------------------------"
    Write-Host "Impostazioni salvate con successo nel file '$ConfigFile'!" -ForegroundColor Green
    Exit
}

# --- GESTIONE PARAMETRI TEMPORANEI DA RIGA DI COMANDO ---
if ($e) { $global:ESTENSIONE = $e }
if ($fc) {
    if ($fc -match "^\d+$" -and [int]$fc -ge 4000 -and [int]$fc -le 192000) {
        $global:FREQUENZA = $fc
    } else {
        Write-Host "[ATTENZIONE] Frequenza '$fc' non valida. Utilizzo valore predefinito: $global:FREQUENZA Hz." -ForegroundColor Yellow
    }
}
if ($b) {
    if ($b -eq 16 -or $b -eq 24) {
        $global:BIT = $b
    } else {
        Write-Host "[ATTENZIONE] Bit '$b' non validi (solo 16 o 24). Utilizzo valore predefinito: $global:BIT bit." -ForegroundColor Yellow
    }
}

# --- PRIMA CONFIGURAZIONE ASSOLUTA ---
if (-not (Test-Path $ConfigFile)) {
    Write-Host "=== CONFIGURAZIONE INIZIALE ===" -ForegroundColor Cyan
    Write-Host "Premi INVIO se vuoi saltare e usare i valori predefiniti."
    $scelta_utente = Read-Host "Inserisci il nome per la cartella di pubblicazione (default: Pubblicabili)"
    if ($scelta_utente) { $global:NOME_CARTELLA = $scelta_utente }
    Salva-Configurazione
    Write-Host "Cartella impostata su: '$global:NOME_CARTELLA'. Non ti verrà più richiesto." -ForegroundColor Green
    Write-Host "Usa il parametro -h per scoprire come modificare le impostazioni audio.`n" -ForegroundColor Yellow
}

# Crea la cartella di destinazione
if (-not (Test-Path $global:NOME_CARTELLA)) {
    New-Item -ItemType Directory -Force -Path $global:NOME_CARTELLA | Out-Null
}

# Configura il codec per ffmpeg in base ai bit
$CODEC = if ($global:BIT -eq 24) { "pcm_s24le" } else { "pcm_s16le" }

# --- INTERFACCIA PRINCIPALE ---
Write-Host "=== CONVERTITORE AUDIO FFMPEG (Estensione: '$global:ESTENSIONE', Frequenza: '$global:FREQUENZA' Hz, Bit: '$global:BIT' bit) ===" -ForegroundColor Cyan
Write-Host "I files verranno salvati nella cartella '$global:NOME_CARTELLA'"
Write-Host "Lancia lo script con il parametro -h se vuoi le info per modificare la configurazione!"
Write-Host "Trascina qui dentro i file che vuoi convertire (anche tutti insieme) e premi INVIO:"
Write-Host "--------------------------------------------------------"
$input_files = Read-Host "> "

# Trucco PowerShell per dividere correttamente la stringa del drag&drop (gestisce spazi e virgolette di Windows)
$FilesArray = [regex]::Matches($input_files, '"[^"\r\n]*"|[^ \t"\r\n]+') | ForEach-Object { $_.Value.Trim('"') }

Write-Host "`n=== RIEPILOGO FILES SELEZIONATI ===" -ForegroundColor Cyan
foreach ($file in $FilesArray) {
    if (Test-Path $file -PathType Leaf) {
        Write-Host "- $(Split-Path $file -Leaf)"
    }
}
Write-Host "--------------------------------------------------"

# Conferma con INVIO predefinito su SI (S)
$conferma = Read-Host "Vuoi procedere con la finalizzazione dei files? [S/n]"
if ([string]::IsNullOrEmpty($conferma)) { $conferma = "S" }

if ($conferma -notmatch "^[Ss]$") {
    Write-Host "`nOperazione annullata dall'utente." -ForegroundColor Yellow
    Write-Host "Premere un tasto per uscire..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Exit
}

Write-Host "`n=== INIZIO CONVERSIONE ===" -ForegroundColor Green

foreach ($file in $FilesArray) {
    if (Test-Path $file -PathType Leaf) {
        $nome_completo = Split-Path $file -Leaf
        $nome_senza_estensione = [System.IO.Path]::GetFileNameWithoutExtension($file)
        
        Write-Host "Elaborazione di: $nome_completo..."
        
        # Output path
        $OutputFile = Join-Path $global:NOME_CARTELLA "${nome_senza_estensione}_pubblicazione$global:ESTENSIONE"
        
        # Esecuzione nativa FFmpeg zittendo i log pesanti di debug stream con -loglevel error
        & ffmpeg -i $file -ar $global:FREQUENZA -ac 2 -c:a $CODEC $OutputFile -y -loglevel error
    } else {
        Write-Host "[ERRORE] File non trovato o non valido: $file (Salto al prossimo...)" -ForegroundColor Red
    }
}

Write-Host "------------------------------------------------------------------------"
Write-Host "=== CONVERSIONE COMPLETATA CON SUCCESSO! ===" -ForegroundColor Green
Write-Host ""

# Blocco chiusura
Write-Host "Premere un tasto per continuare..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")