# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

SSDBridge is a macOS file-sharing app that runs an embedded Vapor HTTP server to share local directories/files via magic links. It supports optional Cloudflare Quick Tunnels for global access (HTTPS via `*.trycloudflare.com`). The guest client is a vanilla JS SPA with dark mode, mobile support, and resumable downloads.

## Build & Run

```bash
swift build          # Debug build
swift run            # Run the server
swift build -c release  # Release build
```

There are no tests, linters, or CI configured.

## Architecture

SwiftUI host app + Vapor HTTP server + vanilla JS SPA guest client. All state flows through a single `@MainActor AppState` ObservableObject injected as an `@EnvironmentObject` into every view.

### Directory layout

```
SSDBridge/
├── App/
│   ├── SSDBridgeApp.swift    — @main: WindowGroup + MenuBarExtra + Settings scene
│   └── AppState.swift        — Central @MainActor ObservableObject; owns all managers, server/tunnel lifecycle
├── Models/
│   ├── Config.swift          — Constants (port, token length, TTLs, etc.)
│   ├── Token.swift           — Magic link model
│   └── Session.swift         — Browser session model
├── Server/
│   ├── ServerManager.swift   — Vapor app setup: CORS, middleware, all route registrations
│   └── Middleware/
│       ├── AuthMiddleware.swift      — Bearer token or ?token= query param; stores Session on Request.storage
│       └── RateLimitMiddleware.swift — IP-based sliding-window rate limiter
├── Services/
│   ├── TokenManager.swift         — Magic link CRUD; salted iterated SHA-256 password hashing, NSLock
│   ├── SessionManager.swift       — Browser session CRUD with periodic expiry cleanup
│   ├── TunnelManager.swift        — cloudflared subprocess management, stderr URL parsing
│   ├── DriveWatcher.swift         — DispatchSource filesystem watcher on /Volumes
│   ├── WebSocketManager.swift     — Per-session WebSocket connections; broadcast refresh signals
│   ├── ChunkedUploadManager.swift — 10MB chunked uploads; OutputStream assembly, stale cleanup
│   ├── FileUtils.swift            — MIME types, size formatting, ZIP creation via ZIPFoundation
│   ├── NetworkUtils.swift         — getLocalIP() via getifaddrs (prefers en0/en1)
│   ├── AccessLogger.swift         — Access events (joins, downloads, uploads, rate limits)
│   ├── TransferStats.swift        — Transfer counters and live bandwidth (5s sliding window)
│   └── Logging.swift              — Structured os.Logger instances by category
├── Views/                         — SwiftUI dashboard views (Dashboard, CreateLink, ActiveLinks, Sessions, etc.)
└── Resources/ClientDist/          — Static guest web client (index.html, app.js, styles.css)
```

### Key design patterns

- **Thread safety**: All service managers use `NSLock` and are `@unchecked Sendable`.
- **Auth**: `AuthMiddleware` → `Request.storage[SessionKey.self]`. Route handlers use `try req.userSession` (throws if not set).
- **Permissions**: `"read"` (browse/download) and `"readwrite"` (upload/delete/rename/mkdir). `WritePermissionMiddleware` enforces write routes.
- **Security**: All file handlers validate scope paths, reject symlinks, and sanitize filenames (`lastPathComponent`). Password hashing uses salted iterated SHA-256 with legacy hash backward compat.
- **Rate limiting**: Join endpoint: 5 req/60s. File operations: 60 req/60s. Write operations: 20 req/60s.
- **ZIP temp files**: Cleaned via periodic timer (5-min expiry) instead of fixed 30s delay — avoids race with slow downloads.
- **Preview safety**: Text previews read only first 513KB via `FileHandle`. Binary previews use `req.fileio.streamFile(at:)`.
- **Port persistence**: `serverPort` stored in `UserDefaults` via `@Published` `didSet`.
- **HTTP Range**: Server supports `Range: bytes=START-END` via Vapor's built-in `FileIO.streamFile()` — returns `206 Partial Content`.
- **Client UI**: Vanilla JS SPA with CSS custom property design tokens, dark mode (`data-theme` + localStorage), reduced-motion support. Styled toast/confirm/prompt dialogs replace native `alert()`/`confirm()`/`prompt()`.

