import SwiftUI

/// Main host dashboard — the primary window of the app.
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

struct DashboardView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationSplitView {
            // Sidebar
            List {
                Section("Server") {
                    Label(
                        appState.isServerRunning ? "Running" : "Stopped",
                        systemImage: appState.isServerRunning
                            ? "bolt.fill"
                            : "bolt.slash.fill"
                    )
                    .foregroundColor(appState.isServerRunning ? .green : .secondary)
                }

                Section("Stats") {
                    Label("\(appState.activeLinks.count) Active Links", systemImage: "link")
                    Label("\(appState.activeSessions.count) Sessions", systemImage: "person.2")
                }

                if appState.isServerRunning && appState.webSocketManager.activeCount > 0 {
                    Section("Live Presence") {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(.green)
                                .frame(width: 8, height: 8)
                            Text("\(appState.webSocketManager.activeCount) guest(s) connected")
                                .font(.callout)
                                .foregroundColor(.green)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .listStyle(.sidebar)
            .frame(minWidth: 180)
        } detail: {
            ScrollView {
                VStack(spacing: 24) {
                    // Server control card
                    serverCard

                    // Live Presence card
                    if appState.isServerRunning {
                        presenceCard
                    }

                    // Create Link section
                    CreateLinkView()
                        .environmentObject(appState)

                    // Active Links
                    ActiveLinksView()
                        .environmentObject(appState)

                    // Active Sessions
                    ActiveSessionsView()
                        .environmentObject(appState)

                    // Access Log
                    AccessLogView()
                        .environmentObject(appState)

                    // Transfer Stats
                    TransferStatsView()
                        .environmentObject(appState)
                }
                .padding(24)
            }
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .navigationTitle("SSDBridge")
    }

    // MARK: - Server Card

    private var serverCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                // Server status row
                HStack(spacing: 16) {
                    Image(systemName: appState.isServerRunning
                        ? "externaldrive.fill.badge.checkmark"
                        : "externaldrive.fill")
                        .font(.system(size: 32))
                        .foregroundColor(appState.isServerRunning ? .green : .secondary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(appState.isServerRunning ? "Server Running" : "Server Stopped")
                            .font(.headline)
                        if appState.isServerRunning {
                            let ip = NetworkUtils.getLocalIP()
                            Text("LAN: http://\(ip):\(appState.serverPort)")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                                .textSelection(.enabled)
                        }
                        if let error = appState.serverError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }

                    Spacer()

                    Button(appState.isServerRunning ? "Stop Server" : "Start Server") {
                        if appState.isServerRunning {
                            appState.stopServer()
                        } else {
                            appState.startServer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(appState.isServerRunning ? .red : .green)
                    .controlSize(.large)
                }

                // Tunnel section (only when server is running)
                if appState.isServerRunning {
                    Divider()
                    tunnelSection
                }
            }
            .padding(8)
        } label: {
            Label("Server Control", systemImage: "server.rack")
        }
    }

    // MARK: - Presence Card

    @ViewBuilder
    private var presenceCard: some View {
        let count = appState.webSocketManager.activeCount
        let sessions = appState.webSocketManager.activeSessions()

        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Circle()
                        .fill(count > 0 ? Color.green : Color.secondary)
                        .frame(width: 10, height: 10)
                    Text(count > 0
                         ? "\(count) guest(s) connected"
                         : "No guests connected")
                        .font(.headline)
                    Spacer()
                    if count > 0 {
                        Text("● LIVE")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }

                if !sessions.isEmpty {
                    Divider()
                    ForEach(sessions, id: \.sessionId) { session in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: WebSocketManager.presenceColors[abs(session.sessionId.hashValue) % WebSocketManager.presenceColors.count]))
                                .frame(width: 8, height: 8)
                            Text(session.sessionId.prefix(8))
                                .font(.system(.caption, design: .monospaced))
                            if !session.path.isEmpty {
                                Text("→ \(session.path)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }
            .padding(8)
        } label: {
            Label("Live Presence", systemImage: "wave.3.right")
        }
    }

    // MARK: - Tunnel Section

    @ViewBuilder
    private var tunnelSection: some View {
        HStack(spacing: 12) {
            Image(systemName: tunnelIcon)
                .font(.system(size: 20))
                .foregroundColor(tunnelColor)

            VStack(alignment: .leading, spacing: 2) {
                Text("Global Sharing")
                    .font(.subheadline)
                    .fontWeight(.medium)

                switch appState.tunnelState {
                case .disconnected:
                    Text("Share files with anyone on the internet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                case .connecting:
                    HStack(spacing: 6) {
                        ProgressView()
                            .controlSize(.mini)
                        Text("Establishing tunnel…")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                case .connected(let url):
                    Text(url)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.green)
                        .textSelection(.enabled)
                case .error(let message):
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.red)
                        .lineLimit(2)
                }
            }

            Spacer()

            // Copy global URL button
            if case .connected(let url) = appState.tunnelState {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(url, forType: .string)
                } label: {
                    Label("Copy URL", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            // Toggle tunnel button
            tunnelToggleButton
        }
    }

    private var tunnelToggleButton: some View {
        Group {
            switch appState.tunnelState {
            case .disconnected, .error:
                Button {
                    appState.startTunnel()
                } label: {
                    Label("Enable", systemImage: "globe")
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .controlSize(.regular)
            case .connecting:
                Button {
                    appState.stopTunnel()
                } label: {
                    Label("Cancel", systemImage: "xmark")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            case .connected:
                Button {
                    appState.stopTunnel()
                } label: {
                    Label("Disable", systemImage: "globe")
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .controlSize(.regular)
            }
        }
    }

    private var tunnelIcon: String {
        switch appState.tunnelState {
        case .disconnected: return "globe"
        case .connecting: return "globe.badge.chevron.backward"
        case .connected: return "globe.americas.fill"
        case .error: return "globe.badge.chevron.backward"
        }
    }

    private var tunnelColor: Color {
        switch appState.tunnelState {
        case .disconnected: return .secondary
        case .connecting: return .orange
        case .connected: return .green
        case .error: return .red
        }
    }

}
