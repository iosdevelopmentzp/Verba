import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: Private properties

    private var container: AppContainer?

    // MARK: Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let container = AppContainer()
        container.start()
        self.container = container
    }
}
