using System;
using System.IO;
using System.Diagnostics;
using System.Drawing;
using System.Windows.Forms;
using System.Threading;

namespace ERTechLab.ArrStack
{
    public class InstallerForm : Form
    {
        private RadioButton rbDocker;
        private RadioButton rbNative;
        private TextBox txtPath;
        private Button btnBrowse;
        private Button btnInstall;
        private ProgressBar progressBar;
        private TextBox txtLog;
        private Label lblStatus;

        public InstallerForm()
        {
            this.Text = "ArrStack // One-Shot Media Suite Installer (ERTechLab)";
            this.Size = new Size(620, 560);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.BackColor = Color.FromArgb(11, 15, 25);
            this.ForeColor = Color.White;
            this.Font = new Font("Segoe UI", 9.5f, FontStyle.Regular);

            // Header Banner
            Panel pnlHeader = new Panel
            {
                Dock = DockStyle.Top,
                Height = 80,
                BackColor = Color.FromArgb(17, 24, 39)
            };
            Label lblTitle = new Label
            {
                Text = "⚡ ArrStack Media Automation Suite",
                Font = new Font("Segoe UI", 14f, FontStyle.Bold),
                ForeColor = Color.FromArgb(6, 182, 212),
                Location = new Point(20, 15),
                AutoSize = true
            };
            Label lblSubtitle = new Label
            {
                Text = "Plex • Radarr • Sonarr • Prowlarr • qBittorrent • Jellyseerr",
                Font = new Font("Segoe UI", 9.5f, FontStyle.Regular),
                ForeColor = Color.FromArgb(156, 163, 175),
                Location = new Point(22, 45),
                AutoSize = true
            };
            pnlHeader.Controls.Add(lblTitle);
            pnlHeader.Controls.Add(lblSubtitle);
            this.Controls.Add(pnlHeader);

            // Group Box: Mode
            GroupBox gbMode = new GroupBox
            {
                Text = " Deployment Architecture ",
                ForeColor = Color.FromArgb(6, 182, 212),
                Location = new Point(25, 95),
                Size = new Size(555, 80)
            };
            rbDocker = new RadioButton
            {
                Text = "🚀 Docker Container Stack (Recommended - Clean, isolated, automated updates)",
                Checked = true,
                Location = new Point(20, 25),
                Size = new Size(520, 22),
                ForeColor = Color.White
            };
            rbNative = new RadioButton
            {
                Text = "💻 Native Windows Packages (Direct desktop applications via Winget)",
                Location = new Point(20, 50),
                Size = new Size(520, 22),
                ForeColor = Color.White
            };
            gbMode.Controls.Add(rbDocker);
            gbMode.Controls.Add(rbNative);
            this.Controls.Add(gbMode);

            // Group Box: Storage
            GroupBox gbStorage = new GroupBox
            {
                Text = " Target Storage Directory ",
                ForeColor = Color.FromArgb(6, 182, 212),
                Location = new Point(25, 185),
                Size = new Size(555, 70)
            };
            txtPath = new TextBox
            {
                Text = @"C:\ArrStack",
                Location = new Point(20, 28),
                Size = new Size(420, 25),
                BackColor = Color.FromArgb(31, 41, 55),
                ForeColor = Color.FromArgb(52, 211, 153),
                BorderStyle = BorderStyle.FixedSingle
            };
            btnBrowse = new Button
            {
                Text = "Browse...",
                Location = new Point(450, 26),
                Size = new Size(85, 27),
                BackColor = Color.FromArgb(55, 65, 81),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat
            };
            btnBrowse.Click += (s, e) => {
                using (FolderBrowserDialog fbd = new FolderBrowserDialog())
                {
                    if (fbd.ShowDialog() == DialogResult.OK)
                    {
                        txtPath.Text = fbd.SelectedPath;
                    }
                }
            };
            gbStorage.Controls.Add(txtPath);
            gbStorage.Controls.Add(btnBrowse);
            this.Controls.Add(gbStorage);

            // Install Button
            btnInstall = new Button
            {
                Text = "⚡ Install & Deploy ArrStack Now",
                Location = new Point(25, 268),
                Size = new Size(555, 42),
                BackColor = Color.FromArgb(14, 165, 233),
                ForeColor = Color.White,
                Font = new Font("Segoe UI", 11f, FontStyle.Bold),
                FlatStyle = FlatStyle.Flat,
                Cursor = Cursors.Hand
            };
            btnInstall.Click += StartInstallation;
            this.Controls.Add(btnInstall);

            // Progress Bar
            progressBar = new ProgressBar
            {
                Location = new Point(25, 320),
                Size = new Size(555, 12),
                Style = ProgressBarStyle.Continuous
            };
            this.Controls.Add(progressBar);

            // Status Label
            lblStatus = new Label
            {
                Text = "Ready to deploy.",
                Location = new Point(25, 338),
                Size = new Size(555, 20),
                ForeColor = Color.FromArgb(156, 163, 175)
            };
            this.Controls.Add(lblStatus);

            // Terminal Log Box
            txtLog = new TextBox
            {
                Location = new Point(25, 362),
                Size = new Size(555, 140),
                Multiline = true,
                ReadOnly = true,
                ScrollBars = ScrollBars.Vertical,
                BackColor = Color.FromArgb(3, 7, 18),
                ForeColor = Color.FromArgb(74, 222, 128),
                Font = new Font("Consolas", 8.5f),
                BorderStyle = BorderStyle.FixedSingle
            };
            this.Controls.Add(txtLog);
        }

