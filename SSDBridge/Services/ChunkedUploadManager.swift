import Foundation

/// Manages chunked upload sessions for large file transfers.
/// Each session tracks chunks written to a temp directory and
/// assembles them into the final file on completion.
final class ChunkedUploadManager: @unchecked Sendable {

    /// 10 MB per chunk
    static let defaultChunkSize: Int = 10 * 1024 * 1024

    /// Stale session cleanup interval (24 hours)
    private static let staleTTL: TimeInterval = 86400

    struct UploadSession {
        let id: String
        let filename: String
        let targetDir: String
        let totalSize: Int64
        let chunkSize: Int
        let totalChunks: Int
        var receivedChunks: Set<Int>
        let createdAt: Date
        let sessionId: String            // auth session that owns this

        var isComplete: Bool { receivedChunks.count == totalChunks }
        var progress: Double {
            totalChunks > 0 ? Double(receivedChunks.count) / Double(totalChunks) : 0
        }
    }

    private var sessions: [String: UploadSession] = [:]
    private let lock = NSLock()
    private var cleanupTimer: Timer?

    init() {
        // Schedule periodic cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) { [weak self] in
            self?.startCleanupTimer()
        }
    }

    private func startCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.cleanupStale()
        }
    }

    // MARK: - Session Lifecycle

    /// Creates a new chunked upload session and temp directory.
    func initUpload(filename: String, targetDir: String, totalSize: Int64, chunkSize: Int, totalChunks: Int, sessionId: String) throws -> String {
        let safeFilename = (filename as NSString).lastPathComponent
        let uploadId = UUID().uuidString

        let session = UploadSession(
            id: uploadId,
            filename: safeFilename,
            targetDir: targetDir,
            totalSize: totalSize,
            chunkSize: chunkSize,
            totalChunks: totalChunks,
            receivedChunks: [],
            createdAt: Date(),
            sessionId: sessionId
        )

        lock.lock()
        sessions[uploadId] = session
        lock.unlock()

        // Create temp directory for chunks
        let tempDir = chunkTempDir(for: uploadId)
        try FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)

        Log.upload.info("Chunked upload started: \(safeFilename) (\(totalChunks) chunks, \(self.formatBytes(totalSize)))")
        return uploadId
    }

    /// Writes a single chunk to the temp directory.
    func writeChunk(uploadId: String, index: Int, data: Data) throws {
        lock.lock()
        guard var session = sessions[uploadId] else {
            lock.unlock()
            throw ChunkedUploadError.sessionNotFound
        }
        guard index >= 0 && index < session.totalChunks else {
            lock.unlock()
            throw ChunkedUploadError.invalidChunkIndex
        }
        lock.unlock()

        // Write chunk file
        let chunkPath = chunkFilePath(uploadId: uploadId, index: index)
        try data.write(to: URL(fileURLWithPath: chunkPath))

        // Update received set
        lock.lock()
        sessions[uploadId]?.receivedChunks.insert(index)
        lock.unlock()
    }

    /// Returns the current status of an upload session.
    func getStatus(uploadId: String) -> (received: [Int], totalChunks: Int, totalSize: Int64, filename: String)? {
        lock.lock()
        defer { lock.unlock() }
        guard let session = sessions[uploadId] else { return nil }
        return (
            received: Array(session.receivedChunks).sorted(),
            totalChunks: session.totalChunks,
            totalSize: session.totalSize,
            filename: session.filename
        )
    }

    /// Assembles all chunks into the final file and cleans up.
    func completeUpload(uploadId: String) throws -> (filePath: String, totalSize: Int64) {
        lock.lock()
        guard let session = sessions[uploadId] else {
            lock.unlock()
            throw ChunkedUploadError.sessionNotFound
        }
        guard session.isComplete else {
            lock.unlock()
            let missing = session.totalChunks - session.receivedChunks.count
            throw ChunkedUploadError.incompleteUpload(missing: missing)
        }
        // Capture session fields before unlocking
        let targetDir = session.targetDir
        let filename = session.filename
        let totalChunks = session.totalChunks
        lock.unlock()

        // Assemble final file path (safe filename enforced at init, double-check here)
        let safeFilename = (filename as NSString).lastPathComponent
        let destPath = (targetDir as NSString).appendingPathComponent(safeFilename)

        // Remove existing file if present
        try? FileManager.default.removeItem(atPath: destPath)

        // Open output stream — properly propagates errors unlike FileHandle.write()
        guard let outputStream = OutputStream(toFileAtPath: destPath, append: false) else {
            throw ChunkedUploadError.assemblyFailed("Could not create output file at \(destPath)")
        }
        outputStream.open()
        defer { outputStream.close() }

        let bufferSize = 256 * 1024  // 256KB internal buffer for stream writes
        for i in 0..<totalChunks {
            let chunkPath = chunkFilePath(uploadId: uploadId, index: i)

            guard let inputStream = InputStream(fileAtPath: chunkPath) else {
                throw ChunkedUploadError.assemblyFailed("Could not open chunk \(i) at \(chunkPath)")
            }
            inputStream.open()
            defer { inputStream.close() }

            var buffer = [UInt8](repeating: 0, count: bufferSize)
            while inputStream.hasBytesAvailable {
                let bytesRead = inputStream.read(&buffer, maxLength: bufferSize)
                if bytesRead < 0 {
                    throw ChunkedUploadError.assemblyFailed("Read error on chunk \(i): \(inputStream.streamError?.localizedDescription ?? "unknown")")
                }
                if bytesRead == 0 { break }
                let bytesWritten = outputStream.write(buffer, maxLength: bytesRead)
                if bytesWritten < 0 {
                    throw ChunkedUploadError.assemblyFailed("Write error on chunk \(i): \(outputStream.streamError?.localizedDescription ?? "unknown")")
                }
            }
        }

        // Close output before reading attributes
        outputStream.close()

        // Clean up temp chunks
        let tempDir = chunkTempDir(for: uploadId)
        try? FileManager.default.removeItem(atPath: tempDir)

        // Remove session
        lock.lock()
        sessions.removeValue(forKey: uploadId)
        lock.unlock()

        guard FileManager.default.fileExists(atPath: destPath) else {
            throw ChunkedUploadError.assemblyFailed("Assembled file not found at \(destPath) after writing")
        }

        let fileSize = (try? FileManager.default.attributesOfItem(atPath: destPath)[.size] as? Int64) ?? session.totalSize
        Log.upload.info("Chunked upload complete: \(filename) (\(self.formatBytes(fileSize))) → \(destPath)")

        return (filePath: destPath, totalSize: fileSize)
    }

    /// Validates that the given upload belongs to the given auth session.
    func validateOwnership(uploadId: String, sessionId: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return sessions[uploadId]?.sessionId == sessionId
    }

    /// Cancels an upload session and removes its temp directory.
    func cancelUpload(uploadId: String) {
        lock.lock()
        sessions.removeValue(forKey: uploadId)
        lock.unlock()
        let tempDir = chunkTempDir(for: uploadId)
        try? FileManager.default.removeItem(atPath: tempDir)
    }

    // MARK: - Cleanup

    /// Removes sessions older than 24 hours.
    func cleanupStale() {
        let cutoff = Date().addingTimeInterval(-Self.staleTTL)
        var staleIds: [String] = []

        lock.lock()
        for (id, session) in sessions where session.createdAt < cutoff {
            staleIds.append(id)
        }
        for id in staleIds {
            sessions.removeValue(forKey: id)
        }
        lock.unlock()

        for id in staleIds {
            let tempDir = chunkTempDir(for: id)
            try? FileManager.default.removeItem(atPath: tempDir)
            Log.upload.info("Cleaned stale upload session: \(id)")
        }
    }

    // MARK: - Helpers

    private func chunkTempDir(for uploadId: String) -> String {
        NSTemporaryDirectory() + "chunked_\(uploadId)"
    }

    private func chunkFilePath(uploadId: String, index: Int) -> String {
        (chunkTempDir(for: uploadId) as NSString).appendingPathComponent("chunk_\(index)")
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Errors

enum ChunkedUploadError: Error, CustomStringConvertible {
    case sessionNotFound
    case invalidChunkIndex
    case incompleteUpload(missing: Int)
    case assemblyFailed(String)

    var description: String {
        switch self {
        case .sessionNotFound: return "Upload session not found"
        case .invalidChunkIndex: return "Invalid chunk index"
        case .incompleteUpload(let missing): return "Upload incomplete — \(missing) chunks missing"
        case .assemblyFailed(let reason): return "File assembly failed: \(reason)"
        }
    }
}
