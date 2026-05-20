import SwiftUI
import Combine
import UserNotifications

/// Central observable state for the entire app.
@MainActor
final class AppState: ObservableObject {
    // Server state
    @Published var isServerRunning = false
    @Published var serverPort: Int = {
        let stored = UserDefaults.standard.integer(forKey: "serverPort")
        return stored > 0 ? stored : 3001
    }() {
        didSet {
            UserDefaults.standard.set(serverPort, forKey: "serverPort")
        }
    }
    @Published var serverError: String?

    // Tunnel state
    @Published var tunnelState: TunnelManager.TunnelState = .disconnected

    // Data
    @Published var activeLinks: [Token] = []
    @Published var activeSessions: [Session] = []

    // Managers
    let tokenManager = TokenManager()
    let sessionManager = SessionManager()
    let driveWatcher = DriveWatcher()
    let tunnelManager = TunnelManager()
    let accessLogger = AccessLogger()
    let webSocketManager = WebSocketManager()
    let transferStats = TransferStats()
    let chunkedUploadManager = ChunkedUploadManager()
    private var serverManager: ServerManager?
    private var refreshTimer: AnyCancellable?
    private var tunnelSink: AnyCancellable?

    // Settings
    @Published var notificationsEnabled: Bool = UserDefaults.standard.bool(forKey: "notificationsEnabled")

    // Presets
    @Published var linkPresets: [LinkPreset] = {
        guard let data = UserDefaults.standard.data(forKey: "linkPresets") else { return [] }
        return (try? JSONDecoder().decode([LinkPreset].self, from: data)) ?? []
    }() {
        didSet {
            if let data = try? JSONEncoder().encode(linkPresets) {
                UserDefaults.standard.set(data, forKey: "linkPresets")
            }
        }
    }

    init() {
        // Start periodic refresh of links/sessions
        refreshTimer = Timer.publish(every: 3, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshData()
            }

        // Forward tunnel state changes
        tunnelSink = tunnelManager.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newState in
                self?.tunnelState = newState
                // Update ServerManager's tunnel URL
                if let url = newState.publicURL {
                    self?.serverManager?.tunnelURL = url
                } else {
                    self?.serverManager?.tunnelURL = nil
                }
            }

        // Request notification permission (deferred to avoid bundle crash)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.requestNotificationPermission()
        }
    }

    // MARK: - Server Control

    func startServer() {
        guard !isServerRunning else { return }
        serverError = nil

        Task {
            do {
                let manager = ServerManager(
                    port: serverPort,
                    tokenManager: tokenManager,
                    sessionManager: sessionManager,
                    driveWatcher: driveWatcher,
                    accessLogger: accessLogger,
                    webSocketManager: webSocketManager,
                    transferStats: transferStats,
                    chunkedUploadManager: chunkedUploadManager
                )
                try await manager.start()
                self.serverManager = manager
                manager.onNotification = { [weak self] title, body in
                    self?.sendNotification(title: title, body: body)
                }
                self.isServerRunning = true
                self.driveWatcher.startWatching()
                self.sessionManager.startCleanupTimer()
                Log.server.info("Server started on port \(self.serverPort)")
            } catch {
                self.serverError = error.localizedDescription
                Log.server.error("Server failed: \(error)")
            }
        }
    }

    func stopServer() {
        stopTunnel()
        serverManager?.stop()
        serverManager = nil
        isServerRunning = false
        driveWatcher.stopWatching()
        Log.server.info("Server stopped")
    }

    // MARK: - Tunnel Control

    func startTunnel() {
        guard isServerRunning else { return }
        tunnelManager.start(port: serverPort)
    }

    func stopTunnel() {
        tunnelManager.stop()
    }

    /// Whether cloudflared is available on this machine.
    var isTunnelAvailable: Bool {
        TunnelManager.isInstalled
    }

    // MARK: - Data

    func refreshData() {
        activeLinks = tokenManager.listTokens()
        activeSessions = sessionManager.listSessions()
    }

    // MARK: - Link Management

    func createLink(scopePath: String, ttlMinutes: Int, oneTimeJoin: Bool, password: String?, permissions: String, encrypted: Bool = false) -> Token {
        let token = tokenManager.createToken(
            scopePath: scopePath,
            ttlMinutes: ttlMinutes,
            oneTimeJoin: oneTimeJoin,
            password: password,
            permissions: permissions,
            encrypted: encrypted
        )
        refreshData()
        return token
    }

    func revokeLink(tokenId: String) {
        tokenManager.revokeToken(tokenId)
        refreshData()
    }

    func terminateSession(sessionId: String) {
        sessionManager.revokeSession(sessionId)
        refreshData()
    }

    /// Build the full magic link URL.
    /// Uses the global tunnel URL when connected, otherwise falls back to LAN IP.
    func buildLinkURL(token: Token) -> String {
        if let tunnelURL = tunnelState.publicURL {
            return "\(tunnelURL)/join/\(token.id)"
        }
        let ip = NetworkUtils.getLocalIP()
        return "http://\(ip):\(serverPort)/join/\(token.id)"
    }

    /// Whether the current link URL is a global (tunnel) link.
    var isGlobalLinkMode: Bool {
        tunnelState.isConnected
    }

    // MARK: - Notifications

    private func requestNotificationPermission() {
        guard Bundle.main.bundleIdentifier != nil else {
            Log.general.warning("Skipping notification setup — no bundle identifier")
            return
        }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                Log.general.warning("Notification permission error: \(error)")
            }
            let msg = granted ? "Notifications enabled" : "Notifications denied"
            Log.general.info("\(msg)")
        }
    }

    func sendNotification(title: String, body: String) {
        guard notificationsEnabled,
              Bundle.main.bundleIdentifier != nil else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    func toggleNotifications(_ enabled: Bool) {
        notificationsEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "notificationsEnabled")
    }

    // MARK: - Presets

    func savePreset(_ preset: LinkPreset) {
        if let idx = linkPresets.firstIndex(where: { $0.id == preset.id }) {
            linkPresets[idx] = preset
        } else {
            linkPresets.append(preset)
        }
    }

    func deletePreset(_ preset: LinkPreset) {
        linkPresets.removeAll { $0.id == preset.id }
    }
}

