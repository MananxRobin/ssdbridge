import Vapor
import Foundation

/// Manages WebSocket connections for real-time file sync and presence awareness.
final class WebSocketManager: @unchecked Sendable {
    private var connections: [String: WebSocket] = [:]
    private var sessionPaths: [String: String] = [:]
    private let lock = NSLock()
    private var colorSeq = 0

    static let presenceColors = ["#d48552", "#4a90c4", "#3d8b7b", "#c7761a", "#8b5ca0"]

    /// Register a new WebSocket connection for a session.
    func add(sessionId: String, socket: WebSocket, scopePath: String = "") {
        lock.lock()
        connections[sessionId]?.close(promise: nil)
        connections[sessionId] = socket
        sessionPaths[sessionId] = ""
        lock.unlock()

        Log.ws.info("WebSocket connected: \(sessionId.prefix(8))…")

        // Setting onText MUST be on the socket's event loop (NIOLoopBoundBox check)
        socket.eventLoop.execute {
            socket.onText { [weak self] _, text in
                self?.handleMessage(sessionId: sessionId, text: text)
            }
        }

        socket.onClose.whenComplete { [weak self] _ in
            self?.remove(sessionId: sessionId)
        }
    }

    /// Remove a WebSocket connection.
    func remove(sessionId: String) {
        lock.lock()
        connections.removeValue(forKey: sessionId)
        sessionPaths.removeValue(forKey: sessionId)
        lock.unlock()
        Log.ws.info("WebSocket disconnected: \(sessionId.prefix(8))…")
    }

    /// Broadcast a file-change refresh signal to all connected clients.
    func broadcastRefresh() {
        lock.lock()
        let sockets = Array(connections.values)
        lock.unlock()

        let message = "{\"type\":\"refresh\"}"
        for socket in sockets {
            socket.send(message)
        }

        if !sockets.isEmpty {
            Log.ws.info("Broadcast refresh to \(sockets.count) client(s)")
        }
    }

    /// Broadcast presence info (guest count + who is viewing what) to all connected clients.
    func broadcastPresence() {
        lock.lock()
        let count = connections.count
        var viewers: [[String: Any]] = []
        for (_, path) in sessionPaths where !path.isEmpty {
            // Determine color for this session (simplified: just use first non-empty path)
            viewers.append(["path": path, "color": Self.presenceColors[0]])
        }
        lock.unlock()

        let payload: [String: Any] = [
            "type": "presence",
            "count": count,
            "viewers": viewers
        ]
        sendJSON(payload)
    }

    /// Broadcast an activity event to all connected clients.
    func broadcastActivity(action: String, detail: String?) {
        var payload: [String: Any] = [
            "type": "activity",
            "action": action
        ]
        if let d = detail { payload["detail"] = d }
        sendJSON(payload)
    }

    /// Number of active WebSocket connections.
    var activeCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return connections.count
    }

    /// List active session IDs with their current viewing paths.
    func activeSessions() -> [(sessionId: String, path: String)] {
        lock.lock()
        defer { lock.unlock() }
        return sessionPaths.map { ($0.key, $0.value) }
    }

    /// List connected session IDs.
    func connectedSessionIds() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return Array(connections.keys)
    }

    /// Beam a file to all connected guests.
    func beamToAll(filename: String, size: Int64, downloadUrls: [String: String]) {
        lock.lock()
        let sockets = connections
        lock.unlock()

        for (sessionId, socket) in sockets {
            guard let url = downloadUrls[sessionId] else { continue }
            let payload: [String: Any] = [
                "type": "beam",
                "filename": filename,
                "size": size,
                "downloadUrl": url
            ]
            guard let jsonData = try? JSONSerialization.data(withJSONObject: payload),
                  let text = String(data: jsonData, encoding: .utf8) else { continue }
            socket.send(text)
        }
    }

    /// Close all connections.
    func closeAll() {
        lock.lock()
        let sockets = Array(connections.values)
        connections.removeAll()
        sessionPaths.removeAll()
        lock.unlock()

        for socket in sockets {
            socket.close(promise: nil)
        }
    }

    // MARK: - Message handling

    private func handleMessage(sessionId: String, text: String) {
        guard let data = text.data(using: .utf8),
              let msg = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = msg["type"] as? String else { return }

        if type == "viewing" {
            let path = msg["path"] as? String ?? ""
            lock.lock()
            sessionPaths[sessionId] = path
            lock.unlock()
        }
    }

    // MARK: - Internal

    private func sendJSON(_ payload: [String: Any]) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload),
              let text = String(data: jsonData, encoding: .utf8) else { return }

        lock.lock()
        let sockets = Array(connections.values)
        lock.unlock()

        for socket in sockets {
            socket.send(text)
        }
    }
}
