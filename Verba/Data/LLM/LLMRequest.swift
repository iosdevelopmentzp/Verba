struct LLMRequest: Sendable {
    let modelID: String
    let systemPrompt: String
    let userContent: String
    let jsonSchema: [String: JSONValue]
    let maxOutputTokens: Int
    let creativity: Creativity
}
