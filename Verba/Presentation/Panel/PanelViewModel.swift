import Observation
import SwiftUI

enum PanelState: Equatable {
    case capturing
    case manualEntry(draft: String)
    case picking(source: SourceText, selectedIndex: Int)
    case parameterPicking(source: SourceText, action: TextAction, selectedIndex: Int)
    case running(source: SourceText, action: TextAction)
    case result(source: SourceText, action: TextAction, result: ActionResult)
    case failed(source: SourceText?, action: TextAction?, error: AppError)
}

@MainActor
@Observable
final class PanelViewModel {

    // MARK: Dependencies

    private let captureTextUseCase: CaptureTextUseCase
    private let processTextUseCase: ProcessTextUseCase
    private let deliverResultUseCase: DeliverResultUseCase
    private let preferences: PreferenceStoring
    private let usageMeter: UsageMetering
    private let logger: AppLogger

    // MARK: Public properties

    private(set) var state: PanelState = .capturing
    private(set) var isHUDVisible = false
    private(set) var usageSnapshot: UsageSnapshot?

    var onRequestClose: (() -> Void)?
    var onOpenSettingsRequested: (() -> Void)?
    var onOpenSystemSettingsRequested: (() -> Void)?

    var isOverBudget: Bool {
        guard let usageSnapshot else { return false }
        return usageSnapshot.costMonthUSD > usageSnapshot.budgetMonthUSD
    }

    var manualDraft: String {
        guard case .manualEntry(let draft) = state else { return "" }
        return draft
    }

    // MARK: Private properties

    private var task: Task<Void, Never>?
    private var currentParameters = ActionParameters()

    // MARK: Static

    private static let hudDisplayDuration: Duration = .milliseconds(650)
    private static let shiftedDigitSymbols: [Character: Int] = ["!": 1, "@": 2, "#": 3, "$": 4, "%": 5]

    // MARK: Init

    init(
        captureTextUseCase: CaptureTextUseCase,
        processTextUseCase: ProcessTextUseCase,
        deliverResultUseCase: DeliverResultUseCase,
        preferences: PreferenceStoring,
        usageMeter: UsageMetering,
        logger: AppLogger
    ) {
        self.captureTextUseCase = captureTextUseCase
        self.processTextUseCase = processTextUseCase
        self.deliverResultUseCase = deliverResultUseCase
        self.preferences = preferences
        self.usageMeter = usageMeter
        self.logger = logger
    }

    // MARK: Public methods

    func beginCapture() {
        task?.cancel()
        isHUDVisible = false
        state = .capturing

        task = Task { [weak self] in
            await self?.performCapture()
        }
    }

    func present(_ source: SourceText) {
        task?.cancel()
        task = nil
        isHUDVisible = false
        logCaptured(source)
        state = .picking(source: source, selectedIndex: 0)
    }

    func prepareForDismissal() {
        task?.cancel()
        task = nil
        isHUDVisible = false
        state = .capturing
    }

    func updateManualDraft(_ text: String) {
        guard case .manualEntry = state else { return }
        state = .manualEntry(draft: text)
    }

    func acceptManualEntry() {
        guard case .manualEntry(let draft) = state else { return }
        guard let source = captureTextUseCase.make(content: draft, origin: .manual) else { return }
        logCaptured(source)
        state = .picking(source: source, selectedIndex: 0)
    }

    func activate(_ action: TextAction, source: SourceText) {
        run(action: action, source: source, parameters: Self.defaultParameters(for: action, preferences: preferences))
    }

    func choose(_ optionIndex: Int, action: TextAction, source: SourceText) {
        run(action: action, source: source, parameters: Self.parameters(for: action, optionIndex: optionIndex))
    }

    func rerun() {
        switch state {
        case .result(let source, let action, _), .failed(.some(let source), .some(let action), _):
            run(action: action, source: source, parameters: currentParameters)
        default:
            break
        }
    }

    func copyPrimary() {
        guard case .result(_, _, let result) = state else { return }
        copyAndClose(result.primary)
    }

    func copyAlternative(at index: Int) {
        guard case .result(_, _, let result) = state, result.alternatives.indices.contains(index) else { return }
        copyAndClose(result.alternatives[index])
    }

    func openSettings() {
        onOpenSettingsRequested?()
    }

    func openSystemSettings() {
        onOpenSystemSettingsRequested?()
    }

