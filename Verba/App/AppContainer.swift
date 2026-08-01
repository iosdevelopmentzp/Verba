@MainActor
final class AppContainer {

    // MARK: Public properties

    let logger: AppLogger
    let panelWindowController: PanelWindowController
    let hotkeyController: HotkeyController

    // MARK: Init

    init() {
        logger = AppLogger()
        panelWindowController = PanelWindowController(logger: logger)
        hotkeyController = HotkeyController(panelController: panelWindowController, logger: logger)
    }

    // MARK: Lifecycle

    func start() {
        panelWindowController.start()
        hotkeyController.start()
        logger.appLaunched()
    }
}
