# SSDBridge

**Turn any external drive into your personal cloud in seconds.** Plug in a drive, fire up SSDBridge, and share it over LAN or the internet with a single magic link. No uploads, no accounts, no storage limits — your files stay on your drive, accessible from any device, anywhere.

Built with SwiftUI + Vapor on the host side and a vanilla JavaScript SPA for the guest client.

## Features

### Sharing
- **Magic links** — password-protected, time-limited, single-use, or persistent
- **Permissions** — read-only or read-write per link
- **End-to-end encryption** — AES-GCM for files up to 50 MB (key delivered via URL fragment)
- **Global access** — optional Cloudflare Quick Tunnel for HTTPS via `*.trycloudflare.com`
- **QR codes** — scan to join from any device
- **Link presets** — save and reuse frequently-used share configurations

### File Operations
- **Browse & navigate** — directory listing with breadcrumbs, pagination, and real-time search
- **Preview** — images, video, audio, PDF, and text files inline
- **Download** — single files, directories as ZIP, or multi-select bulk ZIP
- **Resumable downloads** — File System Access API streaming for Chromium browsers; native download manager fallback for Safari/Firefox
- **Upload** — simple upload with progress bar, or chunked upload (10 MB chunks) for files > 50 MB
- **Resumable uploads** — interrupted chunked uploads survive page reloads and resume from the last received chunk
- **Cancel transfers** — cancel any in-progress upload or download
- **Create folders, rename, delete** — full write operations for read-write links
- **Recent files** — quickly access recently downloaded or uploaded files

### Host App (macOS)
- **Menu bar** — status indicator, quick server start/stop, one-click share from presets
- **Dashboard** — server control, tunnel toggle, active links and sessions, access log, transfer stats
- **Settings** — port configuration, notifications, preset management
- **macOS notifications** — alerted when someone joins, downloads, or uploads

### Guest Client (Web)
- **Dark mode** — auto-detects system preference, toggle persists to localStorage
- **Mobile responsive** — card-based file view, bottom tab bar, swipe gestures, 44 px touch targets
- **Accessible** — ARIA grid roles, keyboard navigation, screen-reader labels, `prefers-reduced-motion`
- **Real-time sync** — WebSocket refresh when files change
- **Drag-and-drop upload** — with full-page drop zone overlay

## Requirements

- macOS 13+
- Swift 5.9+
- [cloudflared](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/) (optional, for global tunnel)

## Quick Start

```bash
# Clone
git clone https://github.com/MananxRobin/ssdbridge.git
cd ssdbridge

# Build & run
swift run
```

The server starts on port 3001 (configurable in Settings). Open the dashboard to create your first magic link.

For global internet access, install cloudflared and click "Enable" in the tunnel section:

```bash
brew install cloudflared
```

## Architecture

```
SSDBridge/
├── App/                         # SwiftUI app entry + central state
│   ├── SSDBridgeApp.swift       # @main: WindowGroup + MenuBarExtra
│   └── AppState.swift           # @MainActor ObservableObject
├── Models/                      # Data structures
│   ├── Token.swift              # Magic link
│   ├── Session.swift            # Browser session
│   ├── Config.swift             # Constants
│   └── LinkPreset.swift         # Saved share preset
├── Server/
│   ├── ServerManager.swift      # Vapor HTTP server + all routes
│   └── Middleware/              # Auth, rate limiting, write permission
├── Services/                    # Business logic
│   ├── TokenManager.swift       # Magic link CRUD + password hashing
│   ├── SessionManager.swift     # Session lifecycle
│   ├── ChunkedUploadManager.swift  # Chunked upload assembly
│   ├── TunnelManager.swift      # cloudflared subprocess
│   ├── WebSocketManager.swift   # Real-time refresh
│   ├── DriveWatcher.swift       # /Volumes filesystem watcher
│   ├── AccessLogger.swift       # Join/download/upload audit
│   ├── TransferStats.swift      # Bandwidth + counters
│   ├── FileUtils.swift          # MIME types, ZIP creation
│   ├── NetworkUtils.swift       # LAN IP detection
│   └── Logging.swift            # os.Logger by category
├── Views/                       # SwiftUI macOS dashboard
└── Resources/ClientDist/        # Guest web client (vanilla JS SPA)
    ├── index.html
    ├── app.js                   # 1,700+ lines — full file browser
    └── styles.css               # 2,000+ lines — dark mode, mobile, design tokens
```

### API Routes

| Method | Path | Auth | Rate | Description |
|--------|------|------|------|-------------|
| `GET` | `/api/health` | — | — | Health check |
| `POST` | `/api/links` | — | — | Create magic link |
| `GET` | `/api/links` | — | — | List active links |
| `DELETE` | `/api/links/:id` | — | — | Revoke link |
| `POST` | `/api/join/:id` | — | 5/60s | Join via magic link |
| `GET` | `/api/files/**` | Session | — | Browse directory |
| `GET` | `/api/download/**` | Session | 60/60s | Download file |
| `GET` | `/api/download-zip/**` | Session | 60/60s | Download as ZIP |
| `GET` | `/api/preview/**` | Session | 60/60s | Preview file |
| `POST` | `/api/download-bulk` | Session | 60/60s | Multi-file ZIP |
| `POST` | `/api/upload/**` | Write | 20/60s | Upload files |
| `POST` | `/api/mkdir/**` | Write | 20/60s | Create folder |
| `PUT` | `/api/rename/**` | Write | 20/60s | Rename |
| `DELETE` | `/api/delete/**` | Write | 20/60s | Delete |
| `POST` | `/api/chunked/init` | Write | 20/60s | Start chunked upload |
| `POST` | `/api/chunked/upload/:id` | Write | 20/60s | Upload chunk |
| `GET` | `/api/chunked/status/:id` | Session | — | Chunk progress |
| `POST` | `/api/chunked/complete/:id` | Write | 20/60s | Assemble chunks |
| `DELETE` | `/api/chunked/:id` | Session | — | Cancel upload |
| `GET` | `/api/recent` | Session | — | Recent files |
| `GET` | `/api/stats` | — | — | Transfer stats |
| `WS` | `/ws?token=<id>` | Query | — | Real-time refresh |
| `GET` | `/**` | — | — | SPA fallback |

## Dependencies

- [Vapor](https://github.com/vapor/vapor) 4.x — HTTP server framework
- [ZIPFoundation](https://github.com/weichsel/ZIPFoundation) — ZIP archive creation
- [cloudflared](https://github.com/cloudflare/cloudflared) (external, optional) — global tunnel

## License

MIT
