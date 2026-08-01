import Foundation

struct CaptureTextUseCase: Sendable {

    // MARK: Dependencies

    private let textSource: TextCapturing
    private let languageDetector: LanguageDetecting

    // MARK: Init

    init(textSource: TextCapturing, languageDetector: LanguageDetecting) {
        self.textSource = textSource
        self.languageDetector = languageDetector
    }

    // MARK: Public methods

    func execute() async throws -> SourceText? {
        guard let captured = try await textSource.capture() else { return nil }
        return make(content: captured.content, origin: captured.origin)
    }

    func make(content: String, origin: SourceText.Origin) -> SourceText? {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return nil }
        return SourceText(content: trimmed, language: languageDetector.detect(trimmed), origin: origin)
    }
}
