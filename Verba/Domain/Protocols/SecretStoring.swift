protocol SecretStoring: Sendable {
    func apiKey(for providerID: String) throws -> String?
    func setAPIKey(_ key: String?, for providerID: String) throws
}
