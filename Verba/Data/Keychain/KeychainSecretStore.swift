import Foundation
import Security

struct KeychainSecretStore: SecretStoring {

    // MARK: Dependencies

    private let logger: AppLogger

    // MARK: Static

    private static let service = "com.dmytrovorko.verba.apikey"

    // MARK: Init

    init(logger: AppLogger) {
        self.logger = logger
    }

    // MARK: Public methods

    func apiKey(for providerID: String) throws -> String? {
        var query = Self.baseQuery(account: providerID)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        switch status {
        case errSecSuccess:
            guard let data = item as? Data, let key = String(data: data, encoding: .utf8) else {
                logger.keychainRead(providerID: providerID, found: false)
                throw AppError.unknown
            }
            logger.keychainRead(providerID: providerID, found: true)
            return key
        case errSecItemNotFound:
            logger.keychainRead(providerID: providerID, found: false)
            return nil
        default:
            logger.keychainRead(providerID: providerID, found: false)
            throw AppError.unknown
        }
    }

    func setAPIKey(_ key: String?, for providerID: String) throws {
        let query = Self.baseQuery(account: providerID)

        guard let key, key.isEmpty == false else {
            let status = SecItemDelete(query as CFDictionary)
            let success = status == errSecSuccess || status == errSecItemNotFound
            logger.keychainDelete(providerID: providerID, success: success)
            guard success else { throw AppError.unknown }
            return
        }

        guard let data = key.data(using: .utf8) else { throw AppError.unknown }

        SecItemDelete(query as CFDictionary)

        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        let success = addStatus == errSecSuccess
        logger.keychainWrite(providerID: providerID, success: success)
        guard success else { throw AppError.unknown }
    }

    // MARK: Private methods

    private static func baseQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: false
        ]
    }
}
