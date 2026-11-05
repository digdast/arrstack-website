#!/usr/bin/env bash
# ==============================================================================
#  ArrStack Universal One-Shot Installer // ERTechLab
#  Installs Plex, Radarr, Sonarr, Prowlarr, qBittorrent & Jellyseerr
#  Cross-platform support: Debian, Ubuntu, Fedora, RHEL, Arch Linux, Alpine, macOS
#  Web: https://arrstack.ertechlab.com
# ==============================================================================

set -euo pipefail

# ANSI Colors
CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
PURPLE='\033[1;35m'
BLUE='\033[1;34m'
GRAY='\033[0;37m'
NC='\033[0m'

# Default Configuration
INSTALL_MODE="docker"
STORAGE_DIR="/data"
CONFIG_DIR="/opt/arrstack"
ENABLE_GPU=true
SILENT=false

# Print Banner
echo -e "${CYAN}"
cat << 'EOF'
  ██████╗ ██████╗ ██████╗ ███████╗████████╗ █████╗  ██████╗██╗  ██╗
 ██╔══██╗██╔══██╗██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██╔════╝██║ ██╔╝
 ███████║██████╔╝██████╔╝███████╗   ██║   ███████║██║     █████╔╝ 
 ██╔══██║██╔══██╗██╔══██╗╚════██║   ██║   ██╔══██║██║     ██╔═██╗ 
 ██║  ██║██║  ██║██║  ██║███████║   ██║   ██║  ██║╚██████╗██║  ██╗
 ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝
EOF
echo -e "${NC}"
echo -e "${GRAY}─────────────────────────────────────────────────────────────────────────────${NC}"
echo -e "${GREEN}  ArrStack One-Shot Deployment Engine // ERTechLab Sovereign Mesh${NC}"
echo -e "${GRAY}  Plex • Radarr • Sonarr • Prowlarr • qBittorrent • FlareSolverr • Jellyseerr${NC}"
echo -e "${GRAY}─────────────────────────────────────────────────────────────────────────────${NC}\n"

# Parse Command-Line Arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --docker)
      INSTALL_MODE="docker"
      shift
      ;;
    --native)
      INSTALL_MODE="native"
      shift
      ;;
    --storage)
      STORAGE_DIR="$2"
      shift 2
      ;;
    --config)
      CONFIG_DIR="$2"
      shift 2
      ;;
    --no-gpu)
      ENABLE_GPU=false
      shift
      ;;
    --silent|-y)
      SILENT=true
      shift
      ;;
    -h|--help)
      echo "Usage: curl -fsSL https://arrstack.ertechlab.com/install.sh | bash [options]"
      echo ""
      echo "Options:"
      echo "  --docker          Install using Docker Compose (Recommended, clean & isolated)"
      echo "  --native          Install packages directly on host OS (Debian/Ubuntu/macOS)"
      echo "  --storage <path>  Target media storage directory (Default: /data)"
      echo "  --config <path>   Configuration base directory (Default: /opt/arrstack)"
      echo "  --no-gpu          Disable GPU hardware transcoding passthrough"
      echo "  --silent, -y      Non-interactive unattended deployment"
      exit 0
      ;;
    *)
      shift
      ;;
  esac
done

# Detect OS
OS_NAME="$(uname -s)"
DISTRO=""
if [[ "$OS_NAME" == "Linux" ]]; then
  if [[ -f /etc/os-release ]]; then
    # shellcheck source=/dev/null
    . /etc/os-release
    DISTRO="$ID"
  fi
elif [[ "$OS_NAME" == "Darwin" ]]; then
  DISTRO="macos"
fi

echo -e "[*] Detected Platform: ${BLUE}${OS_NAME} (${DISTRO:-generic})${NC}"

# Check for root/sudo
IS_ROOT=false
if [[ $EUID -eq 0 ]]; then
  IS_ROOT=true
fi

