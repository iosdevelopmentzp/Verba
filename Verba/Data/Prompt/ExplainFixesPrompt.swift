enum ExplainFixesPrompt {

    // MARK: Public methods

    static func systemPrompt(language: TextLanguage) -> String {
        """
        You are a writing tutor. Given ORIGINAL text, the CORRECTED version, and a short list of \
        fixes already identified (NOTES), explain the underlying grammar or phrasing rule behind \
        each fix — as if teaching a non-native English speaker why their original wording was \
        wrong and what rule the correction follows. Ground each explanation in the actual text if \
        a note is vague. Do not just restate the fix; teach the rule. One entry per fix. "title" \
        is a very short label (2 to 5 words) naming what the rule is about, for example \
        "Subject-verb agreement" or "Article before a noun" — not a repeat of the fix itself. \
        "detail" is the explanation, 1 to 3 sentences, plain and friendly. Both written in \
        \(languageName(language)).
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
        case .ukrainian: return "Ukrainian"
        case .spanish: return "Spanish"
        case .other: return "the same language as the input text"
        }
    }
}
