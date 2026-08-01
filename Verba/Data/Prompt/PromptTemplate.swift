protocol PromptTemplate: Sendable {
    var id: String { get }
    var version: Int { get }
    func systemPrompt(parameters: ActionParameters, language: TextLanguage) -> String
}
