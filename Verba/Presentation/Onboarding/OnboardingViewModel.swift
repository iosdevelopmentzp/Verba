import Observation

@MainActor
@Observable
final class OnboardingViewModel {

    // MARK: Dependencies

    private let preferences: PreferenceStoring
    private let setLaunchAtLogin: @Sendable (Bool) async -> Bool

    // MARK: Public properties

    let settings: SettingsViewModel

    private(set) var launchAtLogin: Bool

    var isComplete: Bool { preferences.hasCompletedOnboarding }

    // MARK: Private properties

    private var loginItemTask: Task<Void, Never>?

    // MARK: Init

    init(
        settings: SettingsViewModel,
        preferences: PreferenceStoring,
        launchAtLogin: Bool,
        setLaunchAtLogin: @escaping @Sendable (Bool) async -> Bool
    ) {
        self.settings = settings
        self.preferences = preferences
        self.launchAtLogin = launchAtLogin
        self.setLaunchAtLogin = setLaunchAtLogin
    }

    // MARK: Public methods

    func updateLaunchAtLogin(_ enabled: Bool) {
        loginItemTask?.cancel()
        loginItemTask = Task { [weak self] in
            guard let self else { return }
            let actual = await setLaunchAtLogin(enabled)
            guard Task.isCancelled == false else { return }
            launchAtLogin = actual
        }
    }

    func finish() {
        preferences.hasCompletedOnboarding = true
    }
}
