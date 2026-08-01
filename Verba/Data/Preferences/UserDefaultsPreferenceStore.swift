import Foundation

final class UserDefaultsPreferenceStore: PreferenceStoring {

    // MARK: Public properties

    var providerID: String {
        get { defaults.string(forKey: Keys.providerID) ?? ProviderID.openAI }
        set { defaults.set(newValue, forKey: Keys.providerID) }
    }

    var modelID: String {
        get {
            defaults.string(forKey: Keys.modelID)
                ?? ModelCatalog.defaultModel(providerID: providerID, tier: .standard)?.id
                ?? ""
        }
        set { defaults.set(newValue, forKey: Keys.modelID) }
    }

    var economyMode: Bool {
        get { defaults.bool(forKey: Keys.economyMode) }
        set { defaults.set(newValue, forKey: Keys.economyMode) }
    }

    var defaultLevel: LanguageLevel {
        get { LanguageLevel(rawValue: defaults.string(forKey: Keys.defaultLevel) ?? "") ?? .b2 }
        set { defaults.set(newValue.rawValue, forKey: Keys.defaultLevel) }
    }

    var monthlyBudgetUSD: Decimal {
        get {
            guard let stored = defaults.object(forKey: Keys.monthlyBudgetUSD) as? NSDecimalNumber else {
                return Self.defaultMonthlyBudgetUSD
            }
            return stored.decimalValue
        }
        set { defaults.set(NSDecimalNumber(decimal: newValue), forKey: Keys.monthlyBudgetUSD) }
    }

    var launchAtLogin: Bool {
        get { defaults.bool(forKey: Keys.launchAtLogin) }
        set { defaults.set(newValue, forKey: Keys.launchAtLogin) }
    }

    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: Keys.hasCompletedOnboarding) }
        set { defaults.set(newValue, forKey: Keys.hasCompletedOnboarding) }
    }

    // MARK: Private properties

    private var defaults: UserDefaults { .standard }

    // MARK: Static

    private static let defaultMonthlyBudgetUSD: Decimal = 5

    private enum Keys {
        static let providerID = "preferences.providerID"
        static let modelID = "preferences.modelID"
        static let economyMode = "preferences.economyMode"
        static let defaultLevel = "preferences.defaultLevel"
        static let monthlyBudgetUSD = "preferences.monthlyBudgetUSD"
        static let launchAtLogin = "preferences.launchAtLogin"
        static let hasCompletedOnboarding = "preferences.hasCompletedOnboarding"
    }

    // MARK: Init

    init() {}
}
