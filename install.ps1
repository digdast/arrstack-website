<#
.SYNOPSIS
    ArrStack Universal Windows Installer // ERTechLab
    One-Shot Installation of Plex, Radarr, Sonarr, Prowlarr, and qBittorrent
    Web: https://arrstack.ertechlab.com
#>

[CmdletBinding()]
param(
    [ValidateSet("Docker", "Native")]
    [string]$Mode = "Docker",

    [string]$StoragePath = "C:\ArrStack",
    [switch]$Silent
)

$ErrorActionPreference = "Stop"

# ANSI Colors for Windows Terminal / PowerShell 7
function Write-Header {
    Write-Host @"
   ██████╗ ██████╗ ██████╗ ███████╗████████╗ █████╗  ██████╗██╗  ██╗
  ██╔══██╗██╔══██╗██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██╔════╝██║ ██╔╝
  ███████║██████╔╝██████╔╝███████╗   ██║   ███████║██║     █████╔╝ 
  ██╔══██║██╔══██╗██╔══██╗╚════██║   ██║   ██╔══██║██║     ██╔═██╗ 
  ██║  ██║██║  ██║██║  ██║███████║   ██║   ██║  ██║╚██████╗██║  ██╗
  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝
─────────────────────────────────────────────────────────────────────────────
  ArrStack One-Shot Deployment Engine for Windows // ERTechLab
  Plex • Radarr • Sonarr • Prowlarr • qBittorrent • Jellyseerr
─────────────────────────────────────────────────────────────────────────────
"@ -ForegroundColor Cyan
}

Clear-Host
Write-Header

# Check Administrator Privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[!] Elevating to Administrator..." -ForegroundColor Yellow
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

# Prompt user if not silent
if (-not $Silent) {
    Write-Host "`n[?] Select Installation Mode:" -ForegroundColor Yellow
    Write-Host "  1) Docker Container Stack (Recommended - Clean, self-contained, isolated)"
    Write-Host "  2) Native Windows Desktop Applications (Direct executables via Winget)"
    $choice = Read-Host "Enter choice [1/2, default 1]"
    if ($choice -eq "2") {
        $Mode = "Native"
    } else {
        $Mode = "Docker"
    }

    $customPath = Read-Host "Target Storage Directory [Default: $StoragePath]"
    if (-not [string]::IsNullOrWhiteSpace($customPath)) {
        $StoragePath = $customPath
    }
}

Write-Host "`n[*] Installation Mode: $Mode" -ForegroundColor Green
Write-Host "[*] Storage Root:      $StoragePath" -ForegroundColor Cyan