SUDO=""
if [[ "$IS_ROOT" == "false" ]]; then
  if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  else
    echo -e "${RED}[!] sudo is required to install system services. Run as root or install sudo.${NC}"
    exit 1
  fi
fi

# Interactive Prompt if not silent
if [[ "$SILENT" == "false" && -t 0 ]]; then
  echo -e "${YELLOW}[?] Select Deployment Mode:${NC}"
  echo -e "  1) Docker Container Stack (Recommended - zero host clutter, instant updates)"
  echo -e "  2) Native Host OS Packages (Direct system binaries)"
  read -rp "Enter choice [1/2, default 1]: " choice
  if [[ "$choice" == "2" ]]; then
    INSTALL_MODE="native"
  else
    INSTALL_MODE="docker"
  fi

  echo -e "\n${YELLOW}[?] Target Media Storage Directory [Default: ${STORAGE_DIR}]:${NC}"
  read -rp "Path: " custom_storage
  if [[ -n "$custom_storage" ]]; then
    STORAGE_DIR="$custom_storage"
  fi
fi

echo -e "\n[*] Deployment Mode: ${GREEN}${INSTALL_MODE^^}${NC}"
echo -e "[*] Storage Path:    ${CYAN}${STORAGE_DIR}${NC}"
echo -e "[*] Config Path:     ${CYAN}${CONFIG_DIR}${NC}\n"

