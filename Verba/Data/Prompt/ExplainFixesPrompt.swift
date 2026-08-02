enum ExplainFixesPrompt {

    // MARK: Public methods

    static func systemPrompt(language: TextLanguage) -> String {
        """
        You are a writing tutor. Given ORIGINAL text, the CORRECTED version, and a short list of \
        fixes already identified (NOTES), explain the underlying grammar or phrasing rule behind \
        each fix in plain, friendly language — as if teaching a non-native English speaker why \
        their original wording was wrong and what rule the correction follows. Ground each \
        explanation in the actual text if a note is vague. Do not just restate the fix; teach the \
        rule. One explanation per fix, 1 to 3 sentences each, written in \(languageName(language)).
        """
    }

    static func userContent(original: String, corrected: String, notes: [String]) -> String {
        """
        ORIGINAL:
        \(original)

        CORRECTED:
        \(corrected)

        NOTES:
        \(notes.map { "- \($0)" }.joined(separator: "\n"))
        """
    }

    // MARK: Private methods

    private static func languageName(_ language: TextLanguage) -> String {
        switch language {
        case .russian: return "Russian"
        case .english: return "English"
        case .other: return "the same language as the input text"
        }
    }
}
