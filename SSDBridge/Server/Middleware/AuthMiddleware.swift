import Vapor

/// Vapor middleware that validates session tokens from Authorization header or query param.
struct AuthMiddleware: AsyncMiddleware {
    let sessionManager: SessionManager

    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        var sessionId: String?

        // Try Authorization: Bearer <sessionId> header first
        if let auth = request.headers.first(name: .authorization),
           auth.hasPrefix("Bearer ") {
            sessionId = String(auth.dropFirst(7))
        }

        // Fallback to ?token= query param (for <a>, <img>, <video> tags)
        if sessionId == nil {
            sessionId = request.query[String.self, at: "token"]
        }

        guard let sid = sessionId else {
            throw Abort(.unauthorized, reason: "Missing or invalid Authorization header")
        }

        guard let session = sessionManager.getSession(sid) else {
            throw Abort(.unauthorized, reason: "Session expired or invalid")
        }

        // Store session in request storage for route handlers
        request.storage[SessionKey.self] = session
        return try await next.respond(to: request)
    }
}

/// Storage key for the session on the request.
struct SessionKey: StorageKey {
    typealias Value = Session
}

/// Convenience extension to access the session from a request.
extension Request {
    var userSession: Session {
        get throws {
            guard let session = storage[SessionKey.self] else {
                throw Abort(.internalServerError, reason: "Session not found in request storage — AuthMiddleware may not be configured")
            }
            return session
        }
    }

    var userSessionOptional: Session? {
        get { storage[SessionKey.self] }
    }
}

/// Middleware that requires write permissions.
struct WritePermissionMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard request.userSessionOptional?.permissions == "readwrite" else {
            throw Abort(.forbidden, reason: "Write permission denied — this link is read-only")
        }
        return try await next.respond(to: request)
    }
}
