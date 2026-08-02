import Foundation

struct UserDefaultsSecretStore: SecretStoring {

    // MARK: Static

    private static let keyPrefix = "com.dmytrovorko.verba.debug.apikey."

    // MARK: Public methods

    func apiKey(for providerID: String) throws -> String? {
        UserDefaults.standard.string(forKey: Self.key(for: providerID))
    }

    func setAPIKey(_ key: String?, for providerID: String) throws {
        guard let key, key.isEmpty == false else {
            UserDefaults.standard.removeObject(forKey: Self.key(for: providerID))
            return
        }
        UserDefaults.standard.set(key, forKey: Self.key(for: providerID))
    }

    // MARK: Private methods

    private static func key(for providerID: String) -> String {
        keyPrefix + providerID
    }
}
