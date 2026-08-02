import Foundation

final class LLMTextProcessor: TextProcessing {

    // MARK: Dependencies

    private let providerRegistry: ProviderRegistry
    private let secretStore: SecretStoring
    private let preferences: PreferenceStoring
    private let promptBuilder: PromptBuilder
    private let usageMeter: UsageMetering
    private let retryPolicy: RetryPolicy
    private let logger: AppLogger

    // MARK: Static

    private static let strictInstruction = "Return ONLY valid JSON matching the schema."

    // Reasoning tokens are billed against max_output_tokens and can exhaust it before any visible output.
    private static let minimumOutputTokens = 700
    private static let maxOutputTokensCeiling = 2000

    private static let responseSchema: [String: JSONValue] = [
        "type": "object",
        "additionalProperties": false,
        "required": ["primary", "alternatives", "notes"],
        "properties": [
            "primary": ["type": "string"],
            "alternatives": ["type": "array", "maxItems": 3, "items": ["type": "string"]],
            "notes": ["type": "array", "maxItems": 4, "items": ["type": "string"]]
        ]
    ]

    // MARK: Init

    init(
        providerRegistry: ProviderRegistry,
        secretStore: SecretStoring,
        preferences: PreferenceStoring,
        promptBuilder: PromptBuilder,
        usageMeter: UsageMetering,
        retryPolicy: RetryPolicy,
        logger: AppLogger
    ) {
        self.providerRegistry = providerRegistry
        self.secretStore = secretStore
        self.preferences = preferences
        self.promptBuilder = promptBuilder
        self.usageMeter = usageMeter
        self.retryPolicy = retryPolicy
        self.logger = logger
    }

    // MARK: Public methods

    func process(
        _ text: SourceText,
        action: TextAction,
        parameters: ActionParameters,
        tier: ModelTier
    ) async throws -> ActionResult {
        guard let client = providerRegistry.client(for: preferences.providerID) else {
            throw AppError.unknown
        }
        guard let apiKey = try secretStore.apiKey(for: preferences.providerID), apiKey.isEmpty == false else {
            throw AppError.missingAPIKey
        }

        let identity = cacheIdentity(for: action, tier: tier)
        let prompt = promptBuilder.build(
            action: action,
            parameters: parameters,
            language: text.language,
            text: text.content
        )
        let maxOutputTokens = Self.maxOutputTokens(forCharacterCount: text.content.count)

        let clock = ContinuousClock()
        let start = clock.now

        do {
            let outcome = try await runRequest(
                client: client,
                apiKey: apiKey,
                modelID: identity.modelID,
                systemPrompt: prompt.systemPrompt,
                userContent: prompt.userContent,
                maxOutputTokens: maxOutputTokens,
                tier: tier
            )

            logger.llmRequestSucceeded(
                actionID: action.id.rawValue,
                modelID: identity.modelID,
                charCount: text.content.count,
                latencyMS: Self.milliseconds(clock.now - start),
                inputTokens: outcome.inputTokens,
                outputTokens: outcome.outputTokens
            )
            await usageMeter.record(
                inputTokens: outcome.inputTokens,
                outputTokens: outcome.outputTokens,
                modelID: identity.modelID
            )
            return outcome.result
        } catch let error as AppError {
            logger.llmRequestFailed(actionID: action.id.rawValue, modelID: identity.modelID, error: error)
            throw error
        } catch is CancellationError {
            throw AppError.cancelled
        } catch {
            throw AppError.unknown
        }
    }

    func cacheIdentity(for action: TextAction, tier: ModelTier) -> LLMCacheIdentity {
        LLMCacheIdentity(modelID: resolvedModelID(for: tier), promptVersion: promptBuilder.promptVersion(for: action))
    }

    // MARK: Private methods

    private func runRequest(
        client: LLMClient,
        apiKey: String,
        modelID: String,
        systemPrompt: String,
        userContent: String,
        maxOutputTokens: Int,
        tier: ModelTier
    ) async throws -> (result: ActionResult, inputTokens: Int, outputTokens: Int) {
        do {
            return try await requestWithRetry(
                client: client,
                apiKey: apiKey,
                modelID: modelID,
                systemPrompt: systemPrompt,
                userContent: userContent,
                maxOutputTokens: maxOutputTokens,
                tier: tier,
                strict: false
            )
        } catch AppError.malformedResponse {
            return try await singleAttempt(
                client: client,
                apiKey: apiKey,
                modelID: modelID,
                systemPrompt: systemPrompt,
                userContent: userContent,
                maxOutputTokens: maxOutputTokens,
                tier: tier,
                strict: true
            )
        }
    }

