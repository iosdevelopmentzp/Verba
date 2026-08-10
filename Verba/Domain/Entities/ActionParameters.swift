struct ActionParameters: Sendable, Equatable {
    var tone: Tone?
    var level: LanguageLevel?
    var sourceLanguage: TextLanguage?
    var targetLanguage: TextLanguage?
    var creativity: Creativity = .balanced
    var extraInstruction: String?
    var systemPromptOverride: String?

    static func defaultTargetLanguage(for sourceLanguage: TextLanguage) -> TextLanguage {
        sourceLanguage == .russian ? .english : .russian
    }
}
