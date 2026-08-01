import AppKit
import SwiftUI

@main
struct VerbaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Verba", systemImage: "text.badge.checkmark") {
            Button("About Verba") {
                NSApplication.shared.orderFrontStandardAboutPanel(nil)
            }
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