### API routes

| Method | Path | Auth | Rate Limit | Description |
|--------|------|------|------------|-------------|
| GET | `/api/health` | No | — | Health check |
| GET | `/api/stats` | No | — | Transfer counters |
| POST | `/api/links` | No | — | Create magic link |
| GET | `/api/links` | No | — | List active links |
| DELETE | `/api/links/:tokenId` | No | — | Revoke link |
| POST | `/api/join/:tokenId` | No | 5/60s | Join → session |
| GET | `/api/files/**` | Session | — | Browse directory / file metadata (supports `?offset=&limit=`) |
| GET | `/api/download/**` | Session | 60/60s | Download file (supports `Range` header for resume) |
| GET | `/api/download-zip/**` | Session | 60/60s | Download directory as ZIP |
| GET | `/api/preview/**` | Session | 60/60s | Text preview or inline binary |
| POST | `/api/download-bulk` | Session | 60/60s | Multi-file ZIP |
| POST | `/api/upload/**` | Session + write | 20/60s | Upload files |
| POST | `/api/mkdir/**` | Session + write | 20/60s | Create directory |
| PUT | `/api/rename/**` | Session + write | 20/60s | Rename file/dir |
| DELETE | `/api/delete/**` | Session + write | 20/60s | Delete file/dir |
| POST | `/api/chunked/init` | Session + write | 20/60s | Start chunked upload |
| POST | `/api/chunked/upload/:uploadId` | Session + write | 20/60s | Upload chunk |
| GET | `/api/chunked/status/:uploadId` | Session | — | Chunked upload progress |
| POST | `/api/chunked/complete/:uploadId` | Session + write | 20/60s | Finalize chunked upload |
| WS | `/ws?token=<sessionId>` | Query param | — | Real-time refresh |
| GET | `/**` | No | — | SPA fallback → index.html |

### Client features

- **Dark mode**: Auto-detects `prefers-color-scheme`, toggle in sidebar, persists to localStorage. FOUC prevention via inline `<head>` script.
- **Search**: Client-side filter with 150ms debounce. Clear button when filter active.
- **Pagination**: Server supports `offset`/`limit` (default 100, max 200). Client shows "N of M items" and "Load more" button.
- **Bulk operations**: Multi-select with checkboxes, bulk download (ZIP), bulk delete.
- **Rename**: Per-file rename via prompt dialog, calls `PUT /api/rename/**`.
- **Directory upload**: `webkitdirectory` input uploads entire folder trees.
- **Resumable downloads**: Three-tier strategy — File System Access API streaming (Chromium, any size), fetch+Blob progress (all browsers, ≤100MB), `window.location.href` fallback (Safari/Firefox, >100MB). Resume state saved to localStorage with 24h expiry.
- **Chunked uploads**: Files >50MB use 10MB chunks with retry and progress tracking.
- **WebSocket**: Real-time file list refresh on changes.
- **E2E encryption**: AES-GCM for files ≤50MB. Key passed via URL fragment (`#key=...`).
- **Mobile**: Card-based file view at ≤640px, fixed bottom tab bar, swipe-to-close sidebar, 44px touch targets, safe-area-inset support.
- **Accessibility**: ARIA grid/row/gridcell roles, keyboard navigation (Enter, Escape), focus management, `prefers-reduced-motion`, `.sr-only` labels, 4.5:1 color contrast.

### Design tokens (styles.css)

All CSS uses namespaced custom properties: `--color-*` (surfaces, brand, text, borders, semantic, file-type), `--text-*` (type scale), `--space-*` (4px grid), `--shadow-*`, `--radius-*`, `--z-*` (elevation), `--transition-*`, `--font-*`. Dark mode overrides in `[data-theme="dark"]` and `@media (prefers-color-scheme: dark)`.

## Dependencies

- **Vapor** (4.89+) — HTTP server
- **ZIPFoundation** (0.9.18+) — ZIP archives
- **cloudflared** (external binary, optional) — `brew install cloudflared` for global tunnel
