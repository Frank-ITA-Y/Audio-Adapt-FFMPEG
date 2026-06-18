# Windows Updater by Lo_Re, Copyright(cc) all rights reserved

# --- PARAMETRI ACCETTATI ---
param (
    [switch]$SetupAuto,
    [switch]$Dis,
    [switch]$ec,
    [switch]$h,
    [string]$Giorni
)

$ConfigFile = ".config_update.txt"
$TaskName = "FfmpegUpdater_Lo_Re"
$LogFile = "$HOME\.cache\ffmpeg_updater_log.txt"
$ScriptPath = $MyInvocation.MyCommand.Path

# Funzione per caricare la configurazione attuale
function Carica-Config {
    if (Test-Path $ConfigFile) {
        $global:ATTIVO = Get-Content $ConfigFile -TotalCount 1
        $global:GIORNI_SALVATI = Get-Content $ConfigFile | Select-Object -Skip 1 -First 1
    } else {
        $global:ATTIVO = "no"
        $global:GIORNI_SALVATI = 7
    }
}

# Funzione per salvare la configurazione e applicare il Task su Windows
function Salva-E-Applica-Config {
    "$global:ATTIVO`n$global:GIORNI_SALVATI" | Out-File $ConfigFile -Encoding utf8
    
    # Rimuove sempre il vecchio Task per evitare conflitti o per disattivarlo
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

    if ($global:ATTIVO -eq "si") {
        # Configura l'azione: lancia PowerShell nascosto che esegue questo script in modalità silenziosa
        $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -File `"$ScriptPath`" -RunSilently"
        
        # Crea un trigger giornaliero. Windows gestirà la ripetizione in base ai giorni
        $Trigger = New-ScheduledTaskTrigger -Daily -At "12:00PM"
        
        # Registra l'operazione pianificata nel sistema
        Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Description "Controllo periodico aggiornamenti FFmpeg by Lo_Re" -Force | Out-Null
        Write-Host "Automatismo ATTIVATO: il controllo avverrà in background." -ForegroundColor Green
    } else {
        Write-Host "Automatismo DISATTIVATO: nessuna operazione pianificata nel sistema." -ForegroundColor Yellow
    }
}

# --- LOGICA DEI PARAMETRI ---

# 1. PARAMETRO HELP (-h)
if ($h) {
    Write-Host "=== GUIDA DI UTILIZZO (update.ps1 - Windows) ===" -ForegroundColor Cyan
    Write-Host "Uso standard: Esegue subito un controllo e aggiorna ffmpeg via Winget."
    Write-Host "`nPARAMETRI DISPONIBILI:"
    Write-Host "  -h    Mostra questa schermata di aiuto."
    Write-Host "  -ec   Modifica la pianificazione (attiva/disattiva o cambia i giorni)."
    Write-Host "  -Dis  Disattiva completamente l'automatismo in background."
    Write-Host "`nNota: I controlli automatici salvano i log in: $LogFile"
    Exit
}

# 2. PARAMETRO DISATTIVAZIONE (-Dis)
if ($Dis) {
    $global:ATTIVO = "no"
    $global:GIORNI_SALVATI = 7
    Salva-E-Applica-Config
    Exit
}

# 3. PARAMETRO COFIGURAZIONE RAPIDA DALL'INSTALLER (-SetupAuto)
if ($SetupAuto) {
    $global:ATTIVO = "si"
    $global:GIORNI_SALVATI = if ($Giorni) { $Giorni } else { 7 }
    Salva-E-Applica-Config
    Exit
}

# 4. PARAMETRO MODIFICA CONFIGURAZIONE (-ec)
if ($ec) {
    Write-Host "=== MODIFICA PIANIFICAZIONE AGGIORNAMENTI (WINDOWS) ===" -ForegroundColor Cyan
    Carica-Config
    Write-Host "Stato attuale: Automatico=$global:ATTIVO | Ogni=$global:GIORNI_SALVATI giorni"
    Write-Host "--------------------------------------------------------"
    
    while ($true) {
        $scelta_attiva = Read-Host "Vuoi attivare il controllo automatico periodico? [S/n]"
        if ([string]::IsNullOrEmpty($scelta_attiva)) { $scelta_attiva = "S" }
        if ($scelta_attiva -match "^[Ss]$") { $global:ATTIVO = "si"; break }
        if ($scelta_attiva -match "^[Nn]$") { $global:ATTIVO = "no"; break }
    }

    if ($global:ATTIVO -eq "si") {
        while ($true) {
            $scelta_giorni = Read-Host "Ogni quanti giorni vuoi eseguire la scansione? (default: 7)"
            if ([string]::IsNullOrEmpty($scelta_giorni)) { $scelta_giorni = 7 }
            if ($scelta_giorni -match "^\d+$" -and [int]$scelta_giorni -gt 0) { $global:GIORNI_SALVATI = $scelta_giorni; break }
            Write-Host "[ERRORE] Inserisci un numero di giorni valido." -ForegroundColor Red
        }
    }
    Salva-E-Applica-Config
    Exit
}

# 5. MODALITÀ SILENZIOSA (Eseguita dal Task Scheduler)
if ($args -contains "-RunSilently") {
    $LogDir = Split-Path -Parent $LogFile
    if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Force -Path $LogDir | Out-Null }
    # Reindirizza tutto l'output sul file di log
    Start-Transcript -Path $LogFile -Append -Force | Out-Null
}

# --- ESECUZIONE AGGIORNAMENTO EFFETTIVO ---
Write-Host "=== CONTROLLO AGGIORNAMENTI WINDOWS: $(Get-Date) ===" -ForegroundColor Cyan
Write-Host "Verifica disponibilità nuove versioni di ffmpeg via Winget..."

if (Get-Command winget -ErrorAction SilentlyContinue) {
    # Cerca e installa l'aggiornamento solo se disponibile, in modo silenzioso
    winget upgrade --id GYAN.FFmpeg --silent --accept-source-agreements --accept-package-agreements
    Write-Host "Controllo completato con successo."
} else {
    Write-Host "[ERRORE] Winget non trovato sul sistema. Impossibile aggiornare automaticamente." -ForegroundColor Red
}

echo "--------------------------------------------------------"

if ($args -contains "-RunSilently") {
    Stop-Transcript | Out-Null
} else {
    Write-Host "Premere un tasto per terminare..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
