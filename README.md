# 🎵 Audio-Adapt-FFmpeg

<p align="center">
  <img src="https://shields.io" alt="Platforms" />
  <img src="https://shields.io" alt="Dependencies" />
  <img src="https://shields.io" alt="License" />
</p>

<p align="center">
  <strong>A lightweight, cross-platform CLI toolkit designed to automate FFmpeg installation and batch-convert audio files for production and publishing.</strong>
</p>

---

## 🚀 Overview

**Audio-Adapt-FFmpeg** is an automated utility built for creators and audio engineers who need a zero-friction workflow to standardise their audio assets. It completely eliminates terminal complexity for non-technical users by handling dependency management, system paths, and automated background maintenance across all major operating systems.

### Key Features
* 📦 **Zero-Config Installers**: Installs dependencies automatically across macOS (Homebrew), Linux (Multi-Distro/Flatpak), and Windows (Winget).
* 🎛️ **Smart Audio Standardisation**: Batch-converts dragged-and-dropped files into broadcast-ready `.wav` format (Stereo, 44.1kHz, 16-bit by default).
* ⚙️ **On-the-Fly Customization**: Modify bit depth (16/24-bit), sample rate (4kHz - 192kHz), output extensions, or destination folders via volatile flags or persistent CLI wizard configs.
* 🔄 **Invisible Automation**: Deploys native system daemons (`LaunchAgent` on macOS, `Cron` on Linux, `Task Scheduler` on Windows) during installation to silently update dependencies in the background every X days.

---

## 📂 Repository Structure

```text
├── macOS/                # macOS shell scripts (.sh)
│   ├── installer.sh      # Dependency manager & environment setup for Mac
│   ├── Adatta_files.sh   # Interactive audio-processing wizard
│   └── updater.sh        # Automated background updater via LaunchAgent
├── Linux/                # Linux shell scripts (.sh)
│   ├── installer.sh      # Native multi-distro & Flatpak dependency manager
│   ├── adatta_files.sh   # CLI batch converter with Unix space-handling
│   └── update.sh         # Automated background maintenance via Cron jobs
├── Windows/              # Windows PowerShell scripts (.ps1)
│   ├── installer.ps1     # Administrative Winget deployment & execution unlocker
│   ├── adatta_files.ps1  # Windows-optimized drag&drop audio converter
│   └── update.ps1        # Background updater via Task Scheduler
└── README.md             # Documentation
```

---

## 🍎 macOS Setup & Installation

### Step 1: Directory Setup
1. Create a new directory named `Audio`.
2. Move `installer.sh`, `Adatta_files.sh`, and `update.sh` inside the `Audio` folder.

### Step 2: Running the Installer
- Open your **Terminal** app (Press `Cmd + Space`, type `Terminal`, and hit `Enter`). 
- To bypass macOS security blocks without manually running `chmod`, execute the installer directly through `bash`:

```bash
bash ~/Desktop/Audio/installer.sh
```

> 🔑 **Note for Users**: The script will automatically configure Homebrew and FFmpeg. If prompted for your macOS system password, type it in and press `Enter`. *No characters or asterisks will appear on the screen while typing—this is a native macOS security feature.*

### Step 3: Configure Automatic Updates
At the end of the installation, the wizard will ask if you want to enable automatic background maintenance:
1. Press `y` (Yes) to activate the hidden background cron/daemon.
2. Input the interval in days (e.g., `7` for weekly checks). The system will now silently manage updates via `~/Library/LaunchAgents/` and log activity to `~/Library/Logs/FfmpegUpdater/`.

---

## 🐧 Linux Setup & Installation

### Step 1: Directory Setup
1. Create a new folder in your Home directory named `Audio`.
2. Move `installer.sh`, `Adatta_files.sh`, and `update.sh` from the `Linux/` repository folder inside it.

### Step 2: Choosing the Deployment Method
Open your terminal and run the installer using `bash`:
```bash
bash ~/Audio/installer.sh
```

You will be prompted to choose between two installation tracks:
1. **Flatpak [RECOMMENDED]**: Installs FFmpeg via a sandboxed user runtime. **This is highly recommended if you want hassle-free automated updates**, as Flatpak can update itself in the background without constantly requesting your `sudo` password.
2. **Native Package Manager**: Detects your distribution architecture and runs native tools (`apt` for Ubuntu/Debian, `pacman` for Arch, `dnf` for Fedora). 

