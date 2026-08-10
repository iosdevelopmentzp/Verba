@MainActor
protocol SpeechSynthesizing: AnyObject {
    var onFinish: (() -> Void)? { get set }
    func speak(_ text: String, language: TextLanguage)
    func stop()
    func bestVoiceQuality(for language: TextLanguage) -> SpeechVoiceQuality
}
