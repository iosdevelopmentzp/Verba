protocol LLMClient: Sendable {
    var providerID: String { get }
    func complete(_ request: LLMRequest, apiKey: String) async throws -> LLMResponse
}
