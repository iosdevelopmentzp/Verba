import AppKit

final class ServicesProvider: NSObject {

    // MARK: Dependencies

    private let panelController: PanelWindowController
    private let captureTextUseCase: CaptureTextUseCase
    private let logger: AppLogger

    // MARK: Static

    private static let emptySelectionMessage = "Verba couldn't read the selected text."

    // MARK: Init

    init(panelController: PanelWindowController, captureTextUseCase: CaptureTextUseCase, logger: AppLogger) {
        self.panelController = panelController
        self.captureTextUseCase = captureTextUseCase
        self.logger = logger
    }

    // MARK: Public methods

    @objc func improveText(
        _ pboard: NSPasteboard,
        userData: String?,
        error: AutoreleasingUnsafeMutablePointer<NSString>
    ) {
        guard let selection = pboard.string(forType: .string),
              let sourceText = captureTextUseCase.make(content: selection, origin: .service) else {
            error.pointee = Self.emptySelectionMessage as NSString
            return
        }

        Task { @MainActor [panelController, logger] in
            logger.serviceInvoked(charCount: sourceText.content.count)
            panelController.present(sourceText)
        }
    }
}
