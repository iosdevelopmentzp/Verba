import AppKit

@MainActor
final class AppContainer {

    // MARK: Public properties

    let logger: AppLogger
    let panelWindowController: PanelWindowController
    let hotkeyController: HotkeyController
    let servicesProvider: ServicesProvider
    let settingsViewModel: SettingsViewModel
    let menuBarViewModel: MenuBarViewModel
    let onboardingViewModel: OnboardingViewModel
    let needsOnboarding: Bool

    // MARK: Private properties

    private let loginItemController: LoginItemController

    // MARK: Init

    init() {
        logger = AppLogger()

        let textSource = PasteboardTextSource()
        let languageDetector = NLLanguageDetector()
        let captureTextUseCase = CaptureTextUseCase(textSource: textSource, languageDetector: languageDetector)

        let preferences = UserDefaultsPreferenceStore()
        #if DEBUG
        let secretStore: SecretStoring = UserDefaultsSecretStore()
        #else
        let secretStore: SecretStoring = KeychainSecretStore(logger: logger)
        #endif
        let providerRegistry = ProviderRegistry(clients: [ProviderID.openAI: OpenAIClient(logger: logger)])
        let promptBuilder = PromptBuilder()
        let retryPolicy = RetryPolicy()
        let resultCache = ResultCache()
        let usageMeter = UsageMeter(preferences: preferences, logger: logger)
        let speechSynthesizer = SystemSpeechSynthesizer()

        let textProcessor = LLMTextProcessor(
            providerRegistry: providerRegistry,
            secretStore: secretStore,
            preferences: preferences,
            promptBuilder: promptBuilder,
            usageMeter: usageMeter,
            retryPolicy: retryPolicy,
            logger: logger
        )

        let processTextUseCase = ProcessTextUseCase(textProcessor: textProcessor, cache: resultCache, preferences: preferences)
        let deliverResultUseCase = DeliverResultUseCase(resultDeliverer: PasteboardResultSink())
        let explainFixesUseCase = ExplainFixesUseCase(explainer: textProcessor)

        panelWindowController = PanelWindowController(
            logger: logger,
            captureTextUseCase: captureTextUseCase,
            processTextUseCase: processTextUseCase,
            deliverResultUseCase: deliverResultUseCase,
            explainFixesUseCase: explainFixesUseCase,
            promptPreview: PromptPreview(promptBuilder: promptBuilder),
            speechSynthesizer: speechSynthesizer,
            preferences: preferences,
            usageMeter: usageMeter
        )
        hotkeyController = HotkeyController(panelController: panelWindowController, logger: logger)
        servicesProvider = ServicesProvider(
            panelController: panelWindowController,
            captureTextUseCase: captureTextUseCase,
            logger: logger
        )
        menuBarViewModel = MenuBarViewModel(usageMeter: usageMeter)

        let modelOptions = ModelCatalog.models(providerID: ProviderID.openAI).map {
            SettingsViewModel.ModelOption(id: $0.id, displayName: $0.displayName, tier: $0.tier)
        }

        settingsViewModel = SettingsViewModel(
            secretStore: secretStore,
            preferences: preferences,
            modelOptions: modelOptions,
            speechSynthesizer: speechSynthesizer,
            openVoiceSettings: { NSWorkspace.shared.open(Self.accessibilitySettingsURL) },
            testAPIKey: { [textProcessor] in
                await Self.testAPIKey(using: textProcessor)
            }
        )

        let loginItemController = LoginItemController(preferences: preferences, logger: logger)
        self.loginItemController = loginItemController
        needsOnboarding = preferences.hasCompletedOnboarding == false
        onboardingViewModel = OnboardingViewModel(
            settings: settingsViewModel,
            preferences: preferences,
            launchAtLogin: loginItemController.isEnabled,
            setLaunchAtLogin: { enabled in
                await loginItemController.setEnabled(enabled)
                return loginItemController.isEnabled
            }
        )
    }

    // MARK: Lifecycle

    func start() {
        loginItemController.syncPreferenceOnLaunch()
        panelWindowController.start()
        hotkeyController.start()
        NSApp.servicesProvider = servicesProvider
        logger.appLaunched()
    }

    // MARK: Private methods

    // The Spoken Content anchor is not published, so this opens Accessibility's root
    // pane; the Settings copy names the rest of the path.
    private static let accessibilitySettingsURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.universalaccess"
    )!

    private static func testAPIKey(using processor: TextProcessing) async -> AppError? {
        let sampleText = SourceText(content: "Ping.", language: .english, origin: .manual)
        do {
            _ = try await processor.process(
                sampleText,
                action: ActionRegistry.all[0],
                parameters: ActionParameters(),
                tier: .economy
            )
            return nil
        } catch let error as AppError {
            return error
        } catch {
            return .unknown
        }
    }
}
