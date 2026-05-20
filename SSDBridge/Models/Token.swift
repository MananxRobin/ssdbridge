import Foundation

/// A magic link token for sharing access.
struct Token: Identifiable, Codable {
    let id: String           // random token string
    let scopePath: String
    let createdAt: Date
    let expiresAt: Date
    let oneTimeJoin: Bool
    var used: Bool
    let passwordHash: String?
    let hasPassword: Bool
    let permissions: String  // "read" or "readwrite"
    let encrypted: Bool      // whether E2E encryption is enabled

    var isExpired: Bool {
        Date() > expiresAt
    }

    var timeRemaining: String {
        let remaining = expiresAt.timeIntervalSinceNow
        if remaining <= 0 { return "Expired" }
        let minutes = Int(remaining / 60)
        if minutes < 60 { return "\(minutes)m" }
        return "\(minutes / 60)h \(minutes % 60)m"
    }
}
