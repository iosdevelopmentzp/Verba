import Foundation

struct PromptBuilder: Sendable {
    struct Prompt: Sendable, Equatable {
        let systemPrompt: String
        let userContent: String
    }

    // MARK: Public methods

    func build(action: TextAction, parameters: ActionParameters, language: TextLanguage, text: String) -> Prompt {
        Prompt(
            systemPrompt: fullSystemPrompt(
                for: action,
                parameters: parameters,
                language: language,
                characterCount: text.count
            ),
            userContent: text
        )
    }

    func fullSystemPrompt(
        for action: TextAction,
        parameters: ActionParameters,
        language: TextLanguage,
        characterCount: Int
    ) -> String {
        var sections = [Templates.preamble]

        let body = parameters.systemPromptOverride ?? defaultSystemPromptBody(
            for: action,
            parameters: parameters,
            language: language
        )
        if body.isEmpty == false {
            sections.append(body)
        }

        if let creativity = Templates.creativitySection(parameters.creativity) {
            sections.append(creativity)
        }

        if OutputBudget.allowsAlternatives(action: action, characterCount: characterCount) == false {
            sections.append(Templates.singleOptionSection)
        }

        let instruction = parameters.extraInstruction?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if instruction.isEmpty == false {
            sections.append(Templates.extraInstructionSection(instruction))
        }

        return sections.joined(separator: "\n\n")
    }

    func defaultSystemPromptBody(for action: TextAction, parameters: ActionParameters, language: TextLanguage) -> String {
        guard let template = Templates.all[action.templateID] else { return "" }
        return template.systemPrompt(parameters: parameters, language: language)
    }

    func promptVersion(for action: TextAction) -> Int {
        Templates.all[action.templateID]?.version ?? 0
    }
}