> ### 🔑 Flatpak Requirement
> **`Installer.sh` does not install Flatpak automatically.** If you choose the **Flatpak** installation track, ensure it is already configured on your system before proceeding. *Once verified, you can safely finalize the installation.*

---

## 🔷 Windows Setup & Installation

> ### 🛡️ PowerShell Execution Policy
> Windows blocks custom scripts by default for security reasons. Before running the toolkit for the first time, you must unlock PowerShell. Open PowerShell **as Administrator** and run this command:
> ```powershell
> Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
> ```

### Step 1: Directory Setup
1. Create a new folder on your Desktop named `Audio`.
2. Move `install.ps1`, `Adatta_files.ps1`, and `update.ps1` from the `Windows/` folder inside it.

### Step 2: Running the Installer
1. Right-click `install.ps1` and choose **"Run with PowerShell"** (or open PowerShell as Admin, navigate to the folder, and run `.\install.ps1`).
2. The script will automatically check for **Winget**, configure **FFmpeg**, and offer to schedule automated background updates.

---

## 🎵 Audio Processing Workflow

Once installed, you can process files instantly by running the converter wizard.

### Standard Interactive Mode
Run the script by executing:
```bash
# On macOS
~/Desktop/Audio/Adatta_files.sh

# On Linux
~/Audio/Adatta_files.sh

# On Windows (PowerShell)
.\Adatta_files.ps1
```

1. **First Run**: The script asks you to name your publishing folder (Defaults to `Publish`). It generates a hidden config file `.nome_cartella.txt` so it never asks you again.
2. **File Selection**: **Drag and drop** multiple audio files directly from Files Manager into the Terminal window, then hit `Enter`.
3. **Review**: Check the clean file checklist generated by the script. Press `Enter` (defaulting to **Y**) to process, or `n` to cancel.

### Advanced CLI Arguments
For powerful users, `Adatta_files.sh` accepts runtime variables and persistent configuration flags:

| Flag | Argument | Description | Range / Options |
| :--- | :--- | :--- | :--- |
| `-h` | *None* | Displays the help manual | — |
| `-ec` | *None* | Launches the permanent audio configuration wizard | Setup folder, Hz, Bits |
| `-e` | `[extension]` | Changes output container for the current session | `.wav`, `.mp3`, `.flac` |
| `-fc`| `[frequency]` | Changes sample rate for the current session | `4000` to `192000` Hz |
| `-b` | `[bit_depth]` | Changes bit depth for the current session | `16` or `24` bit |

#### CLI Examples
* *Temporary override for HD master files:*
  ```bash
  ~/Desktop/Audio/Adatta_files.sh -fc 48000 -b 24
  ```
* *Modify your permanent audio profile:*
  ```bash
  ~/Desktop/Audio/Adatta_files.sh -ec
  ```
* *Ask for help:*
  ```powershell
  ~/Desktop/Audio/Adatta_files.ps1 -h
  ```

---

## 🔄 Background Updater CLI Controls

The background maintenance engine (`update.sh`) can be managed manually using specific flags from the terminal if you want to alter the scheduling behavior post-install.

| Flag | Description | Effect / Use Case |
| :--- | :--- | :--- |
| `-h` | Displays the updater help menu | Show logs directory and active syntax instructions |
| `-ec` | Launches the permanent update configuration wizard | Toggles background execution `[On/Off]` and changes the days interval |
| `-Dis`| Disables the background update schedules | Completely unregisters the daemon/task from the OS |

#### Example:
```bash
# macOS
~/Desktop/Audio/update.sh -ec

# Linux
~/Audio/update.sh -ec

# Windows
.\update.ps1 -ec
```

---

## 🛠️ Error Handling & Resiliency
* **Missing Files**: If a file path is corrupted or deleted mid-session, the script logs an `[ERROR]` block but **continues processing all remaining files** in the queue.
* **Upsampling Safety**: Upsampling lower frequencies (e.g., 22kHz to 44.1kHz) is handled safely via mathematical PCM mapping without crashing, regardless of the input container.

---
<p align="center"><sub>Developed by Lo_Re. Copyright (cc) All rights reserved.</sub></p>
