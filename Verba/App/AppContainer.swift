import AppKit

@MainActor
final class AppContainer {

    // MARK: Public properties

    let logger: AppLogger
    let panelWindowController: PanelWindowController
    let hotkeyController: HotkeyController
    let servicesProvider: ServicesProvider
    let settingsViewModel: SettingsViewModel

    // MARK: Private properties

    private let processTextUseCase: ProcessTextUseCase

    // MARK: Init

    init() {
        logger = AppLogger()

        let textSource = PasteboardTextSource()
        let languageDetector = NLLanguageDetector()
        let captureTextUseCase = CaptureTextUseCase(textSource: textSource, languageDetector: languageDetector)

        panelWindowController = PanelWindowController(logger: logger, captureTextUseCase: captureTextUseCase)
        hotkeyController = HotkeyController(panelController: panelWindowController, logger: logger)
        servicesProvider = ServicesProvider(
            panelController: panelWindowController,
            captureTextUseCase: captureTextUseCase,
            logger: logger
        )

        let preferences = UserDefaultsPreferenceStore()
        let secretStore = KeychainSecretStore(logger: logger)
        let providerRegistry = ProviderRegistry(clients: [ProviderID.openAI: OpenAIClient(logger: logger)])
        let promptBuilder = PromptBuilder()
        let retryPolicy = RetryPolicy()
        let resultCache = ResultCache()
        let usageMeter = UsageMeter(preferences: preferences, logger: logger)

        let textProcessor = LLMTextProcessor(
            providerRegistry: providerRegistry,
            secretStore: secretStore,
            preferences: preferences,
            promptBuilder: promptBuilder,
            usageMeter: usageMeter,
            retryPolicy: retryPolicy,
            logger: logger
        )

        processTextUseCase = ProcessTextUseCase(textProcessor: textProcessor, cache: resultCache, preferences: preferences)

        let modelOptions = ModelCatalog.models(providerID: ProviderID.openAI).map {
            SettingsViewModel.ModelOption(id: $0.id, displayName: $0.displayName, tier: $0.tier)
        }

        settingsViewModel = SettingsViewModel(
            secretStore: secretStore,
            preferences: preferences,
            modelOptions: modelOptions,
            testAPIKey: { [textProcessor] in
                await Self.testAPIKey(using: textProcessor)
            }
        )
    }

    // MARK: Lifecycle

    func start() {
        panelWindowController.start()
        hotkeyController.start()
        NSApp.servicesProvider = servicesProvider
        logger.appLaunched()
    }

    // MARK: Public methods

    #if DEBUG
    func runFixGrammarSample() {
        let sampleText = SourceText(
            content: "I dont know why this happen, can you help me pls? Its very urgent and i need fix it asap.",
            language: .english,
            origin: .manual
        )

        Task { [processTextUseCase, logger] in
            do {
                let result = try await processTextUseCase.execute(
                    text: sampleText,
                    action: ActionRegistry.all[0],
                    parameters: ActionParameters()
                )
                logger.debugSampleSucceeded(cameFromCache: result.cameFromCache)
            } catch let error as AppError {
                logger.debugSampleFailed(error)
            } catch {
                logger.debugSampleFailed(.unknown)
            }
        }
    }
    #endif

    // MARK: Private methods

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
