import Foundation

struct ProcessTextUseCase: Sendable {

    // MARK: Dependencies

    private let textProcessor: TextProcessing
    private let cache: ResultCaching
    private let preferences: PreferenceStoring

    // MARK: Static

    private static let cacheKeyLength = 32

    // MARK: Init

    init(textProcessor: TextProcessing, cache: ResultCaching, preferences: PreferenceStoring) {
        self.textProcessor = textProcessor
        self.cache = cache
        self.preferences = preferences
    }

    // MARK: Public methods

    func execute(
        text: SourceText,
        action: TextAction,
        parameters: ActionParameters
    ) async throws -> ActionResult {
        let trimmed = text.content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { throw AppError.emptyInput }
        guard trimmed.count <= InputLimits.hardMax else {
            throw AppError.inputTooLong(actual: trimmed.count, limit: InputLimits.hardMax)
        }

        let tier = preferences.economyMode ? ModelTier.economy : action.tier
        let identity = textProcessor.cacheIdentity(for: action, tier: tier)
        let key = Self.cacheKey(
            actionID: action.id.rawValue,
            modelID: identity.modelID,
            promptVersion: identity.promptVersion,
            parameters: parameters,
            text: trimmed
        )

        if let cached = await cache.value(for: key) {
            return ActionResult(
                primary: cached.primary,
                alternatives: cached.alternatives,
                notes: cached.notes,
                cameFromCache: true
            )
        }

        let trimmedText = SourceText(content: trimmed, language: text.language, origin: text.origin)

        do {
            let result = try await textProcessor.process(trimmedText, action: action, parameters: parameters, tier: tier)
            await cache.store(result, for: key)
            return result
        } catch is CancellationError {
            throw AppError.cancelled
        } catch let error as AppError {
            throw error
        } catch {
            throw AppError.unknown
        }
    }

    // MARK: Private methods

    private static func cacheKey(
        actionID: String,
        modelID: String,
        promptVersion: Int,
        parameters: ActionParameters,
        text: String
    ) -> String {
        let parameterDescription = [
            parameters.tone?.rawValue ?? "",
            parameters.level?.rawValue ?? "",
            parameters.targetLanguage?.rawValue ?? ""
        ].joined(separator: ",")

        let raw = "\(actionID)|\(modelID)|\(promptVersion)|\(parameterDescription)|\(text)"
        return CacheKeyHasher.hexDigest(raw, truncatedTo: cacheKeyLength)
    }
}
