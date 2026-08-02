import Observation
import SwiftUI

enum PanelState: Equatable {
    case capturing
    case manualEntry(draft: String)
    case picking(source: SourceText, selectedIndex: Int)
    case parameterPicking(source: SourceText, action: TextAction, selectedIndex: Int)
    case running(source: SourceText, action: TextAction)
    case result(source: SourceText, action: TextAction, result: ActionResult, selectedIndex: Int)
    case failed(source: SourceText?, action: TextAction?, error: AppError)
}

enum ExplanationState: Equatable {
    case loading
    case loaded([FixExplanation])
    case failed(AppError)
}

@MainActor
@Observable
final class PanelViewModel {

    // MARK: Dependencies

    private let captureTextUseCase: CaptureTextUseCase
    private let processTextUseCase: ProcessTextUseCase
    private let deliverResultUseCase: DeliverResultUseCase
    private let explainFixesUseCase: ExplainFixesUseCase
    private let preferences: PreferenceStoring
    private let usageMeter: UsageMetering
    private let logger: AppLogger

    // MARK: Public properties

    private(set) var state: PanelState = .capturing
    private(set) var isHUDVisible = false
    private(set) var usageSnapshot: UsageSnapshot?
    private(set) var explanation: ExplanationState?

    var onRequestClose: (() -> Void)?
    var onOpenSettingsRequested: (() -> Void)?
    var onOpenSystemSettingsRequested: (() -> Void)?
    var maxContentHeight: CGFloat?

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
    private var explainTask: Task<Void, Never>?
    private var currentParameters = ActionParameters()
    private var lastTone: Tone?
    private var lastLevel: LanguageLevel?

    // MARK: Static

    private static let hudDisplayDuration: Duration = .milliseconds(650)
    private static let shiftedDigitSymbols: [Character: Int] = [
        "!": 1, "@": 2, "#": 3, "$": 4, "%": 5,
        "£": 3, "§": 3, "№": 3
    ]

    // MARK: Init

    init(
        captureTextUseCase: CaptureTextUseCase,
        processTextUseCase: ProcessTextUseCase,
        deliverResultUseCase: DeliverResultUseCase,
        explainFixesUseCase: ExplainFixesUseCase,
        preferences: PreferenceStoring,
        usageMeter: UsageMetering,
        logger: AppLogger
    ) {
        self.captureTextUseCase = captureTextUseCase
        self.processTextUseCase = processTextUseCase
        self.deliverResultUseCase = deliverResultUseCase
        self.explainFixesUseCase = explainFixesUseCase
        self.preferences = preferences
        self.usageMeter = usageMeter
        self.logger = logger
    }

    // MARK: Public methods

