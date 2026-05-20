import Foundation

/// Server configuration constants.
struct Config {
    static let defaultPort = 3001
    static let defaultHost = "0.0.0.0"
    static let tokenLength = 21
    static let defaultTTLMinutes = 15
    static let sessionTTLSeconds: TimeInterval = 3600 // 1 hour inactivity
    static let sessionCleanupInterval: TimeInterval = 60
    static let maxPreviewBytes = 512 * 1024 // 512 KB for text previews
    static let corsOrigins = ["*"]
}