# ------------------------------------------------------------------------------
# DOCKER DEPLOYMENT MODE
# ------------------------------------------------------------------------------
if [[ "$INSTALL_MODE" == "docker" ]]; then
  echo -e "${CYAN}=== STEP 1: Verifying & Installing Docker Prerequisites ===${NC}"
  
  if ! command -v docker >/dev/null 2>&1; then
    echo -e "[*] Docker not found. Installing official Docker Engine..."
    if [[ "$DISTRO" == "macos" ]]; then
      if command -v brew >/dev/null 2>&1; then
        brew install --cask docker
        open /Applications/Docker.app || true
      else
        echo -e "${RED}[!] Please install Homebrew or Docker Desktop for Mac.${NC}"
        exit 1
      fi
    elif [[ "$DISTRO" =~ ^(ubuntu|debian|raspbian)$ ]]; then
      $SUDO apt-get update -qq
      $SUDO apt-get install -y -qq curl ca-certificates gnupg
      curl -fsSL https://get.docker.com | $SUDO sh
    elif [[ "$DISTRO" =~ ^(fedora|centos|rhel|rocky|almalinux)$ ]]; then
      curl -fsSL https://get.docker.com | $SUDO sh
      $SUDO systemctl enable --now docker
    elif [[ "$DISTRO" == "arch" ]]; then
      $SUDO pacman -Sy --noconfirm docker docker-compose
      $SUDO systemctl enable --now docker
    elif [[ "$DISTRO" == "alpine" ]]; then
      $SUDO apk add --no-cache docker docker-compose
      $SUDO rc-update add docker boot
      $SUDO service docker start
    else
      curl -fsSL https://get.docker.com | $SUDO sh
    fi
  else
    echo -e "[✓] Docker is already installed: $(docker --version)"
  fi

  # Enable and start Docker service on Linux
  if [[ "$OS_NAME" == "Linux" ]] && command -v systemctl >/dev/null 2>&1; then
    $SUDO systemctl enable --now docker >/dev/null 2>&1 || true
    # Add non-root user to docker group if applicable
    if [[ "$IS_ROOT" == "false" ]]; then
      $SUDO usermod -aG docker "$USER" 2>/dev/null || true
    fi
  fi

  # Verify Docker Compose
  COMPOSE_CMD=""
  if docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
  elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
  else
    echo -e "[*] Installing docker-compose-plugin..."
    if [[ "$DISTRO" =~ ^(ubuntu|debian)$ ]]; then
      $SUDO apt-get update -qq && $SUDO apt-get install -y -qq docker-compose-plugin
      COMPOSE_CMD="docker compose"
    else
      DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
      mkdir -p "$DOCKER_CONFIG/cli-plugins"
      curl -sSL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o "$DOCKER_CONFIG/cli-plugins/docker-compose"
      chmod +x "$DOCKER_CONFIG/cli-plugins/docker-compose"
      COMPOSE_CMD="docker compose"
    fi
  fi

  echo -e "[✓] Using Compose engine: ${GREEN}${COMPOSE_CMD}${NC}"

  # STEP 2: Create Directory Structures
  echo -e "\n${CYAN}=== STEP 2: Setting up Media & Configuration Directories ===${NC}"
  $SUDO mkdir -p "${STORAGE_DIR}/media/movies"
  $SUDO mkdir -p "${STORAGE_DIR}/media/tv"
  $SUDO mkdir -p "${STORAGE_DIR}/downloads/torrents"
  $SUDO mkdir -p "${STORAGE_DIR}/downloads/usenet"

  $SUDO mkdir -p "${CONFIG_DIR}/config/plex"
  $SUDO mkdir -p "${CONFIG_DIR}/config/radarr"
  $SUDO mkdir -p "${CONFIG_DIR}/config/sonarr"
  $SUDO mkdir -p "${CONFIG_DIR}/config/prowlarr"
  $SUDO mkdir -p "${CONFIG_DIR}/config/qbittorrent"
  $SUDO mkdir -p "${CONFIG_DIR}/config/jellyseerr"

  # Permissions (Standard 1000:1000 or current user)
  USER_ID=$(id -u)
  GROUP_ID=$(id -g)
  if [[ "$IS_ROOT" == "true" ]]; then
    USER_ID=1000
    GROUP_ID=1000
  fi

  $SUDO chown -R "${USER_ID}:${GROUP_ID}" "${STORAGE_DIR}" 2>/dev/null || true
  $SUDO chown -R "${USER_ID}:${GROUP_ID}" "${CONFIG_DIR}" 2>/dev/null || true
  $SUDO chmod -R 775 "${STORAGE_DIR}" 2>/dev/null || true

  echo -e "[✓] Directories initialized under ${STORAGE_DIR} & ${CONFIG_DIR}"

  # STEP 3: Detect GPU Acceleration
  GPU_DEVICE_SNIPPET=""
  if [[ "$ENABLE_GPU" == "true" && -d "/dev/dri" ]]; then
    echo -e "[✓] Intel / AMD QuickSync GPU hardware found at /dev/dri. Transcoding passthrough enabled!"
    GPU_DEVICE_SNIPPET="    devices:
      - /dev/dri:/dev/dri"
  fi

  # STEP 4: Generate docker-compose.yml
  echo -e "\n${CYAN}=== STEP 3: Generating Production docker-compose.yml ===${NC}"
  
  $SUDO tee "${CONFIG_DIR}/docker-compose.yml" > /dev/null << EOF
version: "3.8"

services:
  plex:
    image: lscr.io/linuxserver/plex:latest
    container_name: arrstack-plex
    network_mode: host
    environment:
      - PUID=${USER_ID}
      - PGID=${GROUP_ID}
      - TZ=Etc/UTC
      - VERSION=docker
    volumes:
      - ${CONFIG_DIR}/config/plex:/config
      - ${STORAGE_DIR}/media/tv:/tv:ro
      - ${STORAGE_DIR}/media/movies:/movies:ro
