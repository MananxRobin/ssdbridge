import Vapor
import Foundation

/// Manages the embedded Vapor HTTP server lifecycle.
final class ServerManager: @unchecked Sendable {
    private let app: Application
    private let port: Int
    private let tokenManager: TokenManager
    private let sessionManager: SessionManager
    private let driveWatcher: DriveWatcher
    private let accessLogger: AccessLogger
    private let webSocketManager: WebSocketManager
    private let transferStats: TransferStats
    private let chunkedUploadManager: ChunkedUploadManager

    /// Set by AppState when a Cloudflare tunnel is connected.
    var tunnelURL: String?

    /// Callback for sending macOS notifications (set by AppState).
    var onNotification: ((String, String) -> Void)?

    /// Temp files pending cleanup (ZIP downloads). Cleaned periodically to avoid
    /// deleting files while they are still being streamed.
    private var pendingTempFiles: [(path: String, createdAt: Date)] = []
    private let tempFileLock = NSLock()
    private var tempCleanupTimer: Timer?

    init(port: Int, tokenManager: TokenManager, sessionManager: SessionManager, driveWatcher: DriveWatcher, accessLogger: AccessLogger, webSocketManager: WebSocketManager, transferStats: TransferStats, chunkedUploadManager: ChunkedUploadManager) {
        self.port = port
        self.tokenManager = tokenManager
        self.sessionManager = sessionManager
        self.driveWatcher = driveWatcher
        self.accessLogger = accessLogger
        self.webSocketManager = webSocketManager
        self.transferStats = transferStats
        self.chunkedUploadManager = chunkedUploadManager
        self.app = Application(.production)
    }

    func start() async throws {
        // Configure server
        app.http.server.configuration.hostname = Config.defaultHost
        app.http.server.configuration.port = port

        // CORS
        let cors = CORSMiddleware(configuration: .init(
            allowedOrigin: .all,
            allowedMethods: [.GET, .POST, .PUT, .DELETE, .OPTIONS],
            allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .init("X-Chunk-Index"), .init("X-Filename")]
        ))
        app.middleware.use(cors)

        // Increase body size limit for uploads (chunks are 10MB)
        app.routes.defaultMaxBodySize = "100mb"

        // Register routes
        let auth = AuthMiddleware(sessionManager: sessionManager)
        let writeGuard = WritePermissionMiddleware()
        let joinRateLimit = RateLimitMiddleware(maxRequests: 5, windowSeconds: 60)
        let fileRateLimit = RateLimitMiddleware(maxRequests: 60, windowSeconds: 60)
        let writeRateLimit = RateLimitMiddleware(maxRequests: 20, windowSeconds: 60)

        registerLinkRoutes(app: app, rateLimit: joinRateLimit)
        registerFileRoutes(app: app, auth: auth)
        registerDownloadRoutes(app: app, auth: auth, rateLimit: fileRateLimit)
        registerPreviewRoutes(app: app, auth: auth, rateLimit: fileRateLimit)
        registerWriteRoutes(app: app, auth: auth, writeGuard: writeGuard, rateLimit: writeRateLimit)
        registerChunkedRoutes(app: app, auth: auth, writeGuard: writeGuard, rateLimit: writeRateLimit)
        registerWebSocketRoute(app: app)
        registerBulkDownloadRoute(app: app, auth: auth, rateLimit: fileRateLimit)
        registerStatsRoute(app: app)
        registerWormholeRoute(app: app, auth: auth)
        registerHostBeamRoute(app: app, auth: auth)
        registerRecentRoute(app: app, auth: auth)
        registerHealthRoute(app: app)
        registerStaticFiles(app: app)

        // Start server in background
        try app.start()

        // Start temp file cleanup timer (ZIP downloads)
        startTempCleanupTimer()

