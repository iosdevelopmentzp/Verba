import AppKit

@MainActor
final class AppContainer {

    // MARK: Public properties

    let logger: AppLogger
    let panelWindowController: PanelWindowController
    let hotkeyController: HotkeyController
    let servicesProvider: ServicesProvider

    // MARK: Init

    init() {
        logger = AppLogger()

        let textSource = PasteboardTextSource()
        let languageDetector = NLLanguageDetector()
        let captureTextUseCase = CaptureTextUseCase(textSource: textSource, languageDetector: languageDetector)

        panelWindowController = PanelWindowController(logger: logger, captureTextUseCase: captureTextUseCase)
        hotkeyController = HotkeyController(panelController: panelWindowController, logger: logger)
        servicesProvider = ServicesProvider(
            panelController: panelWindowController,
            captureTextUseCase: captureTextUseCase,
            logger: logger
        )
    }

    // MARK: Lifecycle

    func start() {
        panelWindowController.start()
        hotkeyController.start()
        NSApp.servicesProvider = servicesProvider
        logger.appLaunched()
    }
}
