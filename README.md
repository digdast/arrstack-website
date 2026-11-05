# ⚡ ARRSTACK // One-Shot Media Suite Automation

```text
  ██████╗ ██████╗ ██████╗ ███████╗████████╗ █████╗  ██████╗██╗  ██╗
 ██╔══██╗██╔══██╗██╔══██╗██╔════╝╚══██╔══╝██╔══██╗██╔════╝██║ ██╔╝
 ███████║██████╔╝██████╔╝███████╗   ██║   ███████║██║     █████╔╝ 
 ██╔══██║██╔══██╗██╔══██╗╚════██║   ██║   ██╔══██║██║     ██╔═██╗ 
 ██║  ██║██║  ██║██║  ██║███████║   ██║   ██║  ██║╚██████╗██║  ██╗
 ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝
```

> **[OFFICIAL PRODUCTION REPOSITORY]**  
> *The ultimate automated media deployment framework. One-shot cross-platform installer for Plex Media Server, Sonarr, Radarr, Prowlarr, qBittorrent, FlareSolverr, and Jellyseerr.*  
> Engineered by **Efrain Rivas** — Senior Enterprise Infrastructure Architect.  
> Production Portal: **[arrstack.ertechlab.com](https://arrstack.ertechlab.com)**

---

## ⚡ Live Telemetry & Badges

[![Production Site](https://img.shields.io/badge/Production-arrstack.ertechlab.com-06b6d4?style=for-the-badge&logo=google-chrome&logoColor=white)](https://arrstack.ertechlab.com)
[![Status](https://img.shields.io/badge/Status-100%25%20Operational-34d399?style=for-the-badge&logo=statuspage&logoColor=white)](https://arrstack.ertechlab.com)
[![Cloudflare Tunnel](https://img.shields.io/badge/Edge-Cloudflare%20Argo%20Tunnel-f38020?style=for-the-badge&logo=cloudflare&logoColor=white)](https://dash.cloudflare.com)
[![Kubernetes](https://img.shields.io/badge/Orchestrator-K3s%20Cluster%20(NodePort%2030093)-326ce5?style=for-the-badge&logo=kubernetes&logoColor=white)](https://k3s.io)
[![Security Hardened](https://img.shields.io/badge/Security-CSP%20%2B%20OWASP%20Shielded-emerald?style=for-the-badge&logo=shield&logoColor=white)](https://arrstack.ertechlab.com)
[![Google AdSense](https://img.shields.io/badge/Monetization-Google%20AdSense%20Verified-4285f4?style=for-the-badge&logo=google-ads&logoColor=white)](https://arrstack.ertechlab.com/ads.txt)
[![Cross-Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20Windows%20%7C%20macOS-blueviolet?style=for-the-badge&logo=linux&logoColor=white)](https://arrstack.ertechlab.com)

---

## 🚀 Instant Deployment (One-Liner)

### 1. Linux & macOS (Universal Bash)
```bash
curl -fsSL https://arrstack.ertechlab.com/install.sh | bash
```

*Options:*
```bash
# Non-interactive silent installation
curl -fsSL https://arrstack.ertechlab.com/install.sh | bash -s -- --silent

# Custom storage directory (default: /data)
curl -fsSL https://arrstack.ertechlab.com/install.sh | bash -s -- --storage /mnt/storage

# Direct native host OS packages (Debian/Ubuntu/macOS)
curl -fsSL https://arrstack.ertechlab.com/install.sh | bash -s -- --native
```

### 2. Windows 10 / 11 / Server (PowerShell)
Open PowerShell as Administrator and run:
```powershell
irm https://arrstack.ertechlab.com/install.ps1 | iex
```

### 3. Docker Compose (Direct Manifest)
```bash
curl -fsSL https://arrstack.ertechlab.com/docker-compose.yml -o docker-compose.yml && docker compose up -d
```

### 4. Standalone Windows Desktop Installers
- **Graphical Wizard**: [ArrStack-Installer.exe](https://arrstack.ertechlab.com/downloads/ArrStack-Installer.exe)
- **Enterprise Package**: [ArrStack-Setup.msi](https://arrstack.ertechlab.com/downloads/ArrStack-Setup.msi)

---

## 🧭 Ecosystem & Default Port Topology

| Service | Port | Default URL | Purpose |
| :--- | :--- | :--- | :--- |
| **Plex Media Server** | `32400` | [http://localhost:32400/web](http://localhost:32400/web) | Universal 4K HDR media streaming and hardware transcoding |
| **Radarr** | `7878` | [http://localhost:7878](http://localhost:7878) | Automated movie monitoring, quality profile upgrades & naming |
| **Sonarr** | `8989` | [http://localhost:8989](http://localhost:8989) | Automated TV series episode tracking and season renaming |
| **Prowlarr** | `9696` | [http://localhost:9696](http://localhost:9696) | Centralized BitTorrent & Usenet indexer proxy synchronizer |
| **qBittorrent** | `8080` | [http://localhost:8080](http://localhost:8080) | Headless BitTorrent download daemon (Default User: `admin` / `adminadmin`) |
| **FlareSolverr** | `8191` | [http://localhost:8191](http://localhost:8191) | Cloudflare anti-bot challenge solver for private trackers |
| **Jellyseerr** | `5055` | [http://localhost:5055](http://localhost:5055) | 1-Click user discovery and movie/show requests portal |

---

## 🏗️ High-Availability Edge Mesh Architecture

```mermaid
flowchart TD
    subgraph WAN ["🌐 Global Web Traffic"]
        Client["Users & Homelab Engineers"]
        Bot["Search Engines & Google AdSense Crawlers"]
    end

    subgraph Cloudflare ["☁️ Cloudflare Global Anycast Edge (arrstack.ertechlab.com)"]
        CF_DNS["Cloudflare DNS (Proxied CNAME: 2f5e2042...cfargotunnel.com)"]
        CF_DDoS["DDoS Scrubbing & Anycast CDN Caching"]
        CF_TLS["Universal SSL (Full Strict / TLS 1.3)"]
        CF_WAF["WAF & Bot Management Shield"]
    end

    subgraph K3sCluster ["🏢 ERTechLab Kubernetes Cluster (192.168.0.80)"]
        CF_Argo["cloudflared Daemon (Argo HTTP/2 Multiplexed Tunnel)"]
        NPM["Nginx Proxy Manager (OpenResty, block_exploits = True)"]
        
        subgraph ToolsNamespace ["Namespace: tools"]
            ArrWeb["arrstack-website Pod (Python 3.11-alpine)"]
            ArrSvc["arrstack-website-svc (NodePort: 30093)"]
        end
    end

    subgraph GeneratedMediaStack ["🚀 User Machine (Target Deployment)"]
        Plex["Plex Media Server (:32400)"]
        Radarr["Radarr (:7878)"]
        Sonarr["Sonarr (:8989)"]
        Prowlarr["Prowlarr (:9696)"]
        qBit["qBittorrent (:8080)"]
        Flare["FlareSolverr (:8191)"]
        Jelly["Jellyseerr (:5055)"]
    end

    Client --> CF_DNS
    Bot --> CF_DNS
    CF_DNS --> CF_DDoS --> CF_TLS --> CF_WAF
    CF_WAF --> CF_Argo --> NPM --> ArrSvc --> ArrWeb
    ArrWeb -.->|"One-Shot curl / irm"| GeneratedMediaStack
    GeneratedMediaStack --> Plex & Radarr & Sonarr & Prowlarr & qBit & Flare & Jelly
```

---

## 🛡️ Security Hardening & OWASP Compliance

- **HTTP Response Security Headers**:
  - `X-Content-Type-Options: nosniff` (mitigates MIME-sniffing drive-by downloads)
  - `X-Frame-Options: SAMEORIGIN` (prevents clickjacking attacks)
  - `X-XSS-Protection: 1; mode=block` (browser-level XSS filtering)
  - `Referrer-Policy: strict-origin-when-cross-origin` (prevents referrer leak)
  - `Permissions-Policy: camera=(), microphone=(), geolocation=()` (disables hardware device hijacking)
- **Content-Security-Policy (CSP)**:
  - Whitelists verified Google AdSense domains (`pagead2.googlesyndication.com`, `googleads.g.doubleclick.net`, `tpc.googlesyndication.com`), official CDNs (`tailwindcss.com`, `unpkg.com`), and self while blocking unauthorized external script injections.
- **Nginx Ingress Hardening**:
  - `block_exploits = true` active in Nginx Proxy Manager, filtering SQL injections (`UNION SELECT`), directory traversal (`/..`), and automated malicious User-Agents.
- **Origin Concealment**:
  - 100% cloaked behind Cloudflare Argo Tunnel with zero required WAN router port forwards.

---

## 📂 Repository Topology

```text
arrstack-website/
├── index.html                  # Production web app with interactive configurator
├── app.py                      # Multi-threaded Python HTTP delivery engine
├── install.sh                  # Universal cross-platform Bash one-shot installer
├── install.ps1                 # Universal Windows PowerShell one-shot installer
├── docker-compose.yml          # Production reference Docker Compose manifest
├── k3s-arrstack-website.yaml   # Kubernetes K3s deployment and service definition
├── ArrStackInstaller.cs        # Native C# .NET Windows GUI installer source code
├── ads.txt                     # Google AdSense authorized seller record
├── robots.txt                  # Universal web crawler policy
├── sitemap.xml                 # Canonical XML search engine sitemap
├── static/
│   ├── arrstack-logo.svg       # Vector primary brand asset
│   └── favicon.svg             # Application favicon
└── downloads/
    ├── ArrStack-Installer.exe  # Standalone Windows Graphical Installer (.EXE)
    ├── ArrStack-Setup.msi      # Standalone Windows Installer Package (.MSI)
    ├── install.sh              # Direct shell script mirror
    ├── install.ps1             # Direct PowerShell script mirror
    └── docker-compose.yml      # Direct Compose manifest mirror
```

---

## ⚖️ License & Attribution

Designed and maintained by **Efrain Rivas** ([@digdast](https://github.com/digdast)).  
All rights reserved &copy; 2026 **ERTechLab Sovereign Infrastructure**.