    private func requestWithRetry(
        client: LLMClient,
        apiKey: String,
        modelID: String,
        systemPrompt: String,
        userContent: String,
        maxOutputTokens: Int,
        tier: ModelTier,
        strict: Bool
    ) async throws -> (result: ActionResult, inputTokens: Int, outputTokens: Int) {
        do {
            return try await singleAttempt(
                client: client,
                apiKey: apiKey,
                modelID: modelID,
                systemPrompt: systemPrompt,
                userContent: userContent,
                maxOutputTokens: maxOutputTokens,
                tier: tier,
                strict: strict
            )
        } catch let error as AppError where retryPolicy.shouldRetry(error) {
            try await Task.sleep(for: retryPolicy.delay(for: error))
            return try await singleAttempt(
                client: client,
                apiKey: apiKey,
                modelID: modelID,
                systemPrompt: systemPrompt,
                userContent: userContent,
                maxOutputTokens: maxOutputTokens,
                tier: tier,
                strict: strict
            )
        }
    }

    private func singleAttempt(
        client: LLMClient,
        apiKey: String,
        modelID: String,
        systemPrompt: String,
        userContent: String,
        maxOutputTokens: Int,
        tier: ModelTier,
        strict: Bool
    ) async throws -> (result: ActionResult, inputTokens: Int, outputTokens: Int) {
        let finalSystemPrompt = strict ? systemPrompt + "\n\n" + Self.strictInstruction : systemPrompt

        let request = LLMRequest(
            modelID: modelID,
            systemPrompt: finalSystemPrompt,
            userContent: userContent,
            jsonSchema: Self.responseSchema,
            maxOutputTokens: maxOutputTokens,
            minimalReasoningEffort: true
        )

        var response = try await client.complete(request, apiKey: apiKey)

        if response.isTruncated {
            let widened = LLMRequest(
                modelID: modelID,
                systemPrompt: finalSystemPrompt,
                userContent: userContent,
                jsonSchema: Self.responseSchema,
                maxOutputTokens: min(Self.maxOutputTokensCeiling, maxOutputTokens * 2),
                minimalReasoningEffort: true
            )
            response = try await client.complete(widened, apiKey: apiKey)
        }

        guard response.isTruncated == false else { throw AppError.malformedResponse }

        let payload = try Self.decodePayload(from: response.rawJSON)

        let result = ActionResult(
            primary: Self.sanitize(payload.primary),
            alternatives: payload.alternatives.map(Self.sanitize),
            notes: payload.notes,
            cameFromCache: false,
            tier: tier
        )
        return (result, response.inputTokens, response.outputTokens)
    }

    private static func sanitize(_ text: String) -> String {
        Self.stripSemicolons(Self.stripEmDash(text))
    }

    private static func stripEmDash(_ text: String) -> String {
        text.replacingOccurrences(of: "—", with: "-")
    }

    private static func stripSemicolons(_ text: String) -> String {
        text.replacingOccurrences(of: ";", with: ",")
    }

    private static func decodePayload(from data: Data) throws -> ActionResultPayload {
        do {
            return try JSONDecoder().decode(ActionResultPayload.self, from: data)
        } catch {
            throw AppError.malformedResponse
        }
    }

    private func resolvedModelID(for tier: ModelTier) -> String {
        if tier == .standard,
           let entry = ModelCatalog.entry(id: preferences.modelID),
           entry.providerID == preferences.providerID,
           entry.tier == .standard {
            return entry.id
        }
        return ModelCatalog.defaultModel(providerID: preferences.providerID, tier: tier)?.id ?? preferences.modelID
    }

    private static func maxOutputTokens(forCharacterCount count: Int) -> Int {
        let inputTokenEstimate = count / 3
        return min(maxOutputTokensCeiling, max(minimumOutputTokens, inputTokenEstimate * 2 + 200))
    }

    private static func milliseconds(_ duration: Duration) -> Int {
        let components = duration.components
        return Int(components.seconds * 1000) + Int(components.attoseconds / 1_000_000_000_000_000)
    }
}

private struct ActionResultPayload: Decodable {
    let primary: String
    let alternatives: [String]
    let notes: [String]
}
