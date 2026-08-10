struct PromptPreview: PromptPreviewing {

    // MARK: Dependencies

    private let promptBuilder: PromptBuilder

    // MARK: Public properties

    var preamble: String { Templates.preamble }

    // MARK: Init

    init(promptBuilder: PromptBuilder = PromptBuilder()) {
        self.promptBuilder = promptBuilder
    }

    // MARK: Public methods

    func promptVersion(for action: TextAction) -> Int {
        promptBuilder.promptVersion(for: action)
    }

    func defaultSystemPromptBody(for action: TextAction, parameters: ActionParameters, language: TextLanguage) -> String {
        promptBuilder.defaultSystemPromptBody(for: action, parameters: parameters, language: language)
    }
}
