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

    func bestVoiceQuality(for language: TextLanguage) -> SpeechVoiceQuality {
        guard let voice = Self.voice(for: language) else { return .missing }
        return Self.quality(of: voice)
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
    // AVSpeechSynthesisVoice(language:) returns the *default* voice, which is the
    // compact one even when an enhanced or premium voice for the same language is
    // installed — hence the manual scan for the best available.
    static func voice(for language: TextLanguage) -> AVSpeechSynthesisVoice? {
        guard let code = bcp47(for: language) else { return nil }
        let prefix = String(code.prefix(2))

        let candidates = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language == code || $0.language.hasPrefix(prefix + "-") }
        guard candidates.isEmpty == false else { return AVSpeechSynthesisVoice(language: code) }

        return candidates.max { lhs, rhs in
            rank(lhs, exactLanguage: code) < rank(rhs, exactLanguage: code)
        }
    }

    static func rank(_ voice: AVSpeechSynthesisVoice, exactLanguage: String) -> Int {
        quality(of: voice).rawValue * 2 + (voice.language == exactLanguage ? 1 : 0)
    }

    static func quality(of voice: AVSpeechSynthesisVoice) -> SpeechVoiceQuality {
        switch voice.quality {
        case .premium: return .premium
        case .enhanced: return .enhanced
        default: return .compact
        }
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
