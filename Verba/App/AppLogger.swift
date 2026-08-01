import os

struct AppLogger: Sendable {

    // MARK: Private properties

    private let app: Logger
    private let hotkey: Logger
    private let panel: Logger
    private let capture: Logger
    private let llm: Logger
    private let keychain: Logger
    private let usage: Logger

    // MARK: Static

    private static let subsystem = "com.dmytrovorko.verba"

    // MARK: Init

    init() {
        app = Logger(subsystem: Self.subsystem, category: "app")
        hotkey = Logger(subsystem: Self.subsystem, category: "hotkey")
        panel = Logger(subsystem: Self.subsystem, category: "panel")
        capture = Logger(subsystem: Self.subsystem, category: "capture")
        llm = Logger(subsystem: Self.subsystem, category: "llm")
        keychain = Logger(subsystem: Self.subsystem, category: "keychain")
        usage = Logger(subsystem: Self.subsystem, category: "usage")
    }

    // MARK: Public methods

    func appLaunched() {
        app.notice("app launched")
    }

    func hotkeyRegistered() {
        hotkey.notice("hotkey registered")
    }

    func panelShown(windowCount: Int) {
        panel.notice("panel shown windowCount=\(windowCount)")
    }

    func panelHidden(windowCount: Int) {
        panel.notice("panel hidden windowCount=\(windowCount)")
    }

    func textCaptured(charCount: Int, origin: String, language: TextLanguage) {
        capture.notice(
            "captured charCount=\(charCount, privacy: .public) origin=\(origin, privacy: .public) language=\(language.rawValue, privacy: .public)"
        )
    }

    func textCaptureFailed(_ error: AppError) {
        capture.notice("capture failed error=\(String(describing: error), privacy: .public)")
    }

    func serviceInvoked(charCount: Int) {
        capture.notice("service invoked charCount=\(charCount, privacy: .public)")
    }

    func llmRequestSucceeded(
        actionID: String,
        modelID: String,
        charCount: Int,
        latencyMS: Int,
        inputTokens: Int,
        outputTokens: Int
    ) {
        llm.notice(
            """
            request succeeded action=\(actionID, privacy: .public) model=\(modelID, privacy: .public) \
            charCount=\(charCount, privacy: .public) latencyMS=\(latencyMS, privacy: .public) \
            inputTokens=\(inputTokens, privacy: .public) outputTokens=\(outputTokens, privacy: .public)
            """
        )
    }

    func llmRequestFailed(actionID: String, modelID: String, error: AppError) {
        llm.notice(
            "request failed action=\(actionID, privacy: .public) model=\(modelID, privacy: .public) error=\(String(describing: error), privacy: .public)"
        )
    }

    func llmHTTPStatus(_ status: Int, byteCount: Int) {
        llm.notice("http status=\(status, privacy: .public) byteCount=\(byteCount, privacy: .public)")
    }

    func llmCacheHit(actionID: String, charCount: Int) {
        llm.notice("cache hit action=\(actionID, privacy: .public) charCount=\(charCount, privacy: .public)")
    }

    func keychainRead(providerID: String, found: Bool) {
        keychain.notice("read providerID=\(providerID, privacy: .public) found=\(found, privacy: .public)")
    }

    func keychainWrite(providerID: String, success: Bool) {
        keychain.notice("write providerID=\(providerID, privacy: .public) success=\(success, privacy: .public)")
    }

    func keychainDelete(providerID: String, success: Bool) {
        keychain.notice("delete providerID=\(providerID, privacy: .public) success=\(success, privacy: .public)")
    }

    func usageRecorded(modelID: String, inputTokens: Int, outputTokens: Int) {
        usage.notice(
            "recorded model=\(modelID, privacy: .public) inputTokens=\(inputTokens, privacy: .public) outputTokens=\(outputTokens, privacy: .public)"
        )
    }
}
