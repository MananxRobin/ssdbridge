import SwiftUI

/// Dashboard card showing transfer statistics and live bandwidth.
struct TransferStatsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 16) {
                // Bandwidth meter
                bandwidthMeter

                Divider()

                // Stats grid
                HStack(spacing: 24) {
                    statItem(
                        icon: "arrow.down.circle.fill",
                        color: .blue,
                        label: "Downloads",
                        value: "\(appState.transferStats.totalDownloads)",
                        subValue: appState.transferStats.downloadFormatted
                    )
                    statItem(
                        icon: "arrow.up.circle.fill",
                        color: .purple,
                        label: "Uploads",
                        value: "\(appState.transferStats.totalUploads)",
                        subValue: appState.transferStats.uploadFormatted
                    )
                    statItem(
                        icon: "arrow.left.arrow.right.circle.fill",
                        color: .green,
                        label: "Total",
                        value: "\(appState.transferStats.totalDownloads + appState.transferStats.totalUploads)",
                        subValue: appState.transferStats.totalTransferFormatted
                    )

                    Spacer()

                    Button {
                        appState.transferStats.reset()
                    } label: {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        } label: {
            Label("Transfer Stats", systemImage: "chart.bar.fill")
        }
    }

    // MARK: - Bandwidth Meter

    private var bandwidthMeter: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Live Bandwidth")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(appState.transferStats.bandwidthFormatted)
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundColor(bandwidthColor)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: bandwidthBarWidth(totalWidth: geo.size.width), height: 8)
                        .animation(.easeInOut(duration: 0.5), value: appState.transferStats.currentBytesPerSecond)
                }
            }
            .frame(height: 8)
        }
    }

    /// Map bandwidth to bar width. Cap at 100 MB/s for the full bar.
    private func bandwidthBarWidth(totalWidth: CGFloat) -> CGFloat {
        let maxBps: Double = 100 * 1024 * 1024 // 100 MB/s
        let ratio = min(appState.transferStats.currentBytesPerSecond / maxBps, 1.0)
        return max(CGFloat(ratio) * totalWidth, 2)
    }

    private var bandwidthColor: Color {
        let bps = appState.transferStats.currentBytesPerSecond
        if bps > 10 * 1024 * 1024 { return .green }   // > 10 MB/s
        if bps > 1024 * 1024 { return .blue }           // > 1 MB/s
        if bps > 0 { return .orange }
        return .secondary
    }

    // MARK: - Stat Item

    private func statItem(icon: String, color: Color, label: String, value: String, subValue: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                Text(subValue)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}