${GPU_DEVICE_SNIPPET}
    restart: unless-stopped

  radarr:
    image: lscr.io/linuxserver/radarr:latest
    container_name: arrstack-radarr
    environment:
      - PUID=${USER_ID}
      - PGID=${GROUP_ID}
      - TZ=Etc/UTC
    volumes:
      - ${CONFIG_DIR}/config/radarr:/config
      - ${STORAGE_DIR}/media/movies:/movies
      - ${STORAGE_DIR}/downloads:/downloads
    ports:
      - 7878:7878
    restart: unless-stopped

  sonarr:
    image: lscr.io/linuxserver/sonarr:latest
    container_name: arrstack-sonarr
    environment:
      - PUID=${USER_ID}
      - PGID=${GROUP_ID}
      - TZ=Etc/UTC
    volumes:
      - ${CONFIG_DIR}/config/sonarr:/config
      - ${STORAGE_DIR}/media/tv:/tv
      - ${STORAGE_DIR}/downloads:/downloads
    ports:
      - 8989:8989
    restart: unless-stopped

  prowlarr:
    image: lscr.io/linuxserver/prowlarr:latest
    container_name: arrstack-prowlarr
    environment:
      - PUID=${USER_ID}
      - PGID=${GROUP_ID}
      - TZ=Etc/UTC
    volumes:
      - ${CONFIG_DIR}/config/prowlarr:/config
    ports:
      - 9696:9696
    restart: unless-stopped

  qbittorrent:
    image: lscr.io/linuxserver/qbittorrent:latest
    container_name: arrstack-qbittorrent
    environment:
      - PUID=${USER_ID}
      - PGID=${GROUP_ID}
      - TZ=Etc/UTC
      - WEBUI_PORT=8080
      - TORRENTING_PORT=6881
    volumes:
      - ${CONFIG_DIR}/config/qbittorrent:/config
      - ${STORAGE_DIR}/downloads:/downloads
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
      - ${CONFIG_DIR}/config/jellyseerr:/app/config
    ports:
      - 5055:5055
    restart: unless-stopped
EOF

  echo -e "[✓] Created ${CONFIG_DIR}/docker-compose.yml"

  # STEP 5: Launch Stack
  echo -e "\n${CYAN}=== STEP 4: Pulling Images & Starting ArrStack ===${NC}"
  cd "${CONFIG_DIR}"
  $SUDO $COMPOSE_CMD pull -q
  $SUDO $COMPOSE_CMD up -d

  # STEP 6: Optional systemd service for Linux
  if [[ "$OS_NAME" == "Linux" ]] && command -v systemctl >/dev/null 2>&1; then
    $SUDO tee /etc/systemd/system/arrstack.service > /dev/null << EOF
[Unit]
Description=ArrStack One-Shot Media Ecosystem
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=${CONFIG_DIR}
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF
    $SUDO systemctl daemon-reload
    $SUDO systemctl enable arrstack.service >/dev/null 2>&1 || true
    echo -e "[✓] Systemd unit 'arrstack.service' registered for automatic system boot."
  fi

