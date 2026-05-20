import SwiftUI

/// Table showing active browser sessions with terminate action.
struct ActiveSessionsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        GroupBox {
            if appState.activeSessions.isEmpty {
                Text("No active sessions")
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                Table(appState.activeSessions) {
                    TableColumn("Session") { session in
                        Text(String(session.id.prefix(10)) + "…")
                            .font(.system(.body, design: .monospaced))
                    }
                    .width(min: 100, ideal: 120)

                    TableColumn("Scope") { session in
                        Text(session.scopePath)
                            .lineLimit(1)
                    }
                    .width(min: 100, ideal: 180)

                    TableColumn("Access") { session in
                        HStack(spacing: 4) {
                            Image(systemName: session.permissions == "readwrite" ? "pencil" : "eye")
                            Text(session.permissions == "readwrite" ? "R/W" : "Read")
                        }
                        .foregroundColor(session.permissions == "readwrite" ? .purple : .blue)
                        .font(.caption)
                    }
                    .width(min: 50, ideal: 70)

                    TableColumn("Connected") { session in
                        Text(session.connectedDuration)
                            .foregroundColor(.secondary)
                    }
                    .width(min: 60, ideal: 90)

                    TableColumn("Last Active") { session in
                        Text(session.lastActiveDuration)
                            .foregroundColor(.secondary)
                    }
                    .width(min: 60, ideal: 90)

                    TableColumn("") { session in
                        Button("Terminate", role: .destructive) {
                            appState.terminateSession(sessionId: session.id)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .width(80)
                }
                .frame(minHeight: max(100, CGFloat(appState.activeSessions.count * 30 + 40)))
            }
        } label: {
            Label("Active Sessions (\(appState.activeSessions.count))", systemImage: "person.2")
        }
    }
}
