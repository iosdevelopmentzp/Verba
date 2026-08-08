struct TextAction: Sendable, Identifiable, Equatable {
    enum Kind: String, Sendable {
        case fixGrammar
        case rephrase
        case changeTone
        case translate
        case humanize
        case shorten
    }

    let id: Kind
    let titleEnglish: String
    let numberKey: Int
    let templateID: String
    let tier: ModelTier
    let needsParameters: Bool
    let supportsExplanation: Bool
    let supportsDiff: Bool
}
