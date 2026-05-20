import Foundation

/// Manages active browser sessions — creation, validation, cleanup, revocation.
final class SessionManager: @unchecked Sendable {
    private var sessions: [String: Session] = [:]
    private let lock = NSLock()
    private var cleanupTimer: Timer?

    // MARK: - Session CRUD

    func createSession(token: String, scopePath: String, permissions: String = "read") -> Session {
        let sessionId = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(32)
        let now = Date()

        let session = Session(
            id: String(sessionId),
            token: token,
            scopePath: scopePath,
            permissions: permissions,
            createdAt: now,
            lastActive: now
        )

        lock.lock()
        sessions[session.id] = session
        lock.unlock()

        return session
    }

    func getSession(_ sessionId: String) -> Session? {
        lock.lock()
        defer { lock.unlock() }

        guard var session = sessions[sessionId] else { return nil }

        if session.isExpired {
            sessions.removeValue(forKey: sessionId)
            return nil
        }

        // Refresh activity
        session.lastActive = Date()
        sessions[sessionId] = session
        return session
    }

    func revokeSession(_ sessionId: String) {
        lock.lock()
        sessions.removeValue(forKey: sessionId)
        lock.unlock()
    }

    func listSessions() -> [Session] {
        lock.lock()
        defer { lock.unlock() }

        // Clean expired
        sessions = sessions.filter { !$0.value.isExpired }
        return Array(sessions.values).sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - Cleanup Timer

    func startCleanupTimer() {
        DispatchQueue.main.async { [weak self] in
            self?.cleanupTimer = Timer.scheduledTimer(
                withTimeInterval: Config.sessionCleanupInterval,
                repeats: true
            ) { [weak self] _ in
                self?.cleanup()
            }
        }
    }

    func stopCleanupTimer() {
        cleanupTimer?.invalidate()
        cleanupTimer = nil
    }

    private func cleanup() {
        lock.lock()
        let before = sessions.count
        sessions = sessions.filter { !$0.value.isExpired }
        let removed = before - sessions.count
        lock.unlock()

        if removed > 0 {
            Log.auth.info("Cleaned up \(removed) expired session(s)")
        }
    }
}