        private void Log(string msg)
        {
            if (txtLog.InvokeRequired)
            {
                txtLog.Invoke(new Action<string>(Log), msg);
                return;
            }
            txtLog.AppendText("[" + DateTime.Now.ToString("HH:mm:ss") + "] " + msg + Environment.NewLine);
        }

        private void SetStatus(string msg, int progress)
        {
            if (lblStatus.InvokeRequired)
            {
                lblStatus.Invoke(new Action<string, int>(SetStatus), msg, progress);
                return;
            }
            lblStatus.Text = msg;
            progressBar.Value = Math.Min(100, Math.Max(0, progress));
        }

        private void StartInstallation(object sender, EventArgs e)
        {
            btnInstall.Enabled = false;
            btnBrowse.Enabled = false;
            txtPath.Enabled = false;
            rbDocker.Enabled = false;
            rbNative.Enabled = false;

            string targetPath = txtPath.Text.Trim();
            bool isDocker = rbDocker.Checked;

            Thread worker = new Thread(() => RunInstall(targetPath, isDocker));
            worker.IsBackground = true;
            worker.Start();
        }

        private void RunInstall(string storagePath, bool isDocker)
        {
            try
            {
                SetStatus("Creating storage and configuration directories...", 15);
                Log("Target Path: " + storagePath);

                string[] subDirs = new string[] {
                    Path.Combine(storagePath, @"media\movies"),
                    Path.Combine(storagePath, @"media\tv"),
                    Path.Combine(storagePath, @"downloads\torrents"),
                    Path.Combine(storagePath, @"config\plex"),
                    Path.Combine(storagePath, @"config\radarr"),
                    Path.Combine(storagePath, @"config\sonarr"),
                    Path.Combine(storagePath, @"config\prowlarr"),
                    Path.Combine(storagePath, @"config\qbittorrent"),
                    Path.Combine(storagePath, @"config\jellyseerr")
                };

                foreach (string d in subDirs)
                {
                    if (!Directory.Exists(d))
                    {
                        Directory.CreateDirectory(d);
                    }
                }
                Log("Initialized folder hierarchy.");

                if (isDocker)
                {
                    SetStatus("Writing docker-compose.yml specification...", 35);
                    string composePath = Path.Combine(storagePath, "docker-compose.yml");
                    string compose = @"version: '3.8'
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
      - ./config/plex:/config
      - ./media/tv:/tv
      - ./media/movies:/movies
    ports:
      - '32400:32400'
    restart: unless-stopped

  radarr:
    image: lscr.io/linuxserver/radarr:latest
    container_name: arrstack-radarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - ./config/radarr:/config
      - ./media/movies:/movies
      - ./downloads:/downloads
    ports:
      - '7878:7878'
    restart: unless-stopped

  sonarr:
    image: lscr.io/linuxserver/sonarr:latest
    container_name: arrstack-sonarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - ./config/sonarr:/config
      - ./media/tv:/tv
      - ./downloads:/downloads
    ports:
      - '8989:8989'
    restart: unless-stopped

  prowlarr:
    image: lscr.io/linuxserver/prowlarr:latest
    container_name: arrstack-prowlarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - ./config/prowlarr:/config
    ports:
      - '9696:9696'
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
      - ./config/qbittorrent:/config
      - ./downloads:/downloads
    ports:
      - '8080:8080'
      - '6881:6881'
      - '6881:6881/udp'
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
      - '8191:8191'
    restart: unless-stopped

  jellyseerr:
    image: fallenbagel/jellyseerr:latest
    container_name: arrstack-jellyseerr
    environment:
      - LOG_LEVEL=debug
      - TZ=Etc/UTC
    volumes:
      - ./config/jellyseerr:/app/config
    ports:
      - '5055:5055'
    restart: unless-stopped
";
                    File.WriteAllText(composePath, compose);
                    Log("Created docker-compose.yml.");

                    SetStatus("Starting Docker Compose media services...", 70);
                    RunCmd("docker", "compose up -d", storagePath);
                }
                else
                {
                    SetStatus("Installing native packages via Windows Package Manager...", 40);
                    string[] pkgs = new string[] {
                        "Plex.PlexMediaServer",
                        "TeamSonarr.Sonarr",
                        "Radarr.Radarr",
                        "Prowlarr.Prowlarr",
                        "qBittorrent.qBittorrent"
                    };

                    int p = 40;
                    foreach (string pkg in pkgs)
                    {
                        Log("Installing " + pkg + "...");
                        RunCmd("winget", "install --id " + pkg + " -e --silent --accept-package-agreements --accept-source-agreements", storagePath);
                        p += 10;
                        SetStatus("Installed " + pkg + "...", p);
                    }
                }

                SetStatus("ArrStack Deployment Complete!", 100);
                Log("ArrStack has been successfully deployed!");
                Log("Opening dashboard: http://localhost:32400/web");

                Process.Start("http://localhost:32400/web");
            }
            catch (Exception ex)
            {
                Log("ERROR: " + ex.Message);
                SetStatus("Installation encountered an issue: " + ex.Message, 0);
            }
        }

        private void RunCmd(string exe, string args, string workingDir)
        {
            try
            {
                ProcessStartInfo psi = new ProcessStartInfo
                {
                    FileName = exe,
                    Arguments = args,
                    WorkingDirectory = workingDir,
                    CreateNoWindow = true,
                    UseShellExecute = false,
                    RedirectStandardOutput = true,
                    RedirectStandardError = true
                };
                using (Process proc = Process.Start(psi))
                {
                    string outStr = proc.StandardOutput.ReadToEnd();
                    string errStr = proc.StandardError.ReadToEnd();
                    proc.WaitForExit();
                    if (!string.IsNullOrEmpty(outStr)) Log(outStr.Trim());
                    if (!string.IsNullOrEmpty(errStr)) Log(errStr.Trim());
                }
            }
            catch (Exception ex)
            {
                Log("Process error: " + ex.Message);
            }
        }

        [STAThread]
        public static void Main(string[] args)
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new InstallerForm());
        }
    }
}
