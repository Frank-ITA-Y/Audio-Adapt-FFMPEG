# Windows Installer by Lo_Re, Copyright(cc) all rights reserved

# Admin
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "=== ERRORE ===" -ForegroundColor Red
    Write-Host "Questo script deve essere eseguito come AMMINISTRATORE." -ForegroundColor Red
    Write-Host "Fai click destro sul file 'installer.ps1' e seleziona 'Esegui con PowerShell' (oppure apri PowerShell come Amministratore)." -ForegroundColor Yellow
    Write-Host "`nPremere un tasto per uscire..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Exit
}
# sblocco script
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
Unblock-File -Path "$ScriptDir\adatta_files.ps1" -ErrorAction SilentlyContinue
Unblock-File -Path "$ScriptDir\update.ps1" -ErrorAction SilentlyContinue

Write-Host "=== INIZIO INSTALLAZIONE FFMPEG (WINDOWS) ===" -ForegroundColor Cyan
Write-Host "Il processo richiede qualche minuto..."
Write-Host "----------------------------------------------------------------"

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "[INFO] Winget non trovato. Tentativo di installazione automatica..." -ForegroundColor Yellow
    
    # Crea una cartella temporanea sicura per il download
    $tempDir = Join-Path $env:TEMP "WingetInstaller"
    New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
    
    $msixbundlePath = Join-Path $tempDir "Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
    
    Write-Host "Scaricamento di Windows Package Manager da Microsoft GitHub..." -ForegroundColor Gray
    # Scarica l'ultima release stabile di App Installer (Winget)
    Invoke-WebRequest -Uri "https://github.com/microsoft/winget-cli/releases/download/v1.28.240/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -OutFile $msixbundlePath
    
    Write-Host "Installazione di Winget nel sistema in corso..." -ForegroundColor Gray
    # Installa il pacchetto MSIX nel sistema di Windows
    Add-AppxPackage -Path $msixbundlePath -ErrorAction Stop
    
    # Pulisce file temporanei
    Remove-Item -Recurse -Force $tempDir
    
    # Rinfresco comandi
    Import-Module Appx -Force
    
    # Controllo
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "[ERRORE] Impossibile configurare Winget automaticamente. Aggiorna Windows tramite Windows Update." -ForegroundColor Red
        Write-Host "Premere un tasto per uscire..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        Exit
    }
    Write-Host "Winget configurato con successo!" -ForegroundColor Green
}
# INSTALLAZIONE FFMPEG
Write-Host "Installazione di FFmpeg in corso..." -ForegroundColor Gray
winget install --id GYAN.FFmpeg --silent --accept-source-agreements --accept-package-agreements
# ffmpeg Path
if ($LASTEXITCODE -eq 0 -or (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Host "`n=== INSTALLAZIONE COMPLETATA CON SUCCESSO! ===" -ForegroundColor Green
} else {
    Write-Host "`n[ERRORE] L'installazione di FFmpeg è fallita." -ForegroundColor Red
    Write-Host "Premere un tasto per uscire..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Exit
}
# update
# Configurazione Aggiornamenti (Versione Fixata)
$Host.UI.RawUI.FlushInputBuffer()
Write-Host "`n=== CONFIGURAZIONE AGGIORNAMENTI ===" -ForegroundColor Cyan
$scelta_up = Read-Host "Vuoi attivare il controllo automatico degli aggiornamenti? [s/N]"
if ([string]::IsNullOrEmpty($scelta_up)) { $scelta_up = "N" }

if ($scelta_up -match "^[Ss]$") {
    if (Test-Path "$ScriptDir\update.ps1") {
        
        # FISSO FONDAMENTALE: Svuota il buffer della tastiera per evitare il salto automatico
        $Host.UI.RawUI.FlushInputBuffer()
        
        while ($true) {
            $giorni_scelti = Read-Host "Ogni quanti giorni vuoi eseguire la scansione? (default: 7)"
            if ([string]::IsNullOrEmpty($giorni_scelti)) { $giorni_scelti = 7 }
            
            # Verifica rigorosa in PowerShell per controllare che sia un numero maggiore di 0
            if ($giorni_scelti -match "^\d+$" -and [int]$giorni_scelti -gt 0) {
                break
            }
            Write-Host "[ERRORE] Inserisci un numero di giorni valido (maggiore di 0)." -ForegroundColor Red
        }
        Write-Host "Attivazione updater in corso..." -ForegroundColor Gray
        
        # Lancia update.ps1
        & "$ScriptDir\update.ps1" -SetupAuto -Giorni $giorni_scelti
    } else {
        Write-Host "[ERRORE] File 'update.ps1' non trovato nella cartella." -ForegroundColor Red
    }
} else {
    Write-Host "Disattivazione o mantenimento updater spento..." -ForegroundColor Yellow
    if (Test-Path "$ScriptDir\update.ps1") {
        & "$ScriptDir\update.ps1" -Dis
    }
}

Write-Host "`n=== SETUP COMPLETATO ===" -ForegroundColor Green
Write-Host "Premere un tasto per continuare..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")