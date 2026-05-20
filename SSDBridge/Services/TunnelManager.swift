import Foundation
import Combine

/// Manages a Cloudflare Quick Tunnel (`cloudflared`) to expose the local
/// server on a public `*.trycloudflare.com` HTTPS URL.
final class TunnelManager: ObservableObject {

    // MARK: - State

    enum TunnelState: Equatable {
        case disconnected
        case connecting
        case connected(url: String)
        case error(message: String)

        var publicURL: String? {
            if case .connected(let url) = self { return url }
            return nil
        }

        var isConnected: Bool {
            if case .connected = self { return true }
            return false
        }
    }

    @Published var state: TunnelState = .disconnected

    // MARK: - Private

    private var process: Process?
    private var stdErrPipe: Pipe?
    private var outputBuffer = ""

    // Well-known install locations for cloudflared
    private static let searchPaths = [
        "/opt/homebrew/bin/cloudflared",   // Apple Silicon Homebrew
        "/usr/local/bin/cloudflared",      // Intel Homebrew
        "/usr/bin/cloudflared",
    ]

    // MARK: - Public API

    /// Returns the path to `cloudflared` if installed, or nil.
    static func cloudflaredPath() -> String? {
        // First check well-known locations
        for path in searchPaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        // Fallback: use `which`
        let whichProcess = Process()
        let pipe = Pipe()
        whichProcess.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        whichProcess.arguments = ["cloudflared"]
        whichProcess.standardOutput = pipe
        whichProcess.standardError = FileHandle.nullDevice
        try? whichProcess.run()
        whichProcess.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let result = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return result.isEmpty ? nil : result
    }

    /// Whether `cloudflared` is installed on this machine.
    static var isInstalled: Bool {
        cloudflaredPath() != nil
    }

    /// Start a Cloudflare Quick Tunnel pointing at the given local port.
    func start(port: Int) {
        guard case .disconnected = state else { return }
        guard let binary = Self.cloudflaredPath() else {
            DispatchQueue.main.async {
                self.state = .error(message: "cloudflared not found. Install with: brew install cloudflared")
            }
            return
        }

        DispatchQueue.main.async {
            self.state = .connecting
        }

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: binary)
        proc.arguments = ["tunnel", "--url", "http://localhost:\(port)"]

        let errPipe = Pipe()
        proc.standardError = errPipe
        proc.standardOutput = FileHandle.nullDevice // cloudflared logs to stderr

        self.process = proc
        self.stdErrPipe = errPipe
        self.outputBuffer = ""

        // Read stderr asynchronously to find the assigned URL
        errPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let self = self else { return }
            let chunk = String(data: data, encoding: .utf8) ?? ""
            self.outputBuffer += chunk
            self.parseForURL(chunk)
        }

        // Handle process termination
        proc.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if case .connecting = self.state {
                    self.state = .error(message: "cloudflared exited before establishing tunnel")
                } else if case .connected = self.state {
                    self.state = .disconnected
                }
                self.cleanup()
            }
        }

        do {
            try proc.run()
            Log.tunnel.info("cloudflared tunnel starting for port \(port)...")
        } catch {
            DispatchQueue.main.async {
                self.state = .error(message: "Failed to launch cloudflared: \(error.localizedDescription)")
            }
        }
    }

    /// Stop the tunnel.
    func stop() {
        guard process != nil else { return }
        process?.terminate()
        // Give it a moment to clean up, then force kill if needed
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) { [weak self] in
            if self?.process?.isRunning == true {
                self?.process?.interrupt()
            }
        }
        DispatchQueue.main.async {
            self.state = .disconnected
        }
        cleanup()
    }

    // MARK: - Private

    private func cleanup() {
        stdErrPipe?.fileHandleForReading.readabilityHandler = nil
        stdErrPipe = nil
        process = nil
    }

    /// Parse cloudflared stderr output for the tunnel URL.
    /// cloudflared prints a line like:
    ///   `... | https://something-random.trycloudflare.com`
    /// or:
    ///   `... INF +-------------------------------------------+`
    ///   `... INF |  https://abc-def.trycloudflare.com        |`
    private func parseForURL(_ text: String) {
        // Match any https URL on trycloudflare.com
        let pattern = #"(https://[a-zA-Z0-9\-]+\.trycloudflare\.com)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else {
            return
        }

        let url = String(text[range])
        DispatchQueue.main.async {
            if !self.state.isConnected {
                self.state = .connected(url: url)
                Log.tunnel.info("Tunnel connected: \(url)")
            }
        }
    }

    deinit {
        stop()
    }
}
