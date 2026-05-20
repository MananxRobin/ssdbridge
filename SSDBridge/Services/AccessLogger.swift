import Foundation

/// Records and publishes access events for the dashboard.
final class AccessLogger: ObservableObject, @unchecked Sendable {

    /// A single access event.
    struct AccessEvent: Identifiable {
        let id = UUID()
        let timestamp: Date
        let ip: String
        let action: Action
        let tokenId: String
        let detail: String?

        enum Action: String, CaseIterable {
            case joinSuccess = "join_success"
            case joinFailed = "join_failed"
            case joinRateLimited = "join_rate_limited"
            case passwordFailed = "password_failed"
            case download = "download"
            case upload = "upload"

            var icon: String {
                switch self {
                case .joinSuccess: return "✅"
                case .joinFailed: return "❌"
                case .joinRateLimited: return "🚫"
                case .passwordFailed: return "🔒"
                case .download: return "⬇️"
                case .upload: return "⬆️"
                }
            }

            var label: String {
                switch self {
                case .joinSuccess: return "Joined"
                case .joinFailed: return "Join Failed"
                case .joinRateLimited: return "Rate Limited"
                case .passwordFailed: return "Wrong Password"
                case .download: return "Download"
                case .upload: return "Upload"
                }
            }
        }

        var timeString: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            return formatter.string(from: timestamp)
        }
    }

    // MARK: - Published State

    @Published var events: [AccessEvent] = []

    /// Maximum number of events to retain in memory.
    private let maxEvents = 200
    private let lock = NSLock()

    // MARK: - Logging

    func log(ip: String, action: AccessEvent.Action, tokenId: String, detail: String? = nil) {
        let event = AccessEvent(
            timestamp: Date(),
            ip: ip,
            action: action,
            tokenId: tokenId,
            detail: detail
        )

        let icon = action.icon
        let tokenShort = String(tokenId.prefix(8)) + "…"
        Log.auth.info("[\(event.timeString)] \(action.label) — IP: \(ip), Token: \(tokenShort)\(detail.map { ", \($0)" } ?? "")")

        DispatchQueue.main.async {
            self.events.insert(event, at: 0)
            if self.events.count > self.maxEvents {
                self.events = Array(self.events.prefix(self.maxEvents))
            }
        }
    }

    /// Extract client IP from common proxy headers.
    static func clientIP(headers: [(String, String)], remoteAddress: String?) -> String {
        // Cloudflare sets CF-Connecting-IP
        if let cfIP = headers.first(where: { $0.0 == "CF-Connecting-IP" })?.1 {
            return cfIP
        }
        if let forwarded = headers.first(where: { $0.0 == "X-Forwarded-For" })?.1 {
            return forwarded.split(separator: ",").first.map(String.init)?.trimmingCharacters(in: .whitespaces) ?? "unknown"
        }
        return remoteAddress ?? "unknown"
    }

    /// Clear all logged events.
    func clear() {
        DispatchQueue.main.async {
            self.events.removeAll()
        }
    }

    /// Returns deduplicated recent file access entries (download/upload events).
    func getRecentFiles(limit: Int) -> [[String: Any]] {
        lock.lock()
        defer { lock.unlock() }
        var seen = Set<String>()
        var result: [[String: Any]] = []
        for event in events {
            guard event.action == .download || event.action == .upload else { continue }
            guard let detail = event.detail, !detail.isEmpty else { continue }
            let key = detail
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            result.append([
                "file": detail,
                "action": event.action.rawValue,
                "time": ISO8601DateFormatter().string(from: event.timestamp),
            ])
            if result.count >= limit { break }
        }
        return result
    }
}
