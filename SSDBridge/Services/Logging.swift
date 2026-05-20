import os

/// Structured loggers for the app. Output appears in Console.app under the
/// "com.ssdbridge" subsystem, filterable by category.
enum Log {
    private static let subsystem = "com.ssdbridge"

    static let server = Logger(subsystem: subsystem, category: "server")
    static let upload = Logger(subsystem: subsystem, category: "upload")
    static let network = Logger(subsystem: subsystem, category: "network")
    static let auth = Logger(subsystem: subsystem, category: "auth")
    static let file = Logger(subsystem: subsystem, category: "file")
    static let ws = Logger(subsystem: subsystem, category: "websocket")
    static let tunnel = Logger(subsystem: subsystem, category: "tunnel")
    static let general = Logger(subsystem: subsystem, category: "general")
}
