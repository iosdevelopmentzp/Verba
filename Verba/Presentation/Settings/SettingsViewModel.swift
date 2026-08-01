import Observation
import KeyboardShortcuts

@MainActor
@Observable
final class SettingsViewModel {
    struct ModelOption: Identifiable, Sendable, Equatable {
        let id: String
        let displayName: String
        let tier: ModelTier
    }

    enum KeyTestState: Equatable {
        case idle
        case testing
        case success
        case failure(AppError)
    }

    // MARK: Dependencies

    private let secretStore: SecretStoring
    private let preferences: PreferenceStoring
    private let testAPIKey: @Sendable () async -> AppError?

    // MARK: Public properties

    let shortcutName = KeyboardShortcuts.Name.togglePanel
    let modelOptions: [ModelOption]

    var apiKeyInput: String = ""
    private(set) var keyTestState: KeyTestState = .idle

    var economyMode: Bool {
        get { preferences.economyMode }
        set { preferences.economyMode = newValue }
    }

    var selectedModelID: String {
        get { preferences.modelID }
        set { preferences.modelID = newValue }
    }

    // MARK: Private properties

    private var testTask: Task<Void, Never>?

    // MARK: Init

    init(
        secretStore: SecretStoring,
        preferences: PreferenceStoring,
        modelOptions: [ModelOption],
        testAPIKey: @escaping @Sendable () async -> AppError?
    ) {
        self.secretStore = secretStore
        self.preferences = preferences
        self.modelOptions = modelOptions
        self.testAPIKey = testAPIKey
    }

    // MARK: Lifecycle

    func start() {
        guard let key = try? secretStore.apiKey(for: preferences.providerID) else { return }
        apiKeyInput = key
    }

    // MARK: Public methods

    func saveAPIKey() {
        try? secretStore.setAPIKey(apiKeyInput.isEmpty ? nil : apiKeyInput, for: preferences.providerID)
    }

    func testKey() {
        saveAPIKey()
        testTask?.cancel()
        keyTestState = .testing

        testTask = Task { [testAPIKey] in
            let error = await testAPIKey()
            guard Task.isCancelled == false else { return }
            keyTestState = error.map(KeyTestState.failure) ?? .success
        }
    }

    func cancelTesting() {
        testTask?.cancel()
        testTask = nil
    }
}
