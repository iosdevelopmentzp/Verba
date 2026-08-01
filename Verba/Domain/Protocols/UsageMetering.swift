protocol UsageMetering: Sendable {
    func record(inputTokens: Int, outputTokens: Int, modelID: String) async
    func snapshot() async -> UsageSnapshot
}
