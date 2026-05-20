import SwiftUI

@main
struct SSDBridgeApp: App {
    @StateObject private var appState = AppState()

    init() {
        NSApplication.shared.setActivationPolicy(.regular)
    }

    var body: some Scene {
        // Main dashboard window
        WindowGroup("SSDBridge") {
            DashboardView()
                .environmentObject(appState)
                .frame(minWidth: 700, minHeight: 500)
                .onAppear {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
        }
        .defaultSize(width: 900, height: 650)

        // Menubar tray icon
        MenuBarExtra("SSDBridge", systemImage: appState.isServerRunning ? "externaldrive.fill.badge.checkmark" : "externaldrive.fill") {
            MenuBarView()
                .environmentObject(appState)
        }

        // Settings
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}