    func handle(_ press: KeyPress) -> KeyPress.Result {
        if press.key == .escape {
            cancelAndClose()
            return .handled
        }

        switch state {
        case .capturing, .running:
            return .ignored
        case .manualEntry:
            return handleManualEntry(press)
        case .picking(let source, let selectedIndex):
            return handlePicking(press, source: source, selectedIndex: selectedIndex)
        case .parameterPicking(let source, let action, let selectedIndex):
            return handleParameterPicking(press, source: source, action: action, selectedIndex: selectedIndex)
        case .result(let source, let action, let result):
            return handleResult(press, source: source, action: action, result: result)
        case .failed(let source, let action, _):
            return handleFailed(press, source: source, action: action)
        }
    }

    // MARK: Private methods

    private func performCapture() async {
        await refreshBudgetState()

        do {
            guard let source = try await captureTextUseCase.execute() else {
                guard Task.isCancelled == false else { return }
                state = .manualEntry(draft: "")
                return
            }
            guard Task.isCancelled == false else { return }
            logCaptured(source)
            state = .picking(source: source, selectedIndex: 0)
        } catch AppError.cancelled {
            return
        } catch let error as AppError {
            logger.textCaptureFailed(error)
            guard Task.isCancelled == false else { return }
            state = .failed(source: nil, action: nil, error: error)
        } catch {
            guard Task.isCancelled == false else { return }
            state = .failed(source: nil, action: nil, error: .unknown)
        }
    }

    private func refreshBudgetState() async {
        usageSnapshot = await usageMeter.snapshot()
    }

    private func logCaptured(_ source: SourceText) {
        logger.textCaptured(
            charCount: source.content.count,
            origin: Self.originDescription(source.origin),
            language: source.language
        )
    }

