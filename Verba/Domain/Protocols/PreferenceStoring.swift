import Foundation

protocol PreferenceStoring: AnyObject, Sendable {
    var providerID: String { get set }
    var modelID: String { get set }
    var economyMode: Bool { get set }
    var defaultLevel: LanguageLevel { get set }
    var lastTone: Tone? { get set }
    var lastLevel: LanguageLevel? { get set }
    var lastCreativity: Creativity { get set }
    var isDiffVisible: Bool { get set }
    var isSidebarExpanded: Bool { get set }
    var panelOriginX: Double? { get set }
    var panelTopY: Double? { get set }
    var lastSourceLanguage: TextLanguage? { get set }
    var lastTargetLanguage: TextLanguage? { get set }
    var promptOverrides: [String: String] { get set }
    var monthlyBudgetUSD: Decimal { get set }
    var launchAtLogin: Bool { get set }
    var hasCompletedOnboarding: Bool { get set }
}
