import AppKit
import SwiftUI

@main
struct VerbaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.openSettings) private var openSettings

    var body: some Scene {
        MenuBarExtra {
            if let container = appDelegate.container {
                MenuBarView(
                    viewModel: container.menuBarViewModel,
                    onOpenSettings: { openSettings() },
                    onAbout: { NSApplication.shared.orderFrontStandardAboutPanel(nil) },
                    onQuit: { NSApplication.shared.terminate(nil) }
                )
            }
        } label: {
            if let container = appDelegate.container {
                MenuBarLabelView(viewModel: container.menuBarViewModel)
            } else {
                Image(systemName: "text.badge.checkmark")
            }
        }

        Settings {
            if let container = appDelegate.container {
                SettingsView(viewModel: container.settingsViewModel)
            }
        }
    }
}
