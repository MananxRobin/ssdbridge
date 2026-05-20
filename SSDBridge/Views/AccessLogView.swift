import SwiftUI

/// Displays the access event log with filtering.
struct AccessLogView: View {
    @EnvironmentObject var appState: AppState

    @State private var filterAction: AccessLogger.AccessEvent.Action? = nil

    var filteredEvents: [AccessLogger.AccessEvent] {
        let events = appState.accessLogger.events
        guard let filter = filterAction else { return events }
        return events.filter { $0.action == filter }
    }

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                // Header with filter + clear
                HStack {
                    Text("\(filteredEvents.count) events")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    // Filter picker
                    Picker("Filter", selection: $filterAction) {
                        Text("All").tag(nil as AccessLogger.AccessEvent.Action?)
                        ForEach(AccessLogger.AccessEvent.Action.allCases, id: \.self) { action in
                            Text("\(action.icon) \(action.label)")
                                .tag(action as AccessLogger.AccessEvent.Action?)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 160)

                    Button {
                        appState.accessLogger.clear()
                    } label: {
                        Label("Clear", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                // Event list
                if filteredEvents.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "shield.checkered")
                                .font(.system(size: 28))
                                .foregroundColor(.secondary)
                            Text("No access events yet")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 16)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(filteredEvents) { event in
                                eventRow(event)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
            }
        } label: {
            Label("Access Log", systemImage: "shield.lefthalf.filled")
        }
    }

    // MARK: - Event Row

    private func eventRow(_ event: AccessLogger.AccessEvent) -> some View {
        HStack(spacing: 8) {
            Text(event.action.icon)
                .font(.body)

            Text(event.timeString)
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)

            Text(event.action.label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(actionColor(event.action))
                .frame(width: 90, alignment: .leading)

            Text(event.ip)
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 110, alignment: .leading)

            Text(String(event.tokenId.prefix(8)) + "…")
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.secondary)

            if let detail = event.detail {
                Text(detail)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 6)
        .background(actionBackground(event.action))
        .cornerRadius(4)
    }

    private func actionColor(_ action: AccessLogger.AccessEvent.Action) -> Color {
        switch action {
        case .joinSuccess: return .green
        case .joinFailed, .passwordFailed: return .red
        case .joinRateLimited: return .orange
        case .download: return .blue
        case .upload: return .purple
        }
    }

    private func actionBackground(_ action: AccessLogger.AccessEvent.Action) -> Color {
        switch action {
        case .joinFailed, .passwordFailed, .joinRateLimited:
            return Color.red.opacity(0.05)
        default:
            return .clear
        }
    }
}
