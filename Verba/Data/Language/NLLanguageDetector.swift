import NaturalLanguage

struct NLLanguageDetector: LanguageDetecting {

    // MARK: Static

    private static let minimumWordCountForDetection = 4

    // MARK: Public methods

    func detect(_ text: String) -> TextLanguage {
        guard wordCount(in: text) >= Self.minimumWordCountForDetection else { return .other }

        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)

        switch recognizer.dominantLanguage {
        case .russian: return .russian
        case .english: return .english
        default: return .other
        }
    }

    // MARK: Private methods

    private func wordCount(in text: String) -> Int {
        text.split(whereSeparator: { $0.isWhitespace || $0.isNewline }).count
    }
}
