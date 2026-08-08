import AVFoundation

@MainActor
final class SystemSpeechSynthesizer: NSObject, SpeechSynthesizing {

    // MARK: Public properties

    var onFinish: (() -> Void)?

    // MARK: Private properties

    private let synthesizer = AVSpeechSynthesizer()

    // MARK: Init

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: Public methods

    func speak(_ text: String, language: TextLanguage) {
        stop()

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = Self.voice(for: language)
        synthesizer.speak(utterance)
    }

    func stop() {
        guard synthesizer.isSpeaking else { return }
        synthesizer.stopSpeaking(at: .immediate)
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension SystemSpeechSynthesizer: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in onFinish?() }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didCancel utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in onFinish?() }
    }
}

// MARK: - Private

private extension SystemSpeechSynthesizer {
    // A voice for the requested language may not be installed; nil lets AVFoundation
    // fall back to the system voice rather than refusing to speak.
    static func voice(for language: TextLanguage) -> AVSpeechSynthesisVoice? {
        guard let code = bcp47(for: language) else { return nil }
        return AVSpeechSynthesisVoice(language: code)
    }

    static func bcp47(for language: TextLanguage) -> String? {
        switch language {
        case .english: return "en-US"
        case .russian: return "ru-RU"
        case .ukrainian: return "uk-UA"
        case .spanish: return "es-ES"
        case .other: return nil
        }
    }
}
