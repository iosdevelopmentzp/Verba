import AppKit
import SwiftUI

@main
struct VerbaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.openSettings) private var openSettings
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some Scene {
        MenuBarExtra {
            if let container = appDelegate.container {
                MenuBarView(
                    viewModel: container.menuBarViewModel,
                    onOpenPanel: { container.panelWindowController.show() },
                    onOpenSettings: { openSettings() },
                    onOpenOnboarding: { openWindow(id: Self.onboardingWindowID) },
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

        Window("Set up Verba", id: Self.onboardingWindowID) {
            if let container = appDelegate.container {
                OnboardingView(viewModel: container.onboardingViewModel) {
                    dismissWindow(id: Self.onboardingWindowID)
                }
            }
        }
        .windowResizability(.contentSize)
        .defaultLaunchBehavior(appDelegate.container?.needsOnboarding == true ? .presented : .suppressed)
    }
}

private extension VerbaApp {
    static let onboardingWindowID = "onboarding"
}