# ------------------------------------------------------------------------------
# NATIVE DEPLOYMENT MODE
# ------------------------------------------------------------------------------
elif [[ "$INSTALL_MODE" == "native" ]]; then
  echo -e "${CYAN}=== STEP 1: Installing Native Host Packages ===${NC}"

  if [[ "$DISTRO" =~ ^(ubuntu|debian)$ ]]; then
    $SUDO apt-get update -qq
    $SUDO apt-get install -y -qq curl gpg lsb-release sqlite3 libicu-dev qbittorrent-nox

    # Plex Repository
    echo -e "[*] Adding Plex Official Repository..."
    curl -fsSL https://downloads.plex.tv/plex-keys/PlexSign.key | $SUDO gpg --dearmor -o /usr/share/keyrings/plex-archive-keyring.gpg --yes
    echo "deb [signed-by=/usr/share/keyrings/plex-archive-keyring.gpg] https://downloads.plex.tv/repo/deb public main" | $SUDO tee /etc/apt/sources.list.d/plexmediaserver.list >/dev/null
    $SUDO apt-get update -qq
    $SUDO apt-get install -y -qq plexmediaserver

    # Sonarr v4 (Official deb)
    echo -e "[*] Installing Sonarr..."
    $SUDO apt-get install -y -qq libsqlite3-0
    mkdir -p /tmp/sonarr-install
    curl -fsSL "https://services.sonarr.tv/v1/download/main/latest?version=4&os=linux&arch=x64" -o /tmp/sonarr-install/sonarr.tar.gz
    $SUDO tar -xzf /tmp/sonarr-install/sonarr.tar.gz -C /opt/
    rm -rf /tmp/sonarr-install

    # Radarr
    echo -e "[*] Installing Radarr..."
    mkdir -p /tmp/radarr-install
    curl -fsSL "https://radarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore&arch=x64" -o /tmp/radarr-install/radarr.tar.gz
    $SUDO tar -xzf /tmp/radarr-install/radarr.tar.gz -C /opt/
    rm -rf /tmp/radarr-install

    # Prowlarr
    echo -e "[*] Installing Prowlarr..."
    mkdir -p /tmp/prowlarr-install
    curl -fsSL "https://prowlarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore&arch=x64" -o /tmp/prowlarr-install/prowlarr.tar.gz
    $SUDO tar -xzf /tmp/prowlarr-install/prowlarr.tar.gz -C /opt/
    rm -rf /tmp/prowlarr-install

    # Create directories
    $SUDO mkdir -p "${STORAGE_DIR}/media/movies" "${STORAGE_DIR}/media/tv" "${STORAGE_DIR}/downloads"
    $SUDO chown -R 1000:1000 "${STORAGE_DIR}" 2>/dev/null || true

  elif [[ "$DISTRO" == "macos" ]]; then
    if command -v brew >/dev/null 2>&1; then
      echo -e "[*] Installing via Homebrew Casks..."
      brew install --cask plex-media-server sonarr radarr prowlarr qbittorrent
    else
      echo -e "${RED}[!] Homebrew is required for native macOS install. Run: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"${NC}"
      exit 1
    fi
  else
    echo -e "${YELLOW}[!] Direct native packages are optimal on Debian/Ubuntu/macOS. For ${DISTRO}, Docker mode is strongly recommended.${NC}"
    echo -e "[*] Falling back to Docker mode..."
    exec "$0" --docker --storage "$STORAGE_DIR" --silent
  fi
fi

# Detect Host IP
HOST_IP="localhost"
if command -v hostname >/dev/null 2>&1; then
  HOST_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "localhost")
fi

# Print Success Telemetry Dashboard
echo -e "\n${GREEN}=============================================================================${NC}"
echo -e "${GREEN}  ✓ ArrStack Deployment Completed Successfully!${NC}"
echo -e "${GREEN}=============================================================================${NC}"
echo -e "${CYAN}Access your unified media suite in any web browser:${NC}\n"
echo -e "  🎬 ${YELLOW}Plex Media Server:${NC} http://${HOST_IP}:32400/web"
echo -e "  📽️  ${YELLOW}Radarr (Movies):${NC}    http://${HOST_IP}:7878"
echo -e "  📺 ${YELLOW}Sonarr (TV Shows):${NC}  http://${HOST_IP}:8989"
echo -e "  🔍 ${YELLOW}Prowlarr (Indexers):${NC} http://${HOST_IP}:9696"
echo -e "  ⚡ ${YELLOW}qBittorrent WebUI:${NC}  http://${HOST_IP}:8080  (User: admin / Pass: check terminal logs or adminadmin)"
echo -e "  🛡️  ${YELLOW}FlareSolverr:${NC}        http://${HOST_IP}:8191"
echo -e "  🍿 ${YELLOW}Jellyseerr Requests:${NC} http://${HOST_IP}:5055\n"
echo -e "${GRAY}Storage Path: ${STORAGE_DIR}/media & ${STORAGE_DIR}/downloads${NC}"
echo -e "${GRAY}Config Path:  ${CONFIG_DIR}/config${NC}"
echo -e "${GREEN}=============================================================================${NC}\n"
EOF
