import Foundation

/// A saved link configuration for one-click sharing.
struct LinkPreset: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var name: String
    var scopePath: String
    var ttlMinutes: Int
    var oneTimeJoin: Bool
    var password: String?
    var permissions: String  // "read" or "readwrite"
    var encrypted: Bool
}
