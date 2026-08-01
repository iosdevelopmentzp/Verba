import AppKit
import Observation

@Observable
final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: Public properties

    private(set) var container: AppContainer?

    // MARK: Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let container = AppContainer()
        container.start()
        self.container = container
    }
}
