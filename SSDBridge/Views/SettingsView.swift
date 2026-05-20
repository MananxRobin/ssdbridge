import SwiftUI

/// Settings pane for server configuration.
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var portText = ""

    var body: some View {
        Form {
            Section("Server") {
                HStack {
                    Text("Port")
                    TextField("3001", text: $portText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .onAppear {
                            portText = String(appState.serverPort)
                        }
                        .onChange(of: portText) { newValue in
                            if let port = Int(newValue), port > 0, port <= 65535 {
                                appState.serverPort = port
                            }
                        }
                }
                Text("Port change takes effect after server restart.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Global Sharing (Tunnel)") {
                HStack {
                    Text("cloudflared")
                    Spacer()
                    if TunnelManager.isInstalled {
                        Label("Installed", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    } else {
                        Label("Not Found", systemImage: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }

                if !TunnelManager.isInstalled {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Install cloudflared to enable global sharing:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("brew install cloudflared")
                            .font(.system(.caption, design: .monospaced))
                            .padding(6)
                            .background(Color(nsColor: .textBackgroundColor))
                            .cornerRadius(4)
                            .textSelection(.enabled)
                    }
                }

                if let path = TunnelManager.cloudflaredPath() {
                    LabeledContent("Binary", value: path)
                        .font(.caption)
                }
            }

            Section("Notifications") {
                Toggle("Enable macOS notifications", isOn: Binding(
                    get: { appState.notificationsEnabled },
                    set: { appState.toggleNotifications($0) }
                ))
                Text("Get notified when someone joins or downloads files.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Link Presets") {
                if appState.linkPresets.isEmpty {
                    Text("No presets saved. Create one from the main window.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(appState.linkPresets) { preset in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(preset.name).fontWeight(.medium)
                                Text(preset.scopePath).font(.caption).foregroundColor(.secondary)
                                Text("\(preset.ttlMinutes)min · \(preset.permissions) · \(preset.encrypted ? "Encrypted" : "Plain")")
                                    .font(.caption2).foregroundStyle(.tertiary)
                            }
                            Spacer()
                            Button(role: .destructive) {
                                appState.deletePreset(preset)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section("About") {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Framework", value: "Vapor (Swift)")
                Link("GitHub", destination: URL(string: "https://github.com")!)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 520)
    }
}

