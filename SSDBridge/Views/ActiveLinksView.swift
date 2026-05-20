import SwiftUI

/// Table showing active magic links with revoke action.
struct ActiveLinksView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        GroupBox {
            if appState.activeLinks.isEmpty {
                Text("No active links")
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                Table(appState.activeLinks) {
                    TableColumn("Token") { token in
                        Text(String(token.id.prefix(10)) + "…")
                            .font(.system(.body, design: .monospaced))
                    }
                    .width(min: 100, ideal: 120)

                    TableColumn("Scope") { token in
                        Text(token.scopePath)
                            .lineLimit(1)
                    }
                    .width(min: 100, ideal: 180)

                    TableColumn("Expires") { token in
                        Text(token.timeRemaining)
                            .foregroundColor(token.isExpired ? .red : .secondary)
                    }
                    .width(min: 60, ideal: 80)

                    TableColumn("Access") { token in
                        HStack(spacing: 4) {
                            Image(systemName: token.permissions == "readwrite" ? "pencil" : "eye")
                            Text(token.permissions == "readwrite" ? "R/W" : "Read")
                        }
                        .foregroundColor(token.permissions == "readwrite" ? .purple : .blue)
                        .font(.caption)
                    }
                    .width(min: 50, ideal: 70)

                    TableColumn("Flags") { token in
                        HStack(spacing: 4) {
                            if token.hasPassword {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.orange)
                            }
                            if token.oneTimeJoin {
                                Image(systemName: "key.fill")
                                    .foregroundColor(.blue)
                            }
                            if token.used {
                                Text("Used")
                                    .font(.caption2)
                                    .padding(.horizontal, 4)
                                    .background(Color.gray.opacity(0.3))
                                    .cornerRadius(3)
                            }
                        }
                    }
                    .width(min: 60, ideal: 80)

                    TableColumn("") { token in
                        Button("Revoke", role: .destructive) {
                            appState.revokeLink(tokenId: token.id)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .width(70)
                }
                .frame(minHeight: max(100, CGFloat(appState.activeLinks.count * 30 + 40)))
            }
        } label: {
            Label("Active Links (\(appState.activeLinks.count))", systemImage: "link")
        }
    }
}
