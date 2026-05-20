import Vapor
import Foundation

/// IP-based rate limiting middleware.
/// Tracks request counts per IP within a sliding time window and returns
/// HTTP 429 (Too Many Requests) when the limit is exceeded.
final class RateLimitMiddleware: AsyncMiddleware, @unchecked Sendable {
    private let maxRequests: Int
    private let windowSeconds: TimeInterval
    private var requests: [String: [Date]] = [:]
    private let lock = NSLock()

    /// - Parameters:
    ///   - maxRequests: Maximum allowed requests per IP within the window.
    ///   - windowSeconds: Time window in seconds.
    init(maxRequests: Int = 5, windowSeconds: TimeInterval = 60) {
        self.maxRequests = maxRequests
        self.windowSeconds = windowSeconds
    }

    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let ip = clientIP(from: request)
        let now = Date()

        let isAllowed = lock.withLock { () -> Bool in
            // Clean old entries for this IP
            var timestamps = requests[ip, default: []]
            timestamps = timestamps.filter { now.timeIntervalSince($0) < windowSeconds }

            if timestamps.count >= maxRequests {
                requests[ip] = timestamps
                return false
            }

            timestamps.append(now)
            requests[ip] = timestamps
            return true
        }

        guard isAllowed else {
            let response = Response(status: .tooManyRequests)
            response.headers.contentType = .json
            response.headers.replaceOrAdd(
                name: "Retry-After",
                value: "\(Int(windowSeconds))"
            )
            response.body = .init(string: """
            {"error":"rate_limited","message":"Too many requests. Try again in \\(Int(windowSeconds)) seconds."}
            """)
            Log.auth.warning("Rate limited IP: \(ip)")
            return response
        }

        return try await next.respond(to: request)
    }

    /// Extract client IP, accounting for Cloudflare tunnel proxy headers.
    private func clientIP(from request: Request) -> String {
        // Cloudflare sets CF-Connecting-IP for the real client IP
        if let cfIP = request.headers.first(name: "CF-Connecting-IP") {
            return cfIP
        }
        // Standard proxy header
        if let forwarded = request.headers.first(name: "X-Forwarded-For") {
            return forwarded.split(separator: ",").first.map(String.init)?.trimmingCharacters(in: .whitespaces) ?? "unknown"
        }
        // Direct connection
        return request.remoteAddress?.ipAddress ?? "unknown"
    }

    /// Periodically clean up stale entries (call from a timer if desired).
    func cleanup() {
        let now = Date()
        lock.withLock {
            for (ip, timestamps) in requests {
                let active = timestamps.filter { now.timeIntervalSince($0) < windowSeconds }
                if active.isEmpty {
                    requests.removeValue(forKey: ip)
                } else {
                    requests[ip] = active
                }
            }
        }
    }
}
