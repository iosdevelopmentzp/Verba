import Foundation

protocol PreferenceStoring: AnyObject, Sendable {
    var providerID: String { get set }
    var modelID: String { get set }
    var economyMode: Bool { get set }
    var defaultLevel: LanguageLevel { get set }
    var monthlyBudgetUSD: Decimal { get set }
    var launchAtLogin: Bool { get set }
    var hasCompletedOnboarding: Bool { get set }
}
