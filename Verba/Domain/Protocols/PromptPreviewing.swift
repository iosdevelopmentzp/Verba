protocol PromptPreviewing: Sendable {
    var preamble: String { get }
    func promptVersion(for action: TextAction) -> Int
    func defaultSystemPromptBody(for action: TextAction, parameters: ActionParameters, language: TextLanguage) -> String
}
