import SwiftUI

/// Main host dashboard — the primary window of the app.
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
            }
            .listStyle(.sidebar)
            .frame(minWidth: 180)
        } detail: {
            ScrollView {
                VStack(spacing: 24) {
                    // Server control card
                    serverCard

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
