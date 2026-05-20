import Foundation

/// An active browser session.
struct Session: Identifiable, Codable {
    let id: String           // sessionId
    let token: String        // originating token
    let scopePath: String
    let permissions: String  // "read" or "readwrite"
    let createdAt: Date
    var lastActive: Date

    var isExpired: Bool {
        Date().timeIntervalSince(lastActive) > Config.sessionTTLSeconds
    }

    var connectedDuration: String {
        let elapsed = Date().timeIntervalSince(createdAt)
        let minutes = Int(elapsed / 60)
        if minutes < 1 { return "Just now" }
        if minutes < 60 { return "\(minutes)m ago" }
        return "\(minutes / 60)h \(minutes % 60)m ago"
    }

    var lastActiveDuration: String {
        let elapsed = Date().timeIntervalSince(lastActive)
        let minutes = Int(elapsed / 60)
        if minutes < 1 { return "Just now" }
        if minutes < 60 { return "\(minutes)m ago" }
        return "\(minutes / 60)h \(minutes % 60)m ago"
    }
}
