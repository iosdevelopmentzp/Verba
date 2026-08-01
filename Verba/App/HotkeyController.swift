import KeyboardShortcuts

@MainActor
final class HotkeyController {

    // MARK: Dependencies

    private let panelController: PanelWindowController
    private let logger: AppLogger

    // MARK: Init

    init(panelController: PanelWindowController, logger: AppLogger) {
        self.panelController = panelController
        self.logger = logger
    }

    // MARK: Lifecycle

    func start() {
        KeyboardShortcuts.onKeyDown(for: .togglePanel) { [weak self] in
            guard let self else { return }
            MainActor.assumeIsolated { panelController.toggle() }
        }
        logger.hotkeyRegistered()
    }
}

extension KeyboardShortcuts.Name {
    static let togglePanel = Self(
        "togglePanel",
        initial: .init(.space, modifiers: [.control, .option])
    )
}
