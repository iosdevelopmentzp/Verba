enum ModelTier: String, Sendable, Codable {
    case standard
    case economy
}

extension ModelTier {
    static func effective(for action: TextAction, preferences: PreferenceStoring) -> ModelTier {
        preferences.economyMode ? .economy : action.tier
    }
}
