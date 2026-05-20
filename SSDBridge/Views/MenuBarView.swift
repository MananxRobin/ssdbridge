import SwiftUI

/// Menubar tray dropdown for quick server control.
struct MenuBarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Status
            HStack {
                Circle()
                    .fill(appState.isServerRunning ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                Text(appState.isServerRunning ? "Server Running" : "Server Stopped")
            }
            .padding(.horizontal, 8)

            if appState.isServerRunning {
                let ip = NetworkUtils.getLocalIP()
                Text("http://\(ip):\(appState.serverPort)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
            }

            Divider()

            // Stats
            Text("🔗 \(appState.activeLinks.count) Links  •  👥 \(appState.activeSessions.count) Sessions")
                .font(.caption)
                .padding(.horizontal, 8)

            // Quick share from presets
            if !appState.linkPresets.isEmpty {
                Divider()
                Menu("⚡ Share from Preset") {
                    ForEach(appState.linkPresets) { preset in
                        Button(preset.name) {
                            guard appState.isServerRunning else { return }
                            let token = appState.createLink(
                                scopePath: preset.scopePath,
                                ttlMinutes: preset.ttlMinutes,
                                oneTimeJoin: preset.oneTimeJoin,
                                password: preset.password,
                                permissions: preset.permissions,
                                encrypted: preset.encrypted
                            )
                            let url = appState.buildLinkURL(token: token)
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(url, forType: .string)
                        }
                    }
                }
            }

            Divider()

            // Toggle
            Button(appState.isServerRunning ? "⏹ Stop Server" : "▶️ Start Server") {
                if appState.isServerRunning {
                    appState.stopServer()
                } else {
                    appState.startServer()
                }
            }
            .keyboardShortcut("s", modifiers: [.command])

            Divider()

            Button("Quit SSDBridge") {
                if appState.isServerRunning {
                    appState.stopServer()
                }
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: [.command])
        }
        .padding(4)
    }
}
