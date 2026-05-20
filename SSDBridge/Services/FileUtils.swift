import Foundation
import ZIPFoundation

/// File utility functions — MIME types, size formatting, ZIP creation.
enum FileUtils {

    // MARK: - Size Formatting

    static func formatSize(_ bytes: Int64) -> String {
        if bytes == 0 { return "0 B" }
        let units = ["B", "KB", "MB", "GB", "TB"]
        let i = Int(log(Double(bytes)) / log(1024))
        let value = Double(bytes) / pow(1024, Double(i))
        return String(format: "%.1f %@", value, units[min(i, units.count - 1)])
    }

    static func formatSize(_ bytes: Int) -> String {
        formatSize(Int64(bytes))
    }

    // MARK: - MIME Types

    private static let mimeMap: [String: String] = [
        // Images
        "jpg": "image/jpeg", "jpeg": "image/jpeg", "png": "image/png",
        "gif": "image/gif", "webp": "image/webp", "svg": "image/svg+xml",
        "ico": "image/x-icon", "bmp": "image/bmp", "tiff": "image/tiff",
        "heic": "image/heic", "heif": "image/heif",
        // Video
        "mp4": "video/mp4", "webm": "video/webm", "mov": "video/quicktime",
        "avi": "video/x-msvideo", "mkv": "video/x-matroska", "m4v": "video/mp4",
        // Audio
        "mp3": "audio/mpeg", "wav": "audio/wav", "ogg": "audio/ogg",
        "flac": "audio/flac", "aac": "audio/aac", "m4a": "audio/mp4",
        // Documents
        "pdf": "application/pdf",
        "doc": "application/msword", "docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        "xls": "application/vnd.ms-excel", "xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "ppt": "application/vnd.ms-powerpoint", "pptx": "application/vnd.openxmlformats-officedocument.presentationml.presentation",
        // Text / Code
        "txt": "text/plain", "html": "text/html", "css": "text/css",
        "js": "text/javascript", "jsx": "text/javascript",
        "ts": "text/typescript", "tsx": "text/typescript",
        "json": "application/json", "xml": "text/xml",
        "md": "text/markdown", "csv": "text/csv",
        "py": "text/x-python", "rb": "text/x-ruby",
        "go": "text/x-go", "rs": "text/x-rust",
        "java": "text/x-java", "swift": "text/x-swift",
        "c": "text/x-c", "cpp": "text/x-c++", "h": "text/x-c",
        "sh": "text/x-shellscript", "yaml": "text/yaml", "yml": "text/yaml",
        "toml": "text/plain", "ini": "text/plain",
        "sql": "text/x-sql", "log": "text/plain",
        // Archives
        "zip": "application/zip", "tar": "application/x-tar",
        "gz": "application/gzip", "rar": "application/x-rar-compressed",
        "7z": "application/x-7z-compressed",
        // Other
        "dmg": "application/x-apple-diskimage",
    ]

    static func mimeType(for path: String) -> String {
        let ext = (path as NSString).pathExtension.lowercased()
        return mimeMap[ext] ?? "application/octet-stream"
    }

    /// Determines if a file is a text file (for preview purposes).
    static func isTextFile(_ path: String) -> Bool {
        let ext = (path as NSString).pathExtension.lowercased()
        let textExtensions: Set<String> = [
            "txt", "md", "json", "xml", "html", "css", "js", "jsx", "ts", "tsx",
            "py", "rb", "go", "rs", "java", "swift", "c", "cpp", "h", "sh",
            "yaml", "yml", "toml", "ini", "sql", "csv", "log",
        ]
        return textExtensions.contains(ext) || mimeType(for: path).hasPrefix("text/")
    }

    // MARK: - ZIP Creation

    static func createZip(from sourcePath: String, to destinationPath: String) throws {
        let sourceURL = URL(fileURLWithPath: sourcePath)
        let destURL = URL(fileURLWithPath: destinationPath)
        try FileManager.default.zipItem(at: sourceURL, to: destURL, shouldKeepParent: true)
    }
}