    func beginCapture() {
        task?.cancel()
        isHUDVisible = false
        dismissExplanation()
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
        dismissExplanation()
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

    func editCurrentSource() {
        guard case .picking(let source, _) = state else { return }
        state = .manualEntry(draft: source.content)
    }

    func goBackToPicking() {
        let backTo: (source: SourceText, action: TextAction)?
        switch state {
        case .parameterPicking(let source, let action, _):
            backTo = (source, action)
        case .result(let source, let action, _, _):
            backTo = (source, action)
        case .failed(.some(let source), .some(let action), _):
            backTo = (source, action)
        default:
            backTo = nil
        }
        guard let backTo else { return }

        task?.cancel()
        dismissExplanation()
        state = .picking(source: backTo.source, selectedIndex: Self.index(of: backTo.action))
    }

    func activate(_ action: TextAction, source: SourceText) {
        if action.needsParameters {
            openParameterPicker(action: action, source: source)
        } else {
            run(action: action, source: source, parameters: ActionParameters(), bypassCache: false)
        }
    }

    func choose(_ optionIndex: Int, action: TextAction, source: SourceText) {
        let parameters = Self.parameters(for: action, optionIndex: optionIndex)
        switch action.id {
        case .changeTone: lastTone = parameters.tone
        case .humanize: lastLevel = parameters.level
        default: break
        }
        run(action: action, source: source, parameters: parameters, bypassCache: false)
    }

    func rerun() {
        switch state {
        case .result(let source, let action, _, _), .failed(.some(let source), .some(let action), _):
            run(action: action, source: source, parameters: currentParameters, bypassCache: true)
        default:
            break
        }
    }

    func copyPrimary() {
        guard case .result(_, _, let result, _) = state else { return }
        copyToPasteboard(result.primary)
    }

    func copyAlternative(at index: Int) {
        guard case .result(_, _, let result, _) = state, result.alternatives.indices.contains(index) else { return }
        copyToPasteboard(result.alternatives[index])
    }

    func explainFixes() {
        guard case .result(let source, let action, let result, _) = state,
              action.supportsExplanation,
              result.notes.isEmpty == false else { return }

        explainTask?.cancel()
        explanation = .loading

        explainTask = Task { [weak self] in
            guard let self else { return }
            do {
                let explanations = try await explainFixesUseCase.execute(
                    original: source.content,
                    corrected: result.primary,
                    notes: result.notes,
                    language: source.language
                )
                guard Task.isCancelled == false else { return }
                explanation = .loaded(explanations)
            } catch AppError.cancelled {
                return
            } catch let error as AppError {
                guard Task.isCancelled == false else { return }
                explanation = .failed(error)
            } catch {
                guard Task.isCancelled == false else { return }
                explanation = .failed(.unknown)
            }
        }
    }

    func dismissExplanation() {
        explainTask?.cancel()
        explainTask = nil
        explanation = nil
    }

    func openSettings() {
        onOpenSettingsRequested?()
    }

    func openSystemSettings() {
        onOpenSystemSettingsRequested?()
    }

    func handle(_ press: KeyPress) -> KeyPress.Result {
        if press.key == .escape {
            if explanation != nil {
                dismissExplanation()
            } else {
                cancelAndClose()
            }
            return .handled
        }

        guard explanation == nil else { return .handled }

        switch state {
        case .capturing, .running:
            return .ignored
        case .manualEntry:
            return handleManualEntry(press)
        case .picking(let source, let selectedIndex):
            return handlePicking(press, source: source, selectedIndex: selectedIndex)
        case .parameterPicking(let source, let action, let selectedIndex):
            return handleParameterPicking(press, source: source, action: action, selectedIndex: selectedIndex)
        case .result(let source, let action, let result, let selectedIndex):
            return handleResult(press, source: source, action: action, result: result, selectedIndex: selectedIndex)
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

    private func run(action: TextAction, source: SourceText, parameters: ActionParameters, bypassCache: Bool) {
        task?.cancel()
        currentParameters = parameters
        state = .running(source: source, action: action)

        task = Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await processTextUseCase.execute(
                    text: source,
                    action: action,
                    parameters: parameters,
                    bypassCache: bypassCache
                )
                guard Task.isCancelled == false else { return }
                state = .result(source: source, action: action, result: result, selectedIndex: 0)
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

    private func copyToPasteboard(_ text: String) {
        task?.cancel()
        task = Task { [weak self] in
            guard let self else { return }
            await deliverResultUseCase.execute(text)
            guard Task.isCancelled == false else { return }
            isHUDVisible = true
            try? await Task.sleep(for: Self.hudDisplayDuration)
            guard Task.isCancelled == false else { return }
            isHUDVisible = false
        }
    }

    private func cancelAndClose() {
        task?.cancel()
        task = nil
        onRequestClose?()
    }

    private func copySelected(at index: Int, result: ActionResult) {
        guard let text = Self.text(at: index, result: result) else { return }
        copyToPasteboard(text)
    }

    private func chainedSource(at index: Int, result: ActionResult) -> SourceText? {
        guard let text = Self.text(at: index, result: result) else { return nil }
        return captureTextUseCase.make(content: text, origin: .chained)
    }

    private static func text(at index: Int, result: ActionResult) -> String? {
        if index == 0 { return result.primary }
        guard result.alternatives.indices.contains(index - 1) else { return nil }
        return result.alternatives[index - 1]
    }

    private func openParameterPicker(action: TextAction, source: SourceText) {
        state = .parameterPicking(
            source: source,
            action: action,
            selectedIndex: defaultParameterIndex(for: action)
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
        if press.key == .tab {
            acceptManualEntry()
            return .handled
        }
        if press.key == .return, press.modifiers.contains(.command) == false {
            updateManualDraft(manualDraft + "\n")
            return .handled
        }
        return .ignored
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
        if press.key == .tab {
            editCurrentSource()
            return .handled
        }
        if let numberKey = Self.numberKey(for: press), press.modifiers.contains(.command) == false {
            runDirectly(numberKey: numberKey, source: source)
            return .handled
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
        if press.key == .leftArrow, press.modifiers.contains(.command) {
            goBackToPicking()
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
        result: ActionResult,
        selectedIndex: Int
    ) -> KeyPress.Result {
        let optionCount = 1 + result.alternatives.count

        if press.key == .upArrow {
            state = .result(
                source: source,
                action: action,
                result: result,
                selectedIndex: moveSelection(by: -1, count: optionCount, from: selectedIndex)
            )
            return .handled
        }
        if press.key == .downArrow {
            state = .result(
                source: source,
                action: action,
                result: result,
                selectedIndex: moveSelection(by: 1, count: optionCount, from: selectedIndex)
            )
            return .handled
        }
        if press.key == .return, press.modifiers.contains(.command) == false {
            copySelected(at: selectedIndex, result: result)
            if press.modifiers.contains(.shift), let chainedSource = chainedSource(at: selectedIndex, result: result) {
                logCaptured(chainedSource)
                state = .picking(source: chainedSource, selectedIndex: 0)
            }
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
        if press.modifiers.contains(.command), Self.isE(press) {
            explainFixes()
            return .handled
        }
        if press.key == .leftArrow, press.modifiers.contains(.command) {
            goBackToPicking()
            return .handled
        }
        if let numberKey = Self.numberKey(for: press), press.modifiers.contains(.command) == false {
            runDirectly(numberKey: numberKey, source: source)
            return .handled
        }
        return .ignored
    }

    private func handleFailed(_ press: KeyPress, source: SourceText?, action: TextAction?) -> KeyPress.Result {
        if press.modifiers.contains(.command), Self.isR(press) {
            rerun()
            return .handled
        }
        if press.key == .leftArrow, press.modifiers.contains(.command) {
            goBackToPicking()
            return .handled
        }
        guard let source else { return .ignored }
        if let numberKey = Self.numberKey(for: press), press.modifiers.contains(.command) == false {
            runDirectly(numberKey: numberKey, source: source)
            return .handled
        }
        return .ignored
    }

    private static func numberKey(for press: KeyPress) -> Int? {
        if let value = press.characters.first?.wholeNumberValue, (1...6).contains(value) {
            return value
        }
        if let symbol = press.characters.first, let value = shiftedDigitSymbols[symbol] {
            return value
        }
        if let value = press.key.character.wholeNumberValue, (1...6).contains(value) {
            return value
        }
        return nil
    }

    private static func isR(_ press: KeyPress) -> Bool {
        press.characters.lowercased() == "r" || press.key.character.lowercased() == "r"
    }

    private static func isE(_ press: KeyPress) -> Bool {
        press.characters.lowercased() == "e" || press.key.character.lowercased() == "e"
    }

    private func defaultParameterIndex(for action: TextAction) -> Int {
        switch action.id {
        case .changeTone:
            return Tone.allCases.firstIndex(of: lastTone ?? .formal) ?? 0
        case .humanize:
            return LanguageLevel.allCases.firstIndex(of: lastLevel ?? preferences.defaultLevel) ?? 0
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

    private static func index(of action: TextAction) -> Int {
        ActionRegistry.all.firstIndex(where: { $0.id == action.id }) ?? 0
    }

    private static func originDescription(_ origin: SourceText.Origin) -> String {
        switch origin {
        case .pasteboard(let isReused): return isReused ? "pasteboard(reused)" : "pasteboard"
        case .service: return "service"
        case .manual: return "manual"
        case .chained: return "chained"
        }
    }
}
