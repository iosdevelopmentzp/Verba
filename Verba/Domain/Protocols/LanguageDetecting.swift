protocol LanguageDetecting: Sendable {
    func detect(_ text: String) -> TextLanguage
}
