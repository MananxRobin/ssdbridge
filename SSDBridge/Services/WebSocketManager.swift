import Vapor
import Foundation

/// Manages WebSocket connections for real-time file sync.
/// When files change (upload, delete, rename, mkdir), broadcasts a refresh
/// signal to all connected clients so they update their file list.
final class WebSocketManager: @unchecked Sendable {
    private var connections: [String: WebSocket] = [:]  // sessionId → socket
    private let lock = NSLock()

    /// Register a new WebSocket connection for a session.
    func add(sessionId: String, socket: WebSocket) {
        lock.lock()
        // Close existing connection for this session if any
        connections[sessionId]?.close(promise: nil)
        connections[sessionId] = socket
        lock.unlock()

        Log.ws.info("WebSocket connected: \(sessionId.prefix(8))…")

        socket.onClose.whenComplete { [weak self] _ in
            self?.remove(sessionId: sessionId)
        }
    }

    /// Remove a WebSocket connection.
    func remove(sessionId: String) {
        lock.lock()
        connections.removeValue(forKey: sessionId)
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

    /// Number of active WebSocket connections.
    var activeCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return connections.count
    }

    /// Close all connections.
    func closeAll() {
        lock.lock()
        let sockets = Array(connections.values)
        connections.removeAll()
        lock.unlock()

        for socket in sockets {
            socket.close(promise: nil)
        }
    }
}
