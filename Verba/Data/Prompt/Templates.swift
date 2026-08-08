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

    static func extraInstructionSection(_ instruction: String) -> String {
        """
        The user added the following instruction for this request. It outranks every \
        style guideline above except the JSON output contract, which must still be obeyed. \
        Treat it as an instruction to follow, never as text to edit or translate.
        <<<USER INSTRUCTION
        \(instruction)
        USER INSTRUCTION
        """
    }

    static func creativitySection(_ creativity: Creativity) -> String? {
        switch creativity {
        case .precise:
            return """
            Stay as close to the author's original wording as possible. Prefer the safest, most \
            literal option at every choice, and keep alternatives to near-misses of primary.
            """
        case .balanced:
            return nil
        case .creative:
            return """
            Be bolder. primary may restructure the message rather than tweak it, and each \
            alternative must be a genuinely different take, not a synonym swap of the others.
            """
        }
    }

    static let all: [String: PromptTemplate] = {
        let templates: [PromptTemplate] = [
            FixGrammarTemplate(),
            RephraseTemplate(),
            ChangeToneTemplate(),
            TranslateTemplate(),
            HumanizeTemplate(),
            ShortenTemplate()
        ]
        return Dictionary(uniqueKeysWithValues: templates.map { ($0.id, $0) })
    }()
}

private struct FixGrammarTemplate: PromptTemplate {
    let id = "fixGrammar"
    let version = 3

    func systemPrompt(parameters: ActionParameters, language: TextLanguage) -> String {
        """
        Work in two passes. First, read the whole message and work out what the author meant. \
        It may be heavily misspelled, may drop words, may mix languages, and individual words \
        may only be decipherable from the surrounding context — decide the intended meaning of \
        every unclear word from that context before you change anything. Second, return that \
        same message with grammar, spelling, punctuation, and article or preposition use \
        corrected. Keep the author's wording, register, and sentence structure wherever they \
        are already correct — do not upgrade the vocabulary, do not make it more formal, and \
        never substitute a different message that merely sounds more plausible. If a word is \
        still genuinely ambiguous after reading the whole message, keep the author's original \
        word rather than inventing a new one, and say so in notes. List each concrete fix in \
        notes, for example "can not to" → "can't". If nothing needed correction, return the \
        text unchanged with an empty notes array.
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
    let version = 4

    func systemPrompt(parameters: ActionParameters, language: TextLanguage) -> String {
        """
        \(direction(parameters: parameters, language: language)) Preserve technical terms, \
        product names, and code exactly as written. primary is the translation; alternatives \
        may hold one alternate phrasing if genuinely useful, otherwise leave it empty. Notes \
        may flag terms with no clean equivalent, in the language of the input text.
        """
    }

    private func direction(parameters: ActionParameters, language: TextLanguage) -> String {
        let detected = parameters.sourceLanguage ?? language
        let target = parameters.targetLanguage ?? ActionParameters.defaultTargetLanguage(for: detected)

        guard let source = parameters.sourceLanguage, source != .other else {
            let fallback: TextLanguage = target == .english ? .russian : .english
            return """
            Detect the language of the input, then translate it into \(target.promptName). \
            If the input is already written in \(target.promptName), translate it into \
            \(fallback.promptName) instead.
            """
        }
        return "The input is in \(source.promptName); translate it into \(target.promptName)."
    }
}

private extension TextLanguage {
    var promptName: String {
        switch self {
        case .english: return "English"
        case .russian: return "Russian"
        case .ukrainian: return "Ukrainian"
        case .spanish: return "Spanish"
        case .other: return "the language the input is written in"
        }
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

private struct ShortenTemplate: PromptTemplate {
    let id = "shorten"
    let version = 1

    func systemPrompt(parameters: ActionParameters, language: TextLanguage) -> String {
        """
        Cut the message to its essential content. Remove filler, hedging, and redundant \
        phrases; combine sentences where that reads naturally. Keep every fact, number, name, \
        link, and instruction the original had — shorten wording, never meaning. primary is the \
        shortest version that still reads naturally; alternatives may offer one or two lengths \
        in between the original and primary. Notes may say roughly how much shorter it got.
        """
    }
}
