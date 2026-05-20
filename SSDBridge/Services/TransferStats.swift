import Foundation

/// Tracks transfer statistics — bytes downloaded/uploaded, counts, and live bandwidth.
final class TransferStats: ObservableObject, @unchecked Sendable {
    // MARK: - Published State

    @Published var totalBytesDownloaded: Int64 = 0
    @Published var totalBytesUploaded: Int64 = 0
    @Published var totalDownloads: Int = 0
    @Published var totalUploads: Int = 0
    @Published var currentBytesPerSecond: Double = 0

    // MARK: - Private

    private let lock = NSLock()
    private var recentTransfers: [(timestamp: Date, bytes: Int64)] = []
    private var bandwidthTimer: Timer?

    init() {
        // Update bandwidth reading every second
        DispatchQueue.main.async {
            self.bandwidthTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.updateBandwidth()
            }
        }
    }

    deinit {
        bandwidthTimer?.invalidate()
    }

    // MARK: - Recording

    func recordDownload(bytes: Int64) {
        let now = Date()
        lock.lock()
        totalBytesDownloaded += bytes
        totalDownloads += 1
        recentTransfers.append((timestamp: now, bytes: bytes))
        lock.unlock()

        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }

    func recordUpload(bytes: Int64) {
        let now = Date()
        lock.lock()
        totalBytesUploaded += bytes
        totalUploads += 1
        recentTransfers.append((timestamp: now, bytes: bytes))
        lock.unlock()

        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }

    // MARK: - Bandwidth

    private func updateBandwidth() {
        let now = Date()
        let windowSeconds: TimeInterval = 5

        lock.lock()
        // Remove entries older than the window
        recentTransfers = recentTransfers.filter { now.timeIntervalSince($0.timestamp) < windowSeconds }
        let totalBytes = recentTransfers.reduce(Int64(0)) { $0 + $1.bytes }
        lock.unlock()

        let bps = Double(totalBytes) / windowSeconds
        DispatchQueue.main.async {
            self.currentBytesPerSecond = bps
        }
    }

    // MARK: - Formatting

    var downloadFormatted: String { formatBytes(totalBytesDownloaded) }
    var uploadFormatted: String { formatBytes(totalBytesUploaded) }
    var bandwidthFormatted: String { formatBytes(Int64(currentBytesPerSecond)) + "/s" }

    var totalTransferFormatted: String {
        formatBytes(totalBytesDownloaded + totalBytesUploaded)
    }

    private func formatBytes(_ bytes: Int64) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        let kb = Double(bytes) / 1024
        if kb < 1024 { return String(format: "%.1f KB", kb) }
        let mb = kb / 1024
        if mb < 1024 { return String(format: "%.1f MB", mb) }
        let gb = mb / 1024
        return String(format: "%.2f GB", gb)
    }

    /// Reset all stats.
    func reset() {
        lock.lock()
        totalBytesDownloaded = 0
        totalBytesUploaded = 0
        totalDownloads = 0
        totalUploads = 0
        recentTransfers.removeAll()
        lock.unlock()

        DispatchQueue.main.async {
            self.currentBytesPerSecond = 0
            self.objectWillChange.send()
        }
    }
}
