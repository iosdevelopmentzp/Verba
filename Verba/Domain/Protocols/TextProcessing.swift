struct LLMCacheIdentity: Sendable, Equatable {
    let modelID: String
    let promptVersion: Int
}

protocol TextProcessing: Sendable {
    func process(
        _ text: SourceText,
        action: TextAction,
        parameters: ActionParameters,
        tier: ModelTier
    ) async throws -> ActionResult

    func cacheIdentity(for action: TextAction, tier: ModelTier) -> LLMCacheIdentity
}
