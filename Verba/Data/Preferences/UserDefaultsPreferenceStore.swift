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

    var lastTone: Tone? {
        get { defaults.string(forKey: Keys.lastTone).flatMap(Tone.init(rawValue:)) }
        set { defaults.set(newValue?.rawValue, forKey: Keys.lastTone) }
    }

    var lastLevel: LanguageLevel? {
        get { defaults.string(forKey: Keys.lastLevel).flatMap(LanguageLevel.init(rawValue:)) }
        set { defaults.set(newValue?.rawValue, forKey: Keys.lastLevel) }
    }

    var lastCreativity: Creativity {
        get { Creativity(rawValue: defaults.string(forKey: Keys.lastCreativity) ?? "") ?? .balanced }
        set { defaults.set(newValue.rawValue, forKey: Keys.lastCreativity) }
    }

    var isDiffVisible: Bool {
        get { defaults.object(forKey: Keys.isDiffVisible) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.isDiffVisible) }
    }

    var isSidebarExpanded: Bool {
        get { defaults.bool(forKey: Keys.isSidebarExpanded) }
        set { defaults.set(newValue, forKey: Keys.isSidebarExpanded) }
    }

    var panelAppearance: PanelAppearance {
        get { PanelAppearance(rawValue: defaults.string(forKey: Keys.panelAppearance) ?? "") ?? .light }
        set { defaults.set(newValue.rawValue, forKey: Keys.panelAppearance) }
    }

    var panelOriginX: Double? {
        get { defaults.object(forKey: Keys.panelOriginX) as? Double }
        set { defaults.set(newValue, forKey: Keys.panelOriginX) }
    }

    var panelTopY: Double? {
        get { defaults.object(forKey: Keys.panelTopY) as? Double }
        set { defaults.set(newValue, forKey: Keys.panelTopY) }
    }

    var lastSourceLanguage: TextLanguage? {
        get { defaults.string(forKey: Keys.lastSourceLanguage).flatMap(TextLanguage.init(rawValue:)) }
        set { defaults.set(newValue?.rawValue, forKey: Keys.lastSourceLanguage) }
    }

    var lastTargetLanguage: TextLanguage? {
        get { defaults.string(forKey: Keys.lastTargetLanguage).flatMap(TextLanguage.init(rawValue:)) }
        set { defaults.set(newValue?.rawValue, forKey: Keys.lastTargetLanguage) }
    }

    var promptOverrides: [String: String] {
        get { defaults.dictionary(forKey: Keys.promptOverrides) as? [String: String] ?? [:] }
        set { defaults.set(newValue, forKey: Keys.promptOverrides) }
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
        static let lastTone = "preferences.lastTone"
        static let lastLevel = "preferences.lastLevel"
        static let lastCreativity = "preferences.lastCreativity"
        static let isDiffVisible = "preferences.isDiffVisible"
        static let isSidebarExpanded = "preferences.isSidebarExpanded"
        static let panelAppearance = "preferences.panelAppearance"
        static let panelOriginX = "preferences.panelOriginX"
        static let panelTopY = "preferences.panelTopY"
        static let lastSourceLanguage = "preferences.lastSourceLanguage"
        static let lastTargetLanguage = "preferences.lastTargetLanguage"
        static let promptOverrides = "preferences.promptOverrides"
        static let monthlyBudgetUSD = "preferences.monthlyBudgetUSD"
        static let launchAtLogin = "preferences.launchAtLogin"
        static let hasCompletedOnboarding = "preferences.hasCompletedOnboarding"
    }

    // MARK: Init

    init() {}
}