    private func run(action: TextAction, source: SourceText, parameters: ActionParameters) {
        task?.cancel()
        currentParameters = parameters
        state = .running(source: source, action: action)

        task = Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await processTextUseCase.execute(text: source, action: action, parameters: parameters)
                guard Task.isCancelled == false else { return }
                state = .result(source: source, action: action, result: result)
                await refreshBudgetState()
            } catch AppError.cancelled {
                return
            } catch let error as AppError {
                guard Task.isCancelled == false else { return }
                state = .failed(source: source, action: action, error: error)
            } catch {
                guard Task.isCancelled == false else { return }
                state = .failed(source: source, action: action, error: .unknown)
            }
        }
    }

    private func copyAndClose(_ text: String) {
        task?.cancel()
        task = Task { [weak self] in
            guard let self else { return }
            await deliverResultUseCase.execute(text)
            guard Task.isCancelled == false else { return }
            isHUDVisible = true
            try? await Task.sleep(for: Self.hudDisplayDuration)
            guard Task.isCancelled == false else { return }
            onRequestClose?()
        }
    }

    private func cancelAndClose() {
        task?.cancel()
        task = nil
        onRequestClose?()
    }

    private func openParameterPicker(numberKey: Int, source: SourceText) {
        guard let action = ActionRegistry.all.first(where: { $0.numberKey == numberKey }) else { return }
        state = .parameterPicking(
            source: source,
            action: action,
            selectedIndex: Self.defaultParameterIndex(for: action, preferences: preferences)
        )
    }

    private func runDirectly(numberKey: Int, source: SourceText) {
        guard let action = ActionRegistry.all.first(where: { $0.numberKey == numberKey }) else { return }
        activate(action, source: source)
    }

    private func moveSelection(by delta: Int, count: Int, from index: Int) -> Int {
        guard count > 0 else { return 0 }
        let next = (index + delta) % count
        return next < 0 ? next + count : next
    }

    private func handleManualEntry(_ press: KeyPress) -> KeyPress.Result {
        guard press.key == .return, press.modifiers.contains(.command) else { return .ignored }
        acceptManualEntry()
        return .handled
    }

    private func handlePicking(_ press: KeyPress, source: SourceText, selectedIndex: Int) -> KeyPress.Result {
        if press.key == .upArrow {
            state = .picking(
                source: source,
                selectedIndex: moveSelection(by: -1, count: ActionRegistry.all.count, from: selectedIndex)
            )
            return .handled
        }
        if press.key == .downArrow {
            state = .picking(
                source: source,
                selectedIndex: moveSelection(by: 1, count: ActionRegistry.all.count, from: selectedIndex)
            )
            return .handled
        }
        if press.key == .return, press.modifiers.contains(.command) == false {
            activate(ActionRegistry.all[selectedIndex], source: source)
            return .handled
        }
        if let numberKey = Self.numberKey(for: press) {
            if press.modifiers.contains(.shift), numberKey == 3 || numberKey == 5 {
                openParameterPicker(numberKey: numberKey, source: source)
                return .handled
            }
            if press.modifiers.contains(.shift) == false, press.modifiers.contains(.command) == false {
                runDirectly(numberKey: numberKey, source: source)
                return .handled
            }
        }
        return .ignored
    }

    private func handleParameterPicking(
        _ press: KeyPress,
        source: SourceText,
        action: TextAction,
        selectedIndex: Int
    ) -> KeyPress.Result {
        let optionCount = Self.parameterOptionCount(for: action)

        if press.key == .upArrow {
            state = .parameterPicking(
                source: source,
                action: action,
                selectedIndex: moveSelection(by: -1, count: optionCount, from: selectedIndex)
            )
            return .handled
        }
        if press.key == .downArrow {
            state = .parameterPicking(
                source: source,
                action: action,
                selectedIndex: moveSelection(by: 1, count: optionCount, from: selectedIndex)
            )
            return .handled
        }
        if press.key == .return, press.modifiers.contains(.command) == false {
            choose(selectedIndex, action: action, source: source)
            return .handled
        }
        if let numberKey = Self.numberKey(for: press),
           press.modifiers.contains(.shift) == false,
           press.modifiers.contains(.command) == false,
           (1...optionCount).contains(numberKey) {
            choose(numberKey - 1, action: action, source: source)
            return .handled
        }
        return .ignored
    }

    private func handleResult(
        _ press: KeyPress,
        source: SourceText,
        action: TextAction,
        result: ActionResult
    ) -> KeyPress.Result {
        if press.key == .return, press.modifiers.contains(.command) == false {
            copyPrimary()
            return .handled
        }
        if press.modifiers.contains(.command), let numberKey = Self.numberKey(for: press), (1...3).contains(numberKey) {
            copyAlternative(at: numberKey - 1)
            return .handled
        }
        if press.modifiers.contains(.command), Self.isR(press) {
            rerun()
            return .handled
        }
        if let numberKey = Self.numberKey(for: press) {
            if press.modifiers.contains(.shift), numberKey == 3 || numberKey == 5 {
                openParameterPicker(numberKey: numberKey, source: source)
                return .handled
            }
            if press.modifiers.contains(.shift) == false, press.modifiers.contains(.command) == false {
                runDirectly(numberKey: numberKey, source: source)
                return .handled
            }
        }
        return .ignored
    }

    private func handleFailed(_ press: KeyPress, source: SourceText?, action: TextAction?) -> KeyPress.Result {
        if press.modifiers.contains(.command), Self.isR(press) {
            rerun()
            return .handled
        }
        guard let source else { return .ignored }
        if let numberKey = Self.numberKey(for: press),
           press.modifiers.contains(.shift) == false,
           press.modifiers.contains(.command) == false {
            runDirectly(numberKey: numberKey, source: source)
            return .handled
        }
        return .ignored
    }

    private static func numberKey(for press: KeyPress) -> Int? {
        if let value = press.characters.first?.wholeNumberValue, (1...5).contains(value) {
            return value
        }
        if let symbol = press.characters.first, let value = shiftedDigitSymbols[symbol] {
            return value
        }
        if let value = press.key.character.wholeNumberValue, (1...5).contains(value) {
            return value
        }
        return nil
    }

    private static func isR(_ press: KeyPress) -> Bool {
        press.characters.lowercased() == "r" || press.key.character.lowercased() == "r"
    }

    private static func defaultParameters(for action: TextAction, preferences: PreferenceStoring) -> ActionParameters {
        switch action.id {
        case .humanize:
            return ActionParameters(level: preferences.defaultLevel)
        default:
            return ActionParameters()
        }
    }

    private static func defaultParameterIndex(for action: TextAction, preferences: PreferenceStoring) -> Int {
        switch action.id {
        case .changeTone:
            return Tone.allCases.firstIndex(of: .formal) ?? 0
        case .humanize:
            return LanguageLevel.allCases.firstIndex(of: preferences.defaultLevel) ?? 0
        default:
            return 0
        }
    }

    private static func parameters(for action: TextAction, optionIndex: Int) -> ActionParameters {
        switch action.id {
        case .changeTone:
            guard Tone.allCases.indices.contains(optionIndex) else { return ActionParameters() }
            return ActionParameters(tone: Tone.allCases[optionIndex])
        case .humanize:
            guard LanguageLevel.allCases.indices.contains(optionIndex) else { return ActionParameters() }
            return ActionParameters(level: LanguageLevel.allCases[optionIndex])
        default:
            return ActionParameters()
        }
    }

    private static func parameterOptionCount(for action: TextAction) -> Int {
        switch action.id {
        case .changeTone: return Tone.allCases.count
        case .humanize: return LanguageLevel.allCases.count
        default: return 1
        }
    }

    private static func originDescription(_ origin: SourceText.Origin) -> String {
        switch origin {
        case .pasteboard(let isReused): return isReused ? "pasteboard(reused)" : "pasteboard"
        case .service: return "service"
        case .manual: return "manual"
        }
    }
}
