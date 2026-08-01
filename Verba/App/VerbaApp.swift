import AppKit
import SwiftUI

@main
struct VerbaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.openSettings) private var openSettings

    var body: some Scene {
        MenuBarExtra("Verba", systemImage: "text.badge.checkmark") {
            Button("Settings…") {
                openSettings()
            }
            Button("About Verba") {
                NSApplication.shared.orderFrontStandardAboutPanel(nil)
            }
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }

        Settings {
            if let container = appDelegate.container {
                SettingsView(viewModel: container.settingsViewModel)
            }
        }
    }
}