# ------------------------------------------------------------------------------
# DOCKER MODE
# ------------------------------------------------------------------------------
if ($Mode -eq "Docker") {
    Write-Host "`n=== STEP 1: Verifying Docker Desktop & Compose ===" -ForegroundColor Cyan
    
    $dockerInstalled = Get-Command docker -ErrorAction SilentlyContinue
    if (-not $dockerInstalled) {
        Write-Host "[*] Docker not found. Installing Docker Desktop via Winget..." -ForegroundColor Yellow
        winget install --id Docker.DockerDesktop -e --silent --accept-package-agreements --accept-source-agreements
        Write-Host "[!] Docker Desktop installed. Please launch Docker Desktop once to initialize WSL2 backend." -ForegroundColor Green
        Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe" -ErrorAction SilentlyContinue
    } else {
        Write-Host "[✓] Docker is installed: $(docker --version)" -ForegroundColor Green
    }

    # Create directories
    Write-Host "`n=== STEP 2: Creating Directory Structures ===" -ForegroundColor Cyan
    $dirs = @(
        "$StoragePath\media\movies",
        "$StoragePath\media\tv",
        "$StoragePath\downloads\torrents",
        "$StoragePath\downloads\usenet",
        "$StoragePath\config\plex",
        "$StoragePath\config\radarr",
        "$StoragePath\config\sonarr",
        "$StoragePath\config\prowlarr",
        "$StoragePath\config\qbittorrent",
        "$StoragePath\config\jellyseerr"
    )
    foreach ($d in $dirs) {
        if (-not (Test-Path $d)) {
            New-Item -ItemType Directory -Path $d -Force | Out-Null
        }
    }
    Write-Host "[✓] Initialized folder hierarchy at $StoragePath" -ForegroundColor Green

    # Generate docker-compose.yml
    Write-Host "`n=== STEP 3: Generating docker-compose.yml ===" -ForegroundColor Cyan
    $composeFile = "$StoragePath\docker-compose.yml"
    $composeContent = @"
version: "3.8"

services:
  plex:
    image: lscr.io/linuxserver/plex:latest
    container_name: arrstack-plex
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
      - VERSION=docker
    volumes:
      - $StoragePath\config\plex:/config
      - $StoragePath\media\tv:/tv
      - $StoragePath\media\movies:/movies
    ports:
      - 32400:32400
    restart: unless-stopped

  radarr:
    image: lscr.io/linuxserver/radarr:latest
    container_name: arrstack-radarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - $StoragePath\config\radarr:/config
      - $StoragePath\media\movies:/movies
      - $StoragePath\downloads:/downloads
    ports:
      - 7878:7878
    restart: unless-stopped

  sonarr:
    image: lscr.io/linuxserver/sonarr:latest
    container_name: arrstack-sonarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - $StoragePath\config\sonarr:/config
      - $StoragePath\media\tv:/tv
      - $StoragePath\downloads:/downloads
    ports:
      - 8989:8989
    restart: unless-stopped

  prowlarr:
    image: lscr.io/linuxserver/prowlarr:latest
    container_name: arrstack-prowlarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - $StoragePath\config\prowlarr:/config
    ports:
      - 9696:9696
    restart: unless-stopped

  qbittorrent:
    image: lscr.io/linuxserver/qbittorrent:latest
    container_name: arrstack-qbittorrent
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
      - WEBUI_PORT=8080
      - TORRENTING_PORT=6881
    volumes:
      - $StoragePath\config\qbittorrent:/config
      - $StoragePath\downloads:/downloads
    ports:
      - 8080:8080
      - 6881:6881
      - 6881:6881/udp
    restart: unless-stopped

  flaresolverr:
    image: ghcr.io/flaresolverr/flaresolverr:latest
    container_name: arrstack-flaresolverr
    environment:
      - LOG_LEVEL=info
      - LOG_HTML=false
      - CAPTCHA_SOLVER=none
      - TZ=Etc/UTC
    ports:
      - 8191:8191
    restart: unless-stopped

  jellyseerr:
    image: fallenbagel/jellyseerr:latest
    container_name: arrstack-jellyseerr
    environment:
      - LOG_LEVEL=debug
      - TZ=Etc/UTC
    volumes:
      - $StoragePath\config\jellyseerr:/app/config
    ports:
      - 5055:5055
    restart: unless-stopped
"@
    Set-Content -Path $composeFile -Value $composeContent -Encoding UTF8
    Write-Host "[✓] Saved $composeFile" -ForegroundColor Green

    # Launch Containers
    Write-Host "`n=== STEP 4: Starting Docker Media Stack ===" -ForegroundColor Cyan
    Set-Location $StoragePath
    try {
        docker compose up -d
    } catch {
        Write-Host "[!] Note: If Docker Desktop is still starting, open Docker Desktop and run: docker compose up -d inside $StoragePath" -ForegroundColor Yellow
    }

# ------------------------------------------------------------------------------
# NATIVE MODE (WINGET)
# ------------------------------------------------------------------------------
} elseif ($Mode -eq "Native") {
    Write-Host "`n=== STEP 1: Installing Native Applications via Windows Package Manager ===" -ForegroundColor Cyan
    
    $packages = @(
        @{ Id = "Plex.PlexMediaServer"; Name = "Plex Media Server" },
        @{ Id = "TeamSonarr.Sonarr"; Name = "Sonarr TV Automator" },
        @{ Id = "Radarr.Radarr"; Name = "Radarr Movie Automator" },
        @{ Id = "Prowlarr.Prowlarr"; Name = "Prowlarr Indexer Manager" },
        @{ Id = "qBittorrent.qBittorrent"; Name = "qBittorrent Client" }
    )

    foreach ($pkg in $packages) {
        Write-Host "[*] Installing $($pkg.Name) ($($pkg.Id))..." -ForegroundColor Yellow
        winget install --id $pkg.Id -e --silent --accept-package-agreements --accept-source-agreements
        Write-Host "[✓] $($pkg.Name) installed." -ForegroundColor Green
    }

    # Initialize folders
    $dirs = @("$StoragePath\media\movies", "$StoragePath\media\tv", "$StoragePath\downloads")
    foreach ($d in $dirs) {
        if (-not (Test-Path $d)) {
            New-Item -ItemType Directory -Path $d -Force | Out-Null
        }
    }
}

# Create Quick Launch Shortcuts on Desktop
$wsh = New-Object -ComObject WScript.Shell
$desktop = [Environment]::GetFolderPath("Desktop")
$shortcut = $wsh.CreateShortcut("$desktop\ArrStack Dashboard.url")
$shortcut.TargetPath = "https://arrstack.ertechlab.com"
$shortcut.Save()

Write-Host @"

=============================================================================
  ✓ ArrStack Deployment Completed Successfully!
=============================================================================
Access your unified media suite in your browser:

  🎬 Plex Media Server: http://localhost:32400/web
  📽️ Radarr (Movies):    http://localhost:7878
  📺 Sonarr (TV Shows):  http://localhost:8989
  🔍 Prowlarr (Indexers):http://localhost:9696
  ⚡ qBittorrent:        http://localhost:8080 (User: admin / Pass: adminadmin)
  🍿 Jellyseerr Requests:http://localhost:5055

Storage Root: $StoragePath
=============================================================================
"@ -ForegroundColor Green
