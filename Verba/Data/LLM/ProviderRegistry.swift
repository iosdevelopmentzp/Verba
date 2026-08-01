struct ProviderRegistry: Sendable {

    // MARK: Private properties

    private let clients: [String: LLMClient]

    // MARK: Init

    init(clients: [String: LLMClient] = [ProviderID.openAI: OpenAIClient()]) {
        self.clients = clients
    }

    // MARK: Public methods

    func client(for providerID: String) -> LLMClient? {
        clients[providerID]
    }
}
