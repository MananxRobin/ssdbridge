import Foundation
import CryptoKit

/// Manages magic link tokens — creation, validation, password checking, revocation.
final class TokenManager: @unchecked Sendable {
    private var tokens: [String: Token] = [:]
    private let lock = NSLock()

    // MARK: - Token Generation

    /// Generate a random alphanumeric string for token IDs.
    private func generateId(length: Int = Config.tokenLength) -> String {
        let chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-"
        return String((0..<length).map { _ in chars.randomElement()! })
    }

    private static let passwordIterations = 100_000

    /// Hash a password using salted, iterated SHA-256.
    /// Output format: `iterations:salt:hash` (all lowercase hex).
    private func hashPassword(_ password: String) -> String {
        let salt = SymmetricKey(size: .bits128).withUnsafeBytes { Data($0) }
        let hash = Self.deriveKey(password: password, salt: salt, iterations: Self.passwordIterations)
        let iterHex = String(Self.passwordIterations, radix: 16)
        return "\(iterHex):\(salt.hexEncoded):\(hash.hexEncoded)"
    }

    /// Legacy raw SHA-256 (no salt, no iterations). Used for backward compat.
    private func hashLegacy(_ password: String) -> String {
        let data = Data(password.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// Iterated SHA-256 key derivation.
    private static func deriveKey(password: String, salt: Data, iterations: Int) -> Data {
        let passwordData = Data(password.utf8)
        var hash = passwordData + salt
        for _ in 0..<iterations {
            hash = Data(SHA256.hash(data: hash))
        }
        return hash
    }

    // MARK: - CRUD

    func createToken(
        scopePath: String,
        ttlMinutes: Int = Config.defaultTTLMinutes,
        oneTimeJoin: Bool = false,
        password: String? = nil,
        permissions: String = "read",
        encrypted: Bool = false
    ) -> Token {
        let id = generateId()
        let now = Date()
        let ttl = TimeInterval(ttlMinutes * 60)

        let token = Token(
            id: id,
            scopePath: scopePath,
            createdAt: now,
            expiresAt: now.addingTimeInterval(ttl),
            oneTimeJoin: oneTimeJoin,
            used: false,
            passwordHash: password.map { hashPassword($0) },
            hasPassword: password != nil && !password!.isEmpty,
            permissions: permissions,
            encrypted: encrypted
        )

        lock.lock()
        tokens[id] = token
        lock.unlock()

        return token
    }

    func validateToken(_ tokenId: String) -> Token? {
        lock.lock()
        defer { lock.unlock() }

        guard var token = tokens[tokenId] else { return nil }
        if token.isExpired {
            tokens.removeValue(forKey: tokenId)
            return nil
        }
        if token.oneTimeJoin && token.used { return nil }
        return token
    }

    func checkPassword(token: Token, password: String?) -> Bool {
        guard let storedHash = token.passwordHash else { return true } // no password needed
        guard let pwd = password, !pwd.isEmpty else { return false }

        // Detect format: "iterations:salt:hash" (new) vs raw hex (legacy)
        let parts = storedHash.split(separator: ":")
        if parts.count == 3,
           let iterations = Int(parts[0], radix: 16),
           let saltData = Data(hexEncoded: String(parts[1])) {
            // New salted/iterated format
            let derived = Self.deriveKey(password: pwd, salt: saltData, iterations: iterations)
            return derived.hexEncoded == String(parts[2])
        }

        // Legacy raw SHA-256
        return storedHash == hashLegacy(pwd)
    }

    func markUsed(_ tokenId: String) {
        lock.lock()
        tokens[tokenId]?.used = true
        lock.unlock()
    }

    func revokeToken(_ tokenId: String) {
        lock.lock()
        tokens.removeValue(forKey: tokenId)
        lock.unlock()
    }

    func listTokens() -> [Token] {
        lock.lock()
        defer { lock.unlock() }

        let now = Date()
        // Clean expired tokens
        tokens = tokens.filter { !$0.value.isExpired }
        return Array(tokens.values).sorted { $0.createdAt > $1.createdAt }
    }
}

private extension Data {
    var hexEncoded: String {
        map { String(format: "%02x", $0) }.joined()
    }

    init?(hexEncoded: String) {
        guard hexEncoded.count.isMultiple(of: 2) else { return nil }
        let chars = Array(hexEncoded)
        var bytes = [UInt8]()
        bytes.reserveCapacity(chars.count / 2)
        for i in stride(from: 0, to: chars.count, by: 2) {
            guard let byte = UInt8(String(chars[i...i+1]), radix: 16) else { return nil }
            bytes.append(byte)
        }
        self = Data(bytes)
    }
}
