struct ActionResult: Sendable, Equatable {
    let primary: String
    let alternatives: [String]
    let notes: [String]
    let cameFromCache: Bool
    let tier: ModelTier
}