        Log.server.info("""

        ╔══════════════════════════════════════════════╗
        ║          SSDBridge — Swift Server             ║
        ╠══════════════════════════════════════════════╣
        ║  HTTP:  http://localhost:\(self.port)               ║
        ║  LAN:   http://\(NetworkUtils.getLocalIP()):\(self.port)       ║
        ╚══════════════════════════════════════════════╝
        """)
    }

    func stop() {
        tempCleanupTimer?.invalidate()
        tempCleanupTimer = nil
        cleanupTempFiles(forceAll: true)
        webSocketManager.closeAll()
        app.shutdown()
    }

    // MARK: - Temp File Cleanup

    private func scheduleTempCleanup(_ path: String) {
        tempFileLock.lock()
        pendingTempFiles.append((path: path, createdAt: Date()))
        tempFileLock.unlock()
    }

    private func startTempCleanupTimer() {
        tempCleanupTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.cleanupTempFiles()
        }
    }

    private func cleanupTempFiles(forceAll: Bool = false) {
        let cutoff = forceAll ? Date.distantFuture : Date().addingTimeInterval(-300) // 5 min
        tempFileLock.lock()
        let expired = pendingTempFiles.filter { $0.createdAt < cutoff }
        pendingTempFiles = forceAll ? [] : pendingTempFiles.filter { $0.createdAt >= cutoff }
        tempFileLock.unlock()
        for item in expired {
            try? FileManager.default.removeItem(atPath: item.path)
        }
    }

    // MARK: - WebSocket Route

    private func registerWebSocketRoute(app: Application) {
        app.webSocket("ws") { req, ws in
            // Authenticate via query param
            guard let sessionId = req.query[String.self, at: "token"],
                  let session = self.sessionManager.getSession(sessionId) else {
                try? await ws.close()
                return
            }
            self.webSocketManager.add(sessionId: sessionId, socket: ws, scopePath: session.scopePath)
        }
    }

    // MARK: - Bulk Download Route

    private func registerBulkDownloadRoute(app: Application, auth: AuthMiddleware, rateLimit: RateLimitMiddleware) {
        let bulkGroup = app.grouped(auth).grouped(rateLimit)

        // POST /api/download-bulk — download multiple files as ZIP
        bulkGroup.post("api", "download-bulk") { req -> Response in
            struct BulkRequest: Content {
                var paths: [String]
            }
            let body = try req.content.decode(BulkRequest.self)
            let session = try req.userSession
            let fm = FileManager.default
            let scope = (session.scopePath as NSString).standardizingPath

            let tempDir = NSTemporaryDirectory() + UUID().uuidString
            try fm.createDirectory(atPath: tempDir, withIntermediateDirectories: true)

            // Copy selected files to temp directory
            var totalBytes: Int64 = 0
            for relativePath in body.paths {
                let fullPath = (session.scopePath as NSString).appendingPathComponent(relativePath)
                let resolved = (fullPath as NSString).standardizingPath
                guard resolved.hasPrefix(scope) else { continue }
                guard fm.fileExists(atPath: resolved) else { continue }

                let destPath = (tempDir as NSString).appendingPathComponent(
                    (relativePath as NSString).lastPathComponent
                )
                try? fm.copyItem(atPath: resolved, toPath: destPath)

                if let attrs = try? fm.attributesOfItem(atPath: resolved) {
                    totalBytes += (attrs[.size] as? Int64) ?? 0
                }
            }

            // Create ZIP
            let zipPath = NSTemporaryDirectory() + UUID().uuidString + ".zip"
            try FileUtils.createZip(from: tempDir, to: zipPath)
            try? fm.removeItem(atPath: tempDir)

            self.transferStats.recordDownload(bytes: totalBytes)
            self.accessLogger.log(ip: self.extractClientIP(from: req), action: .download, tokenId: session.token, detail: "Bulk: \(body.paths.count) files")

            let response = req.fileio.streamFile(at: zipPath)
            response.headers.replaceOrAdd(
                name: .contentDisposition,
                value: self.sanitizeHeaderFilename("SSDBridge-\(body.paths.count)-files.zip")
            )
            response.headers.contentType = .init(type: "application", subType: "zip")

            // Defer cleanup to periodic temp-file reaper (avoids deleting while still streaming)
            self.scheduleTempCleanup(zipPath)

            return response
        }
    }
    // MARK: - Chunked Upload Routes

    private func registerChunkedRoutes(app: Application, auth: AuthMiddleware, writeGuard: WritePermissionMiddleware, rateLimit: RateLimitMiddleware) {
        let chunked = app.grouped(auth).grouped(writeGuard).grouped(rateLimit)

        // POST /api/chunked/init — start a chunked upload session
        chunked.post("api", "chunked", "init") { req -> Response in
            struct InitBody: Content {
                var filename: String
                var totalSize: Int64
                var chunkSize: Int?
                var totalChunks: Int
                var targetPath: String     // relative path within scope
            }
            let body = try req.content.decode(InitBody.self)
            let session = try req.userSession

            let targetDir = body.targetPath.isEmpty
                ? session.scopePath
                : (session.scopePath as NSString).appendingPathComponent(body.targetPath)
            let resolved = (targetDir as NSString).standardizingPath
            let scope = (session.scopePath as NSString).standardizingPath
            guard resolved == scope || resolved.hasPrefix(scope + "/") else {
                throw Abort(.forbidden, reason: "Access denied — path outside scope")
            }

            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: resolved, isDirectory: &isDir), isDir.boolValue else {
                throw Abort(.notFound, reason: "Target directory not found")
            }
            guard !self.isSymbolicLink(atPath: resolved) else {
                throw Abort(.forbidden, reason: "Access denied — symbolic links are not followed")
            }

            let chunkSize = body.chunkSize ?? ChunkedUploadManager.defaultChunkSize
            let safeFilename = (body.filename as NSString).lastPathComponent
            let uploadId = try self.chunkedUploadManager.initUpload(
                filename: safeFilename,
                targetDir: resolved,
                totalSize: body.totalSize,
                chunkSize: chunkSize,
                totalChunks: body.totalChunks,
                sessionId: session.id
            )

            let result: [String: String] = ["uploadId": uploadId]
            let jsonData = try JSONSerialization.data(withJSONObject: result)
            let response = Response(status: .ok)
            response.headers.contentType = .json
            response.body = .init(data: jsonData)
            return response
        }

        // POST /api/chunked/upload/:uploadId — receive a single chunk
        chunked.on(.POST, "api", "chunked", "upload", ":uploadId", body: .collect(maxSize: "12mb")) { req -> Response in
            guard let uploadId = req.parameters.get("uploadId") else {
                throw Abort(.badRequest, reason: "Missing upload ID")
            }
            guard let indexStr = req.headers.first(name: "X-Chunk-Index"),
                  let index = Int(indexStr) else {
                throw Abort(.badRequest, reason: "Missing X-Chunk-Index header")
            }

            let session = try req.userSession
            guard self.chunkedUploadManager.validateOwnership(uploadId: uploadId, sessionId: session.id) else {
                throw Abort(.forbidden, reason: "Upload session does not belong to this session")
            }

            guard let body = req.body.data else {
                throw Abort(.badRequest, reason: "No chunk data")
            }

            let data = Data(buffer: body)
            try self.chunkedUploadManager.writeChunk(uploadId: uploadId, index: index, data: data)

            let result: [String: Any] = ["received": index, "size": data.count]
            let jsonData = try JSONSerialization.data(withJSONObject: result)
            let response = Response(status: .ok)
            response.headers.contentType = .json
            response.body = .init(data: jsonData)
            return response
        }

        // GET /api/chunked/status/:uploadId — check progress
        chunked.get("api", "chunked", "status", ":uploadId") { req -> Response in
            guard let uploadId = req.parameters.get("uploadId") else {
                throw Abort(.badRequest, reason: "Missing upload ID")
            }

            let session = try req.userSession
            guard self.chunkedUploadManager.validateOwnership(uploadId: uploadId, sessionId: session.id) else {
                throw Abort(.forbidden, reason: "Upload session does not belong to this session")
            }

            guard let status = self.chunkedUploadManager.getStatus(uploadId: uploadId) else {
                throw Abort(.notFound, reason: "Upload session not found")
            }

            let result: [String: Any] = [
                "receivedChunks": status.received,
                "totalChunks": status.totalChunks,
                "totalSize": status.totalSize,
                "filename": status.filename
            ]
            let jsonData = try JSONSerialization.data(withJSONObject: result)
            let response = Response(status: .ok)
            response.headers.contentType = .json
            response.body = .init(data: jsonData)
            return response
        }

        // POST /api/chunked/complete/:uploadId — finalize & assemble
        chunked.post("api", "chunked", "complete", ":uploadId") { req -> Response in
            guard let uploadId = req.parameters.get("uploadId") else {
                throw Abort(.badRequest, reason: "Missing upload ID")
            }

            let session = try req.userSession
            guard self.chunkedUploadManager.validateOwnership(uploadId: uploadId, sessionId: session.id) else {
                throw Abort(.forbidden, reason: "Upload session does not belong to this session")
            }

            let result = try self.chunkedUploadManager.completeUpload(uploadId: uploadId)

            self.transferStats.recordUpload(bytes: result.totalSize)
            self.webSocketManager.broadcastRefresh()
            self.accessLogger.log(ip: self.extractClientIP(from: req), action: .upload, tokenId: session.token, detail: (result.filePath as NSString).lastPathComponent)
            self.onNotification?("Large file uploaded", (result.filePath as NSString).lastPathComponent)

            let responseData: [String: Any] = [
                "ok": true,
                "filename": (result.filePath as NSString).lastPathComponent,
                "totalSize": result.totalSize
            ]
            let jsonData = try JSONSerialization.data(withJSONObject: responseData)
            let response = Response(status: .ok)
            response.headers.contentType = .json
            response.body = .init(data: jsonData)
            return response
        }

        // DELETE /api/chunked/:uploadId — cancel a chunked upload
        chunked.delete("api", "chunked", ":uploadId") { req -> Response in
            guard let uploadId = req.parameters.get("uploadId") else {
                throw Abort(.badRequest, reason: "Missing upload ID")
            }
            let session = try req.userSession
            guard self.chunkedUploadManager.validateOwnership(uploadId: uploadId, sessionId: session.id) else {
                throw Abort(.forbidden, reason: "Upload session does not belong to this session")
            }
            self.chunkedUploadManager.cancelUpload(uploadId: uploadId)
            return Response(status: .ok)
        }
    }

    // MARK: - Wormhole Route (guest → host file transfer)

    private func registerWormholeRoute(app: Application, auth: AuthMiddleware) {
        app.grouped(auth).on(.POST, "api", "wormhole", body: .collect(maxSize: "100mb")) { req -> Response in
            let session = try req.userSession
            let fm = FileManager.default

            // Parse multipart or raw body
            var results: [[String: Any]] = []

            if let body = req.body.data {
                let rawFilename = req.headers.first(name: "X-Filename") ?? "wormhole_file"
                let safeFilename = (rawFilename as NSString).lastPathComponent
                let destPath = (Config.wormholeInboxDir as NSString).appendingPathComponent(safeFilename)
                // Avoid overwriting — append number if needed
                let finalPath = self.uniquePath(for: destPath)
                try Data(buffer: body).write(to: URL(fileURLWithPath: finalPath))
                results.append(["name": safeFilename, "size": body.readableBytes, "status": "arrived"])
            }

            if let contentType = req.headers.contentType,
               contentType.type == "multipart" {
                let files = try req.content.decode([String: [File]].self)
                for (_, fileList) in files {
                    for file in fileList {
                        let safeName = (file.filename as NSString).lastPathComponent
                        let destPath = (Config.wormholeInboxDir as NSString).appendingPathComponent(safeName)
                        let finalPath = self.uniquePath(for: destPath)
                        try Data(buffer: file.data).write(to: URL(fileURLWithPath: finalPath))
                        results.append(["name": safeName, "size": file.data.readableBytes, "status": "arrived"])
                    }
                }
            }

            let totalBytes = results.reduce(Int64(0)) { $0 + (($1["size"] as? Int64) ?? Int64($1["size"] as? Int ?? 0)) }
            self.transferStats.recordUpload(bytes: totalBytes)

            // Broadcast activity
            for file in results {
                if let name = file["name"] as? String {
                    self.webSocketManager.broadcastActivity(action: "wormhole", detail: name)
                }
            }

            // Notify host
            let fileNames = results.compactMap { $0["name"] as? String }.joined(separator: ", ")
            self.onNotification?("Wormhole: file arrived", fileNames)

            let responseData: [String: Any] = ["arrived": true, "files": results]
            let jsonData = try JSONSerialization.data(withJSONObject: responseData)
            let response = Response(status: .ok)
            response.headers.contentType = .json
            response.body = .init(data: jsonData)
            return response
        }
    }

    /// Avoid overwriting existing files by appending a number.
    private func uniquePath(for path: String) -> String {
        let fm = FileManager.default
        guard fm.fileExists(atPath: path) else { return path }
        let dir = (path as NSString).deletingLastPathComponent
        let base = (path as NSString).lastPathComponent
        let stem = (base as NSString).deletingPathExtension
        let ext = (base as NSString).pathExtension
        for i in 1...999 {
            let candidate = ext.isEmpty
                ? (dir as NSString).appendingPathComponent("\(stem) \(i)")
                : (dir as NSString).appendingPathComponent("\(stem) \(i).\(ext)")
            if !fm.fileExists(atPath: candidate) { return candidate }
        }
        return path
    }

    // MARK: - Stats Route

    private func registerStatsRoute(app: Application) {
        app.get("api", "stats") { req -> Response in
            let data: [String: Any] = [
                "totalDownloads": self.transferStats.totalDownloads,
                "totalUploads": self.transferStats.totalUploads,
                "totalBytesDownloaded": self.transferStats.totalBytesDownloaded,
                "totalBytesUploaded": self.transferStats.totalBytesUploaded,
                "activeWebSockets": self.webSocketManager.activeCount,
            ]
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            let response = Response(status: .ok)
            response.headers.contentType = .json
            response.body = .init(data: jsonData)
            return response
        }
    }

    // MARK: - Host Beam Route

    private func registerHostBeamRoute(app: Application, auth: AuthMiddleware) {
        app.grouped(auth).post("api", "host", "beam") { req -> Response in
            struct BeamBody: Content { var path: String }
            let body = try req.content.decode(BeamBody.self)
            let session = try req.userSession

            let filePath = (session.scopePath as NSString).appendingPathComponent(body.path)
            let resolved = (filePath as NSString).standardizingPath
            let scope = (session.scopePath as NSString).standardizingPath
            guard resolved.hasPrefix(scope) else {
                throw Abort(.forbidden, reason: "Access denied — path outside scope")
            }
            guard FileManager.default.fileExists(atPath: resolved) else {
                throw Abort(.notFound, reason: "File not found")
            }
            guard !self.isSymbolicLink(atPath: resolved) else {
                throw Abort(.forbidden, reason: "Symbolic links are not followed")
            }

            let filename = (resolved as NSString).lastPathComponent
            let attrs = try FileManager.default.attributesOfItem(atPath: resolved)
            let size = (attrs[.size] as? Int64) ?? 0

            // Build per-session download URLs
            let encodedPath = body.path.split(separator: "/").map { $0.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? String($0) }.joined(separator: "/")
            var downloadUrls: [String: String] = [:]
            for sid in self.webSocketManager.connectedSessionIds() {
                downloadUrls[sid] = "/api/download/\(encodedPath)?token=\(sid)"
            }

            self.webSocketManager.beamToAll(filename: filename, size: size, downloadUrls: downloadUrls)
            self.accessLogger.log(ip: "host", action: .download, tokenId: session.token, detail: "Beam: \(filename)")

            let responseData: [String: Any] = ["beamed": filename, "recipients": downloadUrls.count]
            let jsonData = try JSONSerialization.data(withJSONObject: responseData)
            let response = Response(status: .ok)
            response.headers.contentType = .json
            response.body = .init(data: jsonData)
            return response
        }
    }

    // MARK: - Recent Files

    private func registerRecentRoute(app: Application, auth: AuthMiddleware) {
        app.grouped(auth).get("api", "recent") { req -> Response in
            let recent = self.accessLogger.getRecentFiles(limit: 50)
            let jsonData = try JSONSerialization.data(withJSONObject: ["files": recent])
            let response = Response(status: .ok)
            response.headers.contentType = .json
            response.body = .init(data: jsonData)
            return response
        }
    }

    // MARK: - Health

    private func registerHealthRoute(app: Application) {
        app.get("api", "health") { req -> [String: String] in
            ["status": "ok"]
        }
    }

    // MARK: - Static Files (Guest Client)

    private func registerStaticFiles(app: Application) {
        let fm = FileManager.default

        // Search for client files in multiple locations
        let sourceTreePath = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // ServerManager.swift
            .deletingLastPathComponent()  // Server/
            .deletingLastPathComponent()  // SSDBridge/ (inside build dir or source root)
            .appendingPathComponent("SSDBridge/Resources/ClientDist")
            .path

        let searchPaths = [
            // 1. Resolved relative to source file (development)
            sourceTreePath,
            // 2. Bundle resources (production build)
            (Bundle.main.resourcePath ?? "") + "/Resources/ClientDist",
            (Bundle.main.resourcePath ?? "") + "/ClientDist",
        ]

        guard let clientPath = searchPaths.first(where: { fm.fileExists(atPath: $0 + "/index.html") }) else {
            Log.server.warning("Guest client not found. Searched: \(searchPaths.joined(separator: ", "))")
            return
        }

        Log.server.info("Serving guest client from: \(clientPath)")

        // Ensure trailing slash for FileMiddleware
        let publicDir = clientPath.hasSuffix("/") ? clientPath : clientPath + "/"
        app.middleware.use(FileMiddleware(publicDirectory: publicDir))

        // SPA fallback — serve index.html for non-API routes
        app.get("**") { req -> Response in
            let path = req.url.path
            if path.hasPrefix("/api/") || path.hasPrefix("/ws") {
                throw Abort(.notFound)
            }
            let indexPath = clientPath + "/index.html"
            let data = try Data(contentsOf: URL(fileURLWithPath: indexPath))
            let response = Response(status: .ok)
            response.headers.replaceOrAdd(name: .contentType, value: "text/html; charset=utf-8")
            response.body = .init(data: data)
            return response
        }
    }

    // MARK: - Link Routes

    private func registerLinkRoutes(app: Application, rateLimit: RateLimitMiddleware) {
        let links = app.grouped("api", "links")

        // POST /api/links — create magic link
        links.post { req -> [String: String] in
            struct CreateBody: Content {
                var scopePath: String?
                var ttlMinutes: Int?
                var oneTimeJoin: Bool?
                var password: String?
                var permissions: String?
            }

            let body = try req.content.decode(CreateBody.self)
            let token = self.tokenManager.createToken(
                scopePath: body.scopePath ?? "/Volumes",
                ttlMinutes: body.ttlMinutes ?? Config.defaultTTLMinutes,
                oneTimeJoin: body.oneTimeJoin ?? false,
                password: body.password,
                permissions: body.permissions ?? "read"
            )

            let link: String
            if let tunnelURL = self.tunnelURL {
                link = "\(tunnelURL)/join/\(token.id)"
            } else {
                let ip = NetworkUtils.getLocalIP()
                link = "http://\(ip):\(self.port)/join/\(token.id)"
            }

            return [
                "token": token.id,
                "scopePath": token.scopePath,
                "expiresAt": ISO8601DateFormatter().string(from: token.expiresAt),
                "oneTimeJoin": token.oneTimeJoin ? "true" : "false",
                "hasPassword": token.hasPassword ? "true" : "false",
                "permissions": token.permissions,
                "link": link,
            ]
        }

        // GET /api/links
        links.get { req -> Response in
            let tokens = self.tokenManager.listTokens()
            let list = tokens.map { t -> [String: String] in
                [
                    "token": t.id,
                    "scopePath": t.scopePath,
                    "expiresAt": ISO8601DateFormatter().string(from: t.expiresAt),
                    "oneTimeJoin": t.oneTimeJoin ? "true" : "false",
                    "used": t.used ? "true" : "false",
                    "hasPassword": t.hasPassword ? "true" : "false",
                    "permissions": t.permissions,
                ]
            }
            let data = try JSONSerialization.data(withJSONObject: ["links": list])
            let response = Response(status: .ok)
            response.headers.contentType = .json
            response.body = .init(data: data)
            return response
        }

        // DELETE /api/links/:token
        links.delete(":tokenId") { req -> [String: Bool] in
            guard let tokenId = req.parameters.get("tokenId") else {
                throw Abort(.badRequest, reason: "Missing tokenId")
            }
            self.tokenManager.revokeToken(tokenId)
            return ["revoked": true]
        }

        // POST /api/join/:token — rate limited
        let joinGroup = app.grouped(rateLimit)
        joinGroup.post("api", "join", ":tokenId") { req -> Response in
            guard let tokenId = req.parameters.get("tokenId") else {
                throw Abort(.badRequest, reason: "Missing tokenId")
            }
            let ip = self.extractClientIP(from: req)

            guard let tokenData = self.tokenManager.validateToken(tokenId) else {
                self.accessLogger.log(ip: ip, action: .joinFailed, tokenId: tokenId, detail: "Invalid, expired, or already-used")
                throw Abort(.unauthorized, reason: "Invalid, expired, or already-used link")
            }

            struct JoinBody: Content {
                var password: String?
            }
            let body = try req.content.decode(JoinBody.self)

            if tokenData.hasPassword {
                guard let password = body.password, !password.isEmpty else {
                    self.accessLogger.log(ip: ip, action: .passwordFailed, tokenId: tokenId, detail: "Password not provided")
                    let response = Response(status: .forbidden)
                    response.headers.contentType = .json
                    response.body = .init(string: "{\"error\":\"password_required\",\"message\":\"This link requires a password\"}")
                    return response
                }
                if !self.tokenManager.checkPassword(token: tokenData, password: password) {
                    self.accessLogger.log(ip: ip, action: .passwordFailed, tokenId: tokenId, detail: "Wrong password")
                    let response = Response(status: .forbidden)
                    response.headers.contentType = .json
                    response.body = .init(string: "{\"error\":\"wrong_password\",\"message\":\"Incorrect password\"}")
                    return response
                }
            }

            if tokenData.oneTimeJoin {
                self.tokenManager.markUsed(tokenId)
            }

            let session = self.sessionManager.createSession(
                token: tokenId,
                scopePath: tokenData.scopePath,
                permissions: tokenData.permissions
            )

            self.accessLogger.log(ip: ip, action: .joinSuccess, tokenId: tokenId, detail: "Scope: \(tokenData.scopePath)")
            self.onNotification?("Someone joined", "IP: \(ip) — \(tokenData.scopePath)")
            // Will broadcast activity once WebSocket connects — just store intent
            // Activity is broadcast from WebSocketManager.add()

            let data: [String: String] = [
                "sessionId": session.id,
                "scopePath": session.scopePath,
                "permissions": session.permissions,
            ]
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            let response = Response(status: .ok)
            response.headers.contentType = .json
            response.body = .init(data: jsonData)
            return response
        }

        // GET /api/sessions
        app.get("api", "sessions") { req -> Response in
            let sessions = self.sessionManager.listSessions()
            let list = sessions.map { s -> [String: String] in
                [
                    "sessionId": s.id,
                    "scopePath": s.scopePath,
                    "permissions": s.permissions,
                    "createdAt": ISO8601DateFormatter().string(from: s.createdAt),
                    "lastActive": ISO8601DateFormatter().string(from: s.lastActive),
                ]
            }
            let data = try JSONSerialization.data(withJSONObject: ["sessions": list])
            let response = Response(status: .ok)
            response.headers.contentType = .json
            response.body = .init(data: data)
            return response
        }

        // DELETE /api/sessions/:sessionId
        app.delete("api", "sessions", ":sessionId") { req -> [String: Bool] in
            guard let sessionId = req.parameters.get("sessionId") else {
                throw Abort(.badRequest, reason: "Missing sessionId")
            }
            self.sessionManager.revokeSession(sessionId)
            return ["revoked": true]
        }
    }

    // MARK: - File Routes

    private func registerFileRoutes(app: Application, auth: AuthMiddleware) {
        let files = app.grouped("api", "files").grouped(auth)

        // Handler that works for both root and subpath
        let listHandler: @Sendable (Request) throws -> Response = { req in
            let relativePath = (try? req.parameters.getCatchall().joined(separator: "/")) ?? ""
            let session = try req.userSession
            let fm = FileManager.default
            let offset = max(0, Int(req.query[String.self, at: "offset"] ?? "0") ?? 0)
            let limit = min(200, max(1, Int(req.query[String.self, at: "limit"] ?? "100") ?? 100))

            let targetPath = relativePath.isEmpty
                ? session.scopePath
                : (session.scopePath as NSString).appendingPathComponent(relativePath)

            // Security: verify within scope
            let resolved = (targetPath as NSString).standardizingPath
            let scope = (session.scopePath as NSString).standardizingPath
            guard resolved == scope || resolved.hasPrefix(scope + "/") else {
                throw Abort(.forbidden, reason: "Access denied — path outside scope")
            }

            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: resolved, isDirectory: &isDir) else {
                throw Abort(.notFound, reason: "Path not found")
            }

            if !isDir.boolValue {
                // Single file metadata
                let attrs = try fm.attributesOfItem(atPath: resolved)
                let size = attrs[.size] as? Int64 ?? 0
                let modified = attrs[.modificationDate] as? Date ?? Date()
                let data: [String: Any] = [
                    "type": "file",
                    "name": (resolved as NSString).lastPathComponent,
                    "path": relativePath,
                    "size": size,
                    "sizeFormatted": FileUtils.formatSize(size),
                    "modified": ISO8601DateFormatter().string(from: modified),
                    "mimeType": FileUtils.mimeType(for: resolved),
                ]
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let response = Response(status: .ok)
                response.headers.contentType = .json
                response.body = .init(data: jsonData)
                return response
            }

            // Directory listing
            let contents = try fm.contentsOfDirectory(atPath: resolved)
            var items: [[String: Any]] = []

            for name in contents {
                if name.hasPrefix(".") { continue }
                let fullPath = (resolved as NSString).appendingPathComponent(name)
                let entryRelPath = relativePath.isEmpty ? name : "\(relativePath)/\(name)"

                guard let attrs = try? fm.attributesOfItem(atPath: fullPath) else { continue }
                let fileType = attrs[.type] as? FileAttributeType
                
                // Skip symbolic links (e.g. Macintosh HD in /Volumes)
                if fileType == .typeSymbolicLink { continue }

                let size = attrs[.size] as? Int64 ?? 0
                let modified = attrs[.modificationDate] as? Date ?? Date()

                if fileType == .typeDirectory {
                    items.append([
                        "name": name,
                        "type": "directory",
                        "path": entryRelPath,
                        "size": 0,
                        "sizeFormatted": "—",
                        "modified": ISO8601DateFormatter().string(from: modified),
                        "mimeType": NSNull(),
                    ])
                } else {
                    items.append([
                        "name": name,
                        "type": "file",
                        "path": entryRelPath,
                        "size": size,
                        "sizeFormatted": FileUtils.formatSize(size),
                        "modified": ISO8601DateFormatter().string(from: modified),
                        "mimeType": FileUtils.mimeType(for: name),
                    ])
                }
            }

            // Sort: directories first, then alphabetically
            items.sort { a, b in
                let typeA = (a["type"] as? String) ?? ""
                let typeB = (b["type"] as? String) ?? ""
                if typeA != typeB { return typeA == "directory" }
                let nameA = (a["name"] as? String) ?? ""
                let nameB = (b["name"] as? String) ?? ""
                return nameA.localizedCaseInsensitiveCompare(nameB) == .orderedAscending
            }

            let totalItems = items.count
            let pagedItems = Array(items.dropFirst(offset).prefix(limit))

            let pathSegments = relativePath.isEmpty ? [] : relativePath.split(separator: "/").map(String.init)
            let result: [String: Any] = [
                "type": "directory",
                "path": relativePath.isEmpty ? "/" : relativePath,
                "name": (resolved as NSString).lastPathComponent,
                "pathSegments": pathSegments,
                "items": pagedItems,
                "totalItems": totalItems,
                "offset": offset,
                "limit": limit,
                "hasMore": offset + limit < totalItems,
            ]

            let jsonData = try JSONSerialization.data(withJSONObject: result)
            let response = Response(status: .ok)
            response.headers.contentType = .json
            response.body = .init(data: jsonData)
            return response
        }

        // Register both root and subpath handlers
        files.get(use: listHandler)       // GET /api/files
        files.get("**", use: listHandler)  // GET /api/files/subpath/...
    }

    // MARK: - Download Routes

    private func registerDownloadRoutes(app: Application, auth: AuthMiddleware, rateLimit: RateLimitMiddleware) {
        let download = app.grouped("api", "download").grouped(auth).grouped(rateLimit)
        let downloadZip = app.grouped("api", "download-zip").grouped(auth).grouped(rateLimit)

        // Single file download
        download.get("**") { req -> Response in
            let relativePath = req.parameters.getCatchall().joined(separator: "/")
            let session = try req.userSession

            let filePath = (session.scopePath as NSString).appendingPathComponent(relativePath)
            let resolved = (filePath as NSString).standardizingPath
            let scope = (session.scopePath as NSString).standardizingPath
            guard resolved == scope || resolved.hasPrefix(scope + "/") else {
                throw Abort(.forbidden, reason: "Access denied — path outside scope")
            }

            guard FileManager.default.fileExists(atPath: resolved) else {
                throw Abort(.notFound, reason: "File not found")
            }
            guard !self.isSymbolicLink(atPath: resolved) else {
                throw Abort(.forbidden, reason: "Access denied — symbolic links are not followed")
            }

            let fileName = (resolved as NSString).lastPathComponent
            let response = req.fileio.streamFile(at: resolved)
            response.headers.replaceOrAdd(
                name: .contentDisposition,
                value: self.sanitizeHeaderFilename(fileName)
            )
            // Enable resumable downloads
            response.headers.replaceOrAdd(name: .init("Accept-Ranges"), value: "bytes")
            if let attrs = try? FileManager.default.attributesOfItem(atPath: resolved) {
                let size = (attrs[.size] as? Int64) ?? 0
                response.headers.replaceOrAdd(name: .contentLength, value: String(size))
                self.transferStats.recordDownload(bytes: size)
            }
            self.onNotification?("File downloaded", fileName)
            self.accessLogger.log(ip: self.extractClientIP(from: req), action: .download, tokenId: session.token, detail: fileName)
            self.webSocketManager.broadcastActivity(action: "downloaded", detail: fileName)

            return response
        }

        // ZIP download
        downloadZip.get("**") { req -> Response in
            let relativePath = req.parameters.getCatchall().joined(separator: "/")
            let session = try req.userSession

            let dirPath = (session.scopePath as NSString).appendingPathComponent(relativePath)
            let resolved = (dirPath as NSString).standardizingPath
            let scope = (session.scopePath as NSString).standardizingPath
            guard resolved == scope || resolved.hasPrefix(scope + "/") else {
                throw Abort(.forbidden, reason: "Access denied — path outside scope")
            }

            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: resolved, isDirectory: &isDir), isDir.boolValue else {
                throw Abort(.notFound, reason: "Directory not found")
            }
            guard !self.isSymbolicLink(atPath: resolved) else {
                throw Abort(.forbidden, reason: "Access denied — symbolic links are not followed")
            }

            // Create ZIP in temp
            let zipName = (resolved as NSString).lastPathComponent + ".zip"
            let tempZip = NSTemporaryDirectory() + UUID().uuidString + ".zip"

            try FileUtils.createZip(from: resolved, to: tempZip)

            let response = req.fileio.streamFile(at: tempZip)
            response.headers.replaceOrAdd(
                name: .contentDisposition,
                value: self.sanitizeHeaderFilename(zipName)
            )
            response.headers.contentType = .init(type: "application", subType: "zip")

            // Defer cleanup to periodic temp-file reaper
            self.scheduleTempCleanup(tempZip)

            return response
        }
    }

    // MARK: - Preview Routes

    private func registerPreviewRoutes(app: Application, auth: AuthMiddleware, rateLimit: RateLimitMiddleware) {
        let preview = app.grouped("api", "preview").grouped(auth).grouped(rateLimit)

        preview.get("**") { req -> Response in
            let relativePath = req.parameters.getCatchall().joined(separator: "/")
            let session = try req.userSession

            let filePath = (session.scopePath as NSString).appendingPathComponent(relativePath)
            let resolved = (filePath as NSString).standardizingPath
            let scope = (session.scopePath as NSString).standardizingPath
            guard resolved == scope || resolved.hasPrefix(scope + "/") else {
                throw Abort(.forbidden, reason: "Access denied — path outside scope")
            }

            guard FileManager.default.fileExists(atPath: resolved) else {
                throw Abort(.notFound, reason: "File not found")
            }
            guard !self.isSymbolicLink(atPath: resolved) else {
                throw Abort(.forbidden, reason: "Access denied — symbolic links are not followed")
            }

            let mime = FileUtils.mimeType(for: resolved)

            // Text files: return JSON with content
            if mime.hasPrefix("text/") || FileUtils.isTextFile(resolved) {
                let attrs = try FileManager.default.attributesOfItem(atPath: resolved)
                let totalSize = attrs[.size] as? Int ?? 0
                let maxBytes = Config.maxPreviewBytes

                // Read only the first maxBytes+1 to detect truncation without loading entire file
                let fileHandle = try FileHandle(forReadingFrom: URL(fileURLWithPath: resolved))
                defer { try? fileHandle.close() }
                let rawData = fileHandle.readData(ofLength: maxBytes + 1)
                let truncated = rawData.count > maxBytes
                let previewData = truncated ? rawData.prefix(maxBytes) : rawData
                let content = String(data: previewData, encoding: .utf8) ?? ""

                let result: [String: Any] = [
                    "type": "text",
                    "content": content,
                    "truncated": truncated,
                    "totalSize": totalSize,
                ]
                let jsonData = try JSONSerialization.data(withJSONObject: result)
                let response = Response(status: .ok)
                response.headers.contentType = .json
                response.body = .init(data: jsonData)
                return response
            }

            // Binary files (images, video, audio, PDF): stream inline via Vapor's file streaming
            let response = req.fileio.streamFile(at: resolved)
            response.headers.replaceOrAdd(name: .contentType, value: mime)
            response.headers.replaceOrAdd(name: .contentDisposition, value: "inline")
            // Enable byte-range requests for video/audio seeking
            // (Vapor's FileIO already sets Content-Length correctly, including for 206 Partial Content)
            if mime.hasPrefix("video/") || mime.hasPrefix("audio/") {
                response.headers.replaceOrAdd(name: .init("Accept-Ranges"), value: "bytes")
            }
            return response
        }
    }

    // MARK: - Write Routes

    private func registerWriteRoutes(app: Application, auth: AuthMiddleware, writeGuard: WritePermissionMiddleware, rateLimit: RateLimitMiddleware) {
        let authWrite = app.grouped(auth).grouped(writeGuard).grouped(rateLimit)

        // POST /api/upload/** — file upload
        authWrite.on(.POST, "api", "upload", "**", body: .collect(maxSize: "100mb")) { req -> Response in
            let relativePath = req.parameters.getCatchall().joined(separator: "/")
            let session = try req.userSession

            let targetDir = relativePath.isEmpty
                ? session.scopePath
                : (session.scopePath as NSString).appendingPathComponent(relativePath)
            let resolved = (targetDir as NSString).standardizingPath
            let scope = (session.scopePath as NSString).standardizingPath
            guard resolved == scope || resolved.hasPrefix(scope + "/") else {
                throw Abort(.forbidden, reason: "Access denied — path outside scope")
            }

            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: resolved, isDirectory: &isDir), isDir.boolValue else {
                throw Abort(.notFound, reason: "Target directory not found")
            }
            guard !self.isSymbolicLink(atPath: resolved) else {
                throw Abort(.forbidden, reason: "Access denied — symbolic links are not followed")
            }

            // Parse multipart upload
            var results: [[String: Any]] = []

            if let body = req.body.data {
                // Simple single-file upload via raw body
                let rawFilename = req.headers.first(name: "X-Filename") ?? "uploaded_file"
                let safeFilename = (rawFilename as NSString).lastPathComponent
                let destPath = (resolved as NSString).appendingPathComponent(safeFilename)
                try Data(buffer: body).write(to: URL(fileURLWithPath: destPath))
                results.append(["name": safeFilename, "size": body.readableBytes, "status": "ok"])
            }

            // Try multipart parsing
            if let contentType = req.headers.contentType,
               contentType.type == "multipart" {
                let files = try req.content.decode([String: [File]].self)
                for (_, fileList) in files {
                    for file in fileList {
                        let safeName = (file.filename as NSString).lastPathComponent
                        let destPath = (resolved as NSString).appendingPathComponent(safeName)
                        try Data(buffer: file.data).write(to: URL(fileURLWithPath: destPath))
                        results.append(["name": safeName, "size": file.data.readableBytes, "status": "ok"])
                    }
                }
            }

            let responseData: [String: Any] = [
                "uploaded": results.count,
                "files": results,
            ]
            let jsonData = try JSONSerialization.data(withJSONObject: responseData)
            let response = Response(status: .ok)
            response.headers.contentType = .json
            response.body = .init(data: jsonData)

            // Track transfer + broadcast refresh
            let totalBytes = results.reduce(Int64(0)) { $0 + (($1["size"] as? Int64) ?? Int64($1["size"] as? Int ?? 0)) }
            self.transferStats.recordUpload(bytes: totalBytes)
            self.webSocketManager.broadcastRefresh()
            for file in results {
                if let name = file["name"] as? String {
                    self.accessLogger.log(ip: self.extractClientIP(from: req), action: .upload, tokenId: session.token, detail: name)
                }
            }

            return response
        }

        // POST /api/mkdir/** — create directory
        authWrite.post("api", "mkdir", "**") { req -> [String: String] in
            let relativePath = req.parameters.getCatchall().joined(separator: "/")
            let session = try req.userSession

            struct MkdirBody: Content { var name: String }
            let body = try req.content.decode(MkdirBody.self)

            let parentDir = relativePath.isEmpty
                ? session.scopePath
                : (session.scopePath as NSString).appendingPathComponent(relativePath)
            let resolved = (parentDir as NSString).standardizingPath
            let scope = (session.scopePath as NSString).standardizingPath
            guard resolved == scope || resolved.hasPrefix(scope + "/") else {
                throw Abort(.forbidden, reason: "Access denied — path outside scope")
            }

            let newDir = (resolved as NSString).appendingPathComponent(body.name)
            guard newDir.hasPrefix(scope) else {
                throw Abort(.forbidden, reason: "Access denied — path outside scope")
            }

            if FileManager.default.fileExists(atPath: newDir) {
                throw Abort(.conflict, reason: "Folder already exists")
            }

            try FileManager.default.createDirectory(atPath: newDir, withIntermediateDirectories: false)
            self.webSocketManager.broadcastRefresh()
            return ["created": body.name, "path": newDir]
        }

        // PUT /api/rename/** — rename file/folder
        authWrite.put("api", "rename", "**") { req -> [String: String] in
            let relativePath = req.parameters.getCatchall().joined(separator: "/")
            let session = try req.userSession

            struct RenameBody: Content { var newName: String }
            let body = try req.content.decode(RenameBody.self)

            let oldPath = (session.scopePath as NSString).appendingPathComponent(relativePath)
            let resolved = (oldPath as NSString).standardizingPath
            let scope = (session.scopePath as NSString).standardizingPath
            guard resolved == scope || resolved.hasPrefix(scope + "/") else {
                throw Abort(.forbidden, reason: "Access denied — path outside scope")
            }

            guard FileManager.default.fileExists(atPath: resolved) else {
                throw Abort(.notFound, reason: "File or folder not found")
            }
            guard !self.isSymbolicLink(atPath: resolved) else {
                throw Abort(.forbidden, reason: "Access denied — symbolic links are not followed")
            }

            let parentDir = (resolved as NSString).deletingLastPathComponent
            let newPath = (parentDir as NSString).appendingPathComponent(body.newName)
            guard newPath.hasPrefix(scope) else {
                throw Abort(.forbidden, reason: "Access denied — path outside scope")
            }

            if FileManager.default.fileExists(atPath: newPath) {
                throw Abort(.conflict, reason: "A file or folder with that name already exists")
            }

            try FileManager.default.moveItem(atPath: resolved, toPath: newPath)
            self.webSocketManager.broadcastRefresh()
            return ["renamed": body.newName, "oldName": (resolved as NSString).lastPathComponent]
        }

        // DELETE /api/delete/** — delete file/folder
        authWrite.delete("api", "delete", "**") { req -> Response in
            let relativePath = req.parameters.getCatchall().joined(separator: "/")
            let session = try req.userSession

            let targetPath = (session.scopePath as NSString).appendingPathComponent(relativePath)
            let resolved = (targetPath as NSString).standardizingPath
            let scope = (session.scopePath as NSString).standardizingPath
            guard resolved != scope else {
                throw Abort(.forbidden, reason: "Cannot delete the shared root folder")
            }
            guard resolved.hasPrefix(scope + "/") else {
                throw Abort(.forbidden, reason: "Access denied — path outside scope")
            }

            guard FileManager.default.fileExists(atPath: resolved) else {
                throw Abort(.notFound, reason: "File or folder not found")
            }
            guard !self.isSymbolicLink(atPath: resolved) else {
                throw Abort(.forbidden, reason: "Access denied — symbolic links are not followed")
            }

            var isDir: ObjCBool = false
            FileManager.default.fileExists(atPath: resolved, isDirectory: &isDir)
            try FileManager.default.removeItem(atPath: resolved)

            self.webSocketManager.broadcastRefresh()

            let result: [String: Any] = ["deleted": (resolved as NSString).lastPathComponent, "wasDirectory": isDir.boolValue]
            let jsonData = try JSONSerialization.data(withJSONObject: result)
            let response = Response(status: .ok)
            response.headers.contentType = .json
            response.body = .init(data: jsonData)
            return response
        }
    }

    // MARK: - Helpers

    /// Escape a filename for use in a Content-Disposition header per RFC 6266.
    private func sanitizeHeaderFilename(_ name: String) -> String {
        let escaped = name.replacingOccurrences(of: "\\", with: "\\\\")
                         .replacingOccurrences(of: "\"", with: "\\\"")
        return "attachment; filename=\"\(escaped)\""
    }

    /// Check if a path is a symbolic link (without following it).
    private func isSymbolicLink(atPath path: String) -> Bool {
        (try? URL(fileURLWithPath: path).resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) ?? false
    }

    /// Extract the real client IP, accounting for Cloudflare tunnel headers.
    private func extractClientIP(from request: Request) -> String {
        if let cfIP = request.headers.first(name: "CF-Connecting-IP") {
            return cfIP
        }
        if let forwarded = request.headers.first(name: "X-Forwarded-For") {
            return forwarded.split(separator: ",").first.map(String.init)?.trimmingCharacters(in: .whitespaces) ?? "unknown"
        }
        return request.remoteAddress?.ipAddress ?? "unknown"
    }
}
