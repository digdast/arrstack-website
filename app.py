import os
import sys
import json
import mimetypes
import urllib.parse
from pathlib import Path
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler

APP_DIR = Path(__file__).parent.resolve()
STATIC_DIR = APP_DIR / "static"
DOWNLOADS_DIR = APP_DIR / "downloads"
PORT = int(os.environ.get("PORT", "8080"))

# Register custom MIME types
mimetypes.add_type("text/x-shellscript", ".sh")
mimetypes.add_type("text/plain", ".ps1")
mimetypes.add_type("text/yaml", ".yml")
mimetypes.add_type("text/yaml", ".yaml")
mimetypes.add_type("application/x-msdownload", ".exe")
mimetypes.add_type("application/x-msi", ".msi")
mimetypes.add_type("image/svg+xml", ".svg")

class ArrStackHandler(BaseHTTPRequestHandler):
    def send_security_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, HEAD, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("X-Frame-Options", "SAMEORIGIN")
        self.send_header("X-XSS-Protection", "1; mode=block")
        self.send_header("Referrer-Policy", "strict-origin-when-cross-origin")
        self.send_header("Permissions-Policy", "camera=(), microphone=(), geolocation=()")

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_security_headers()
        self.end_headers()

    def do_HEAD(self):
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_security_headers()
        self.end_headers()

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path.rstrip("/")
        if not path:
            path = "/"

        # Health endpoint
        if path == "/api/health":
            body = json.dumps({"status": "healthy", "service": "arrstack-website", "version": "2.4.0"}).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.send_security_headers()
            self.end_headers()
            self.wfile.write(body)
            return

        # Direct installer endpoints
        file_map = {
            "/": APP_DIR / "index.html",
            "/index.html": APP_DIR / "index.html",
            "/install.sh": APP_DIR / "install.sh",
            "/install.ps1": APP_DIR / "install.ps1",
            "/docker-compose.yml": APP_DIR / "docker-compose.yml",
            "/ads.txt": APP_DIR / "ads.txt",
            "/robots.txt": APP_DIR / "robots.txt",
            "/sitemap.xml": APP_DIR / "sitemap.xml",
            "/favicon.svg": APP_DIR / "favicon.svg"
        }

        target = None
        if path in file_map:
            target = file_map[path]
        elif path.startswith("/downloads/"):
            filename = path[len("/downloads/"):]
            candidate = (DOWNLOADS_DIR / filename).resolve()
            try:
                candidate.relative_to(DOWNLOADS_DIR)
                if candidate.exists() and candidate.is_file():
                    target = candidate
            except ValueError:
                target = None
        elif path.startswith("/static/"):
            filename = path[len("/static/"):]
            candidate = (STATIC_DIR / filename).resolve()
            try:
                candidate.relative_to(STATIC_DIR)
                if candidate.exists() and candidate.is_file():
                    target = candidate
            except ValueError:
                target = None

        if target and target.exists() and target.is_file():
            mime, _ = mimetypes.guess_type(str(target))
            if target.suffix == ".sh":
                mime = "text/x-shellscript"
            elif target.suffix == ".ps1":
                mime = "text/plain"
            elif target.suffix in [".yml", ".yaml"]:
                mime = "text/yaml"

            with open(target, "rb") as f:
                content = f.read()

            self.send_response(200)
            content_type = mime or "application/octet-stream"
            if "text" in content_type:
                content_type += "; charset=utf-8"
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(content)))
            self.send_header("Cache-Control", "public, max-age=300")
            self.send_security_headers()
            self.end_headers()
            self.wfile.write(content)
        else:
            self.send_error(404, "ArrStack File Not Found")

    def log_message(self, format, *args):
        pass

def main():
    server = ThreadingHTTPServer(("0.0.0.0", PORT), ArrStackHandler)
    print(f"[*] ArrStack Official Portal running on http://0.0.0.0:{PORT}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n[!] Shutting down server...")
        server.server_close()

if __name__ == "__main__":
    main()
