enum Templates {

    // MARK: Static

    static let preamble = """
    You edit short workplace messages. Return only JSON matching the provided schema. \
    "primary" is the improved text and nothing else — no preamble, no quotes, no markdown. \
    "alternatives" holds up to 3 genuinely different phrasings, or an empty array. "notes" \
    holds up to 4 very short bullets naming what changed, in the language of the input text. \
    Preserve the author's meaning, names, links, code, and formatting. Never add greetings, \
    sign-offs, or emoji that were not in the input. Do not use semicolons in "primary" or \
    "alternatives" — split into two sentences or use a comma instead.
    """

    static let all: [String: PromptTemplate] = {
        let templates: [PromptTemplate] = [
            FixGrammarTemplate(),
            RephraseTemplate(),
            ChangeToneTemplate(),
            TranslateTemplate(),
            HumanizeTemplate()
        ]
        return Dictionary(uniqueKeysWithValues: templates.map { ($0.id, $0) })
    }()
}

private struct FixGrammarTemplate: PromptTemplate {
    let id = "fixGrammar"
    let version = 2

    func systemPrompt(parameters: ActionParameters, language: TextLanguage) -> String {
        """
        Correct grammar, spelling, punctuation, and article or preposition use. Keep the \
        author's wording and register wherever it is already correct — do not upgrade the \
        vocabulary or make it more formal. List each concrete fix in notes, for example \
        "can not to" → "can't". If nothing needed correction, return the text unchanged with \
        an empty notes array.
        """
    }
}

private struct RephraseTemplate: PromptTemplate {
    let id = "rephrase"
    let version = 2

    func systemPrompt(parameters: ActionParameters, language: TextLanguage) -> String {
        """
        Keep the meaning and the register, change the wording. primary is the best rewrite; \
        alternatives holds two or three meaningfully different phrasings of the same message. \
        Leave notes empty, or add one short line describing what shifted. Do not change facts, \
        names, links, or code.
        """
    }
}

private struct ChangeToneTemplate: PromptTemplate {
    let id = "changeTone"
    let version = 2

    func systemPrompt(parameters: ActionParameters, language: TextLanguage) -> String {
        let tone = parameters.tone?.rawValue ?? Tone.formal.rawValue
        return """
        Rewrite the message in a \(tone) tone without changing the facts, names, links, or code. \
        "direct" means shorter and unhedged, not blunt or rude; "friendly" adds warmth without \
        becoming casual slang. primary is the rewrite in the requested tone; alternatives may \
        offer one or two variations at the same tone. Notes name what changed.
        """
    }
}

private struct TranslateTemplate: PromptTemplate {
    let id = "translate"
    let version = 2

    func systemPrompt(parameters: ActionParameters, language: TextLanguage) -> String {
        """
        Translate between Russian and English; detect the input's language yourself and \
        translate into the other one. Preserve technical terms, product names, and code exactly \
        as written. primary is the translation; alternatives may hold one alternate phrasing if \
        genuinely useful, otherwise leave it empty. Notes may flag terms with no clean \
        equivalent, in the language of the input text.
        """
    }
}

private struct HumanizeTemplate: PromptTemplate {
    let id = "humanize"
    let version = 2

    func systemPrompt(parameters: ActionParameters, language: TextLanguage) -> String {
        let level = (parameters.level ?? .b2).rawValue.uppercased()
        return """
        Rewrite so it reads as written by a real person at CEFR level \(level) whose first \
        language is not English. Use contractions and everyday vocabulary; keep sentences \
        ordinary in length; allow slight imperfection in rhythm. Avoid em dashes, "delve", \
        "moreover", "it's worth noting", tricolons, and other polished-AI tells. Never make it \
        wrong on purpose — meaning and facts must stay intact. Notes name the biggest stylistic \
        changes.
        """
    }
}
