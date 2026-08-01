import AppKit
import SwiftUI

@main
struct VerbaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.openSettings) private var openSettings
    @State private var settingsViewModel = SettingsViewModel()

    var body: some Scene {
        MenuBarExtra("Verba", systemImage: "text.badge.checkmark") {
            Button("Settings…") {
                openSettings()
            }
            Button("About Verba") {
                NSApplication.shared.orderFrontStandardAboutPanel(nil)
            }
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }

        Settings {
            SettingsView(viewModel: settingsViewModel)
        }
    }
}
