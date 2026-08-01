import Foundation
import Observation

@MainActor
@Observable
final class PanelContentViewModel {

    // MARK: Dependencies

    private let captureTextUseCase: CaptureTextUseCase
    private let logger: AppLogger

    // MARK: Public properties

    private(set) var sourceText: SourceText?
    var manualDraft: String = ""

    // MARK: Init

    init(captureTextUseCase: CaptureTextUseCase, logger: AppLogger) {
        self.captureTextUseCase = captureTextUseCase
        self.logger = logger
    }

    // MARK: Public methods

    func beginCapture() async {
        do {
            sourceText = try await captureTextUseCase.execute()
        } catch let error as AppError {
            logger.textCaptureFailed(error)
            sourceText = nil
        } catch {
            sourceText = nil
        }

        guard let sourceText else { return }
        logger.textCaptured(
            charCount: sourceText.content.count,
            origin: Self.originDescription(sourceText.origin),
            language: sourceText.language
        )
    }

    func acceptManualEntry() {
        guard let made = captureTextUseCase.make(content: manualDraft, origin: .manual) else { return }
        sourceText = made
    }

    func present(_ sourceText: SourceText) {
        self.sourceText = sourceText
        logger.textCaptured(
            charCount: sourceText.content.count,
            origin: Self.originDescription(sourceText.origin),
            language: sourceText.language
        )
    }

    func reset() {
        sourceText = nil
        manualDraft = ""
    }

    // MARK: Private methods

    private static func originDescription(_ origin: SourceText.Origin) -> String {
        switch origin {
        case .pasteboard(let isReused): return isReused ? "pasteboard(reused)" : "pasteboard"
        case .service: return "service"
        case .manual: return "manual"
        }
    }
}
