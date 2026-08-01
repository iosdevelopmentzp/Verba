struct PromptBuilder: Sendable {
    struct Prompt: Sendable, Equatable {
        let systemPrompt: String
        let userContent: String
    }

    // MARK: Public methods

    func build(action: TextAction, parameters: ActionParameters, language: TextLanguage, text: String) -> Prompt {
        guard let template = Templates.all[action.templateID] else {
            return Prompt(systemPrompt: Templates.preamble, userContent: text)
        }

        let systemPrompt = Templates.preamble + "\n\n" + template.systemPrompt(parameters: parameters, language: language)
        return Prompt(systemPrompt: systemPrompt, userContent: text)
    }

    func promptVersion(for action: TextAction) -> Int {
        Templates.all[action.templateID]?.version ?? 0
    }
}
