import Foundation
#if canImport(Network)
import Network
#endif

/// Network utility functions.
enum NetworkUtils {
    /// Get the local IPv4 address of this machine.
    static func getLocalIP() -> String {
        var address = "127.0.0.1"

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return address
        }
        defer { freeifaddrs(ifaddr) }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family

            if addrFamily == UInt8(AF_INET) { // IPv4
                let name = String(cString: interface.ifa_name)
                if name == "en0" || name == "en1" { // Wi-Fi or Ethernet
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(
                        interface.ifa_addr,
                        socklen_t(interface.ifa_addr.pointee.sa_len),
                        &hostname,
                        socklen_t(hostname.count),
                        nil, 0,
                        NI_NUMERICHOST
                    )
                    address = String(cString: hostname)
                    break
                }
            }
        }

        return address
    }

    /// Check if `cloudflared` is installed on this machine.
    static func isCloudflaredInstalled() -> Bool {
        TunnelManager.isInstalled
    }

    /// Get the path to the `cloudflared` binary, or nil if not found.
    static func cloudflaredPath() -> String? {
        TunnelManager.cloudflaredPath()
    }
}
