import Observation
import SwiftUI

struct PendingRun: Equatable {
    let action: TextAction
    let parameters: ActionParameters
}

struct InstructionEditorState: Equatable {
    let actionTitle: String
    let hadInstruction: Bool
    var draft: String
}

struct PromptEditorState: Equatable {
    let actionTitle: String
    let preamble: String
    let defaultBody: String
    var body: String
    var isPersistent: Bool
}

enum PanelState: Equatable {
    case capturing
    case manualEntry(draft: String, returnTo: PendingRun?)
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
    private let promptPreview: PromptPreviewing
    private let preferences: PreferenceStoring
    private let usageMeter: UsageMetering
    private let logger: AppLogger

    // MARK: Public properties

    private(set) var state: PanelState = .capturing
    private(set) var isHUDVisible = false
    private(set) var usageSnapshot: UsageSnapshot?
    private(set) var explanation: ExplanationState?
    private(set) var isDiffShown: Bool
    private(set) var isSidebarExpanded: Bool
    private(set) var panelAppearance: PanelAppearance
    private(set) var creativity: Creativity
    private(set) var extraInstructions: [String: String] = [:]
    private(set) var promptEditor: PromptEditorState?
    private(set) var instructionEditor: InstructionEditorState?
    private(set) var rootFocusRequestID = 0

    var onRequestClose: (() -> Void)?
    var onOpenSettingsRequested: (() -> Void)?
    var onOpenSystemSettingsRequested: (() -> Void)?
    var onCopyCompleted: (() -> Void)?
    var onAppearanceChanged: ((PanelAppearance) -> Void)?
    var maxContentHeight: CGFloat?

    var isOverBudget: Bool {
        guard let usageSnapshot else { return false }
        return usageSnapshot.costMonthUSD > usageSnapshot.budgetMonthUSD
    }

    var manualDraft: String {
        guard case .manualEntry(let draft, _) = state else { return "" }
        return draft
    }

    var sourceLanguage: TextLanguage? {
        currentParameters.sourceLanguage
    }

    var detectedLanguage: TextLanguage? {
        currentSource?.language
    }

    var targetLanguage: TextLanguage {
        if let targetLanguage = currentParameters.targetLanguage { return targetLanguage }
        return ActionParameters.defaultTargetLanguage(for: currentParameters.sourceLanguage ?? currentSource?.language ?? .other)
    }

    func trackLayoutInputs() {
        _ = state
        _ = isDiffShown
        _ = creativity
        _ = isSidebarExpanded
        _ = promptEditor
        _ = instructionEditor
        _ = explanation
        _ = usageSnapshot
    }

    // MARK: Private properties

    private var task: Task<Void, Never>?
    private var explainTask: Task<Void, Never>?
    private var currentParameters = ActionParameters()
    private var sessionPromptOverrides: [String: String] = [:]

    // MARK: Static

    private static let hudDisplayDuration: Duration = .milliseconds(650)
    private static let numberKeyRange = 1...ActionRegistry.all.count
    private static let shiftedDigitSymbols: [Character: Int] = [
        "!": 1, "@": 2, "#": 3, "$": 4, "%": 5, "^": 6, "&": 7,
        "£": 3, "§": 3, "№": 3
    ]

    // MARK: Init

    init(
        captureTextUseCase: CaptureTextUseCase,
        processTextUseCase: ProcessTextUseCase,
        deliverResultUseCase: DeliverResultUseCase,
        explainFixesUseCase: ExplainFixesUseCase,
        promptPreview: PromptPreviewing,
        preferences: PreferenceStoring,
        usageMeter: UsageMetering,
        logger: AppLogger
    ) {
        self.captureTextUseCase = captureTextUseCase
        self.processTextUseCase = processTextUseCase
        self.deliverResultUseCase = deliverResultUseCase
        self.explainFixesUseCase = explainFixesUseCase
        self.promptPreview = promptPreview
        self.preferences = preferences
        self.usageMeter = usageMeter
        self.logger = logger
        self.isDiffShown = preferences.isDiffVisible
        self.creativity = preferences.lastCreativity
        self.isSidebarExpanded = preferences.isSidebarExpanded
        self.panelAppearance = preferences.panelAppearance
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
        extraInstructions = [:]
        sessionPromptOverrides = [:]
        instructionEditor = nil
        promptEditor = nil
        dismissExplanation()
        state = .capturing
    }

    func updateManualDraft(_ text: String) {
        guard case .manualEntry(_, let returnTo) = state else { return }
        state = .manualEntry(draft: text, returnTo: returnTo)
    }

    func acceptManualEntry() {
        guard case .manualEntry(let draft, let returnTo) = state else { return }
        guard let source = captureTextUseCase.make(content: draft, origin: .manual) else { return }
        logCaptured(source)
        rootFocusRequestID += 1

        guard let returnTo else {
            state = .picking(source: source, selectedIndex: 0)
            return
        }
        run(action: returnTo.action, source: source, parameters: returnTo.parameters, bypassCache: false)
    }

    func editCurrentSource() {
        switch state {
        case .picking(let source, _):
            state = .manualEntry(draft: source.content, returnTo: nil)
        case .result(let source, let action, _, _), .failed(.some(let source), .some(let action), _):
            task?.cancel()
            dismissExplanation()
            state = .manualEntry(
                draft: source.content,
                returnTo: PendingRun(action: action, parameters: currentParameters)
            )
        default:
            break
        }
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
        case .changeTone: preferences.lastTone = parameters.tone
        case .humanize: preferences.lastLevel = parameters.level
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

    func copySelectedOption() {
        guard case .result(_, _, let result, let selectedIndex) = state else { return }
        copySelected(at: selectedIndex, result: result)
    }

    func copyAlternative(at index: Int) {
        guard case .result(_, _, let result, _) = state, result.alternatives.indices.contains(index) else { return }
        copyToPasteboard(result.alternatives[index])
    }

    func copyOriginal() {
        switch state {
        case .picking(let source, _),
             .parameterPicking(let source, _, _),
             .running(let source, _),
             .result(let source, _, _, _):
            copyToPasteboard(source.content)
        case .failed(.some(let source), _, _):
            copyToPasteboard(source.content)
        default:
            break
        }
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

    func extraInstruction(for action: TextAction) -> String {
        extraInstructions[action.id.rawValue] ?? ""
    }

    func updateExtraInstruction(_ text: String, for action: TextAction) {
        extraInstructions[action.id.rawValue] = text
    }

    func openInstructionEditor() {
        guard let action = currentAction else { return }
        let existing = extraInstruction(for: action)
        instructionEditor = InstructionEditorState(
            actionTitle: action.titleEnglish,
            hadInstruction: existing.isEmpty == false,
            draft: existing
        )
    }

    func updateInstructionDraft(_ text: String) {
        instructionEditor?.draft = text
    }

    func dismissInstructionEditor() {
        instructionEditor = nil
        rootFocusRequestID += 1
    }

    func applyInstructionEditor() {
        guard let action = currentAction, let editor = instructionEditor else { return }
        let trimmed = editor.draft.trimmingCharacters(in: .whitespacesAndNewlines)
        let previous = extraInstruction(for: action)
        instructionEditor = nil
        rootFocusRequestID += 1

        guard trimmed != previous else { return }
        updateExtraInstruction(trimmed, for: action)
        rerunCurrentAction()
    }

    func clearInstructionEditor() {
        instructionEditor?.draft = ""
    }

    func setCreativity(_ value: Creativity) {
        guard value != creativity else { return }
        creativity = value
        preferences.lastCreativity = value
        rerunCurrentAction()
    }

    func cycleCreativity() {
        let all = Creativity.allCases
        guard let index = all.firstIndex(of: creativity) else { return }
        setCreativity(all[(index + 1) % all.count])
    }

    func setSourceLanguage(_ value: TextLanguage?) {
        guard value != currentParameters.sourceLanguage else { return }
        currentParameters.sourceLanguage = value
        currentParameters.targetLanguage = nil
        preferences.lastSourceLanguage = value
        preferences.lastTargetLanguage = nil
        rerunCurrentAction()
    }

    func setTargetLanguage(_ value: TextLanguage) {
        guard value != currentParameters.targetLanguage else { return }
        currentParameters.targetLanguage = value
        preferences.lastTargetLanguage = value
        rerunCurrentAction()
    }

    func cycleSourceLanguage() {
        let all: [TextLanguage?] = [nil] + TextLanguage.selectable.map { Optional($0) }
        let index = all.firstIndex(of: currentParameters.sourceLanguage) ?? 0
        setSourceLanguage(all[(index + 1) % all.count])
    }

    func cycleTargetLanguage() {
        let all = TextLanguage.selectable
        let index = all.firstIndex(of: targetLanguage) ?? 0
        setTargetLanguage(all[(index + 1) % all.count])
    }

    func openPromptEditor() {
        guard let action = currentAction, let source = currentSource else { return }
        let parameters = resolvedParameters(currentParameters, action: action, source: source)
        let defaultBody = promptPreview.defaultSystemPromptBody(
            for: action,
            parameters: parameters,
            language: source.language
        )
        promptEditor = PromptEditorState(
            actionTitle: action.titleEnglish,
            preamble: promptPreview.preamble,
            defaultBody: defaultBody,
            body: parameters.systemPromptOverride ?? defaultBody,
            isPersistent: preferences.promptOverrides[overrideKey(for: action)] != nil
        )
    }

    func dismissPromptEditor() {
        promptEditor = nil
        rootFocusRequestID += 1
    }

    func updatePromptBody(_ text: String) {
        promptEditor?.body = text
    }

    func setPromptPersistent(_ isPersistent: Bool) {
        promptEditor?.isPersistent = isPersistent
    }

    func resetPrompt() {
        guard let action = currentAction, var editor = promptEditor else { return }
        sessionPromptOverrides[overrideKey(for: action)] = nil
        preferences.promptOverrides[overrideKey(for: action)] = nil
        editor.body = editor.defaultBody
        editor.isPersistent = false
        promptEditor = editor
    }

    func applyPromptEditor() {
        guard let action = currentAction, let editor = promptEditor else { return }
        let trimmed = editor.body.trimmingCharacters(in: .whitespacesAndNewlines)
        let override = trimmed == editor.defaultBody.trimmingCharacters(in: .whitespacesAndNewlines) ? nil : trimmed

        let key = overrideKey(for: action)
        sessionPromptOverrides[key] = editor.isPersistent ? nil : override
        preferences.promptOverrides[key] = editor.isPersistent ? override : nil

        promptEditor = nil
        rerunCurrentAction()
    }

    func selectOption(at index: Int) {
        guard case .result(let source, let action, let result, _) = state,
              (0..<Self.rowCount(for: result)).contains(index) else { return }
        state = .result(source: source, action: action, result: result, selectedIndex: index)
    }

    static func instructionRowIndex(for result: ActionResult) -> Int {
        1 + result.alternatives.count
    }

    static func rowCount(for result: ActionResult) -> Int {
        instructionRowIndex(for: result) + 1
    }

    static func isInstructionRow(_ index: Int, result: ActionResult) -> Bool {
        index == instructionRowIndex(for: result)
    }

    func setPanelAppearance(_ value: PanelAppearance) {
        guard value != panelAppearance else { return }
        panelAppearance = value
        preferences.panelAppearance = value
        onAppearanceChanged?(value)
    }

    func toggleSidebar() {
        isSidebarExpanded.toggle()
        preferences.isSidebarExpanded = isSidebarExpanded
    }

    var economyMode: Bool {
        preferences.economyMode
    }

    func setEconomyMode(_ isOn: Bool) {
        guard isOn != preferences.economyMode else { return }
        preferences.economyMode = isOn
        rerunCurrentAction()
    }

    var canToggleDiff: Bool {
        currentAction?.supportsDiff == true
    }

    func toggleDiff() {
        isDiffShown.toggle()
        preferences.isDiffVisible = isDiffShown
    }

    func openSettings() {
        onOpenSettingsRequested?()
    }

    func openSystemSettings() {
        onOpenSystemSettingsRequested?()
    }

    func handleEscape() {
        if instructionEditor != nil {
            dismissInstructionEditor()
        } else if promptEditor != nil {
            dismissPromptEditor()
        } else if explanation != nil {
            dismissExplanation()
        } else {
            cancelAndClose()
        }
    }

    func handle(_ press: KeyPress) -> KeyPress.Result {
        if press.key == .escape {
            handleEscape()
            return .handled
        }

        guard explanation == nil, promptEditor == nil, instructionEditor == nil else { return .handled }

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
                state = .manualEntry(draft: "", returnTo: nil)
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

    private var currentSource: SourceText? {
        switch state {
        case .picking(let source, _),
             .parameterPicking(let source, _, _),
             .running(let source, _),
             .result(let source, _, _, _):
            return source
        case .failed(let source, _, _):
            return source
        default:
            return nil
        }
    }

    private var currentAction: TextAction? {
        switch state {
        case .parameterPicking(_, let action, _), .running(_, let action), .result(_, let action, _, _):
            return action
        case .failed(_, .some(let action), _):
            return action
        default:
            return nil
        }
    }

    private func overrideKey(for action: TextAction) -> String {
        "\(action.templateID).v\(promptPreview.promptVersion(for: action))"
    }

    private func resolvedParameters(
        _ parameters: ActionParameters,
        action: TextAction,
        source: SourceText
    ) -> ActionParameters {
        var resolved = parameters
        resolved.creativity = creativity
        let instruction = extraInstruction(for: action)
        resolved.extraInstruction = instruction.isEmpty ? nil : instruction
        let overrideKey = overrideKey(for: action)
        resolved.systemPromptOverride = sessionPromptOverrides[overrideKey]
            ?? preferences.promptOverrides[overrideKey]

        if action.id == .translate {
            resolved.sourceLanguage = resolved.sourceLanguage ?? preferences.lastSourceLanguage
            resolved.targetLanguage = resolved.targetLanguage
                ?? preferences.lastTargetLanguage
                ?? ActionParameters.defaultTargetLanguage(for: resolved.sourceLanguage ?? source.language)
        }
        return resolved
    }

    private func rerunCurrentAction() {
        guard let action = currentAction, let source = currentSource else { return }
        run(action: action, source: source, parameters: currentParameters, bypassCache: false)
    }

    private func run(action: TextAction, source: SourceText, parameters: ActionParameters, bypassCache: Bool) {
        task?.cancel()
        rootFocusRequestID += 1
        let parameters = resolvedParameters(parameters, action: action, source: source)
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
            onCopyCompleted?()
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
        let rowCount = Self.rowCount(for: result)

        if press.key == .upArrow {
            state = .result(
                source: source,
                action: action,
                result: result,
                selectedIndex: moveSelection(by: -1, count: rowCount, from: selectedIndex)
            )
            return .handled
        }
        if press.key == .downArrow {
            state = .result(
                source: source,
                action: action,
                result: result,
                selectedIndex: moveSelection(by: 1, count: rowCount, from: selectedIndex)
            )
            return .handled
        }
        if press.key == .return, Self.isInstructionRow(selectedIndex, result: result) {
            openInstructionEditor()
            return .handled
        }
        if press.key == .return, press.modifiers.contains(.command) {
            copySelected(at: selectedIndex, result: result)
            if let chainedSource = chainedSource(at: selectedIndex, result: result) {
                logCaptured(chainedSource)
                state = .picking(source: chainedSource, selectedIndex: 0)
            }
            return .handled
        }
        if press.key == .return, press.modifiers.contains(.command) == false {
            copySelected(at: selectedIndex, result: result)
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
        if press.modifiers.contains(.command), Self.isD(press), action.supportsDiff {
            toggleDiff()
            return .handled
        }
        if press.modifiers.contains(.command), Self.isLetter(press, "j") {
            cycleCreativity()
            return .handled
        }
        if press.modifiers.contains(.command), Self.isLetter(press, "i") {
            openInstructionEditor()
            return .handled
        }
        if press.modifiers.contains(.command), Self.isLetter(press, "p") {
            openPromptEditor()
            return .handled
        }
        if press.modifiers.contains(.command), Self.isLetter(press, "t"), action.id == .translate {
            if press.modifiers.contains(.shift) {
                cycleSourceLanguage()
            } else {
                cycleTargetLanguage()
            }
            return .handled
        }
        if press.key == .tab {
            editCurrentSource()
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
        if press.key == .tab, source != nil, action != nil {
            editCurrentSource()
            return .handled
        }
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
        if let value = press.characters.first?.wholeNumberValue, Self.numberKeyRange.contains(value) {
            return value
        }
        if let symbol = press.characters.first, let value = shiftedDigitSymbols[symbol] {
            return value
        }
        if let value = press.key.character.wholeNumberValue, Self.numberKeyRange.contains(value) {
            return value
        }
        return nil
    }

    private static func isLetter(_ press: KeyPress, _ letter: String) -> Bool {
        press.characters.lowercased() == letter || press.key.character.lowercased() == letter
    }

    private static func isR(_ press: KeyPress) -> Bool {
        isLetter(press, "r")
    }

    private static func isE(_ press: KeyPress) -> Bool {
        isLetter(press, "e")
    }

    private static func isD(_ press: KeyPress) -> Bool {
        isLetter(press, "d")
    }

    private func defaultParameterIndex(for action: TextAction) -> Int {
        switch action.id {
        case .changeTone:
            return Tone.allCases.firstIndex(of: preferences.lastTone ?? .formal) ?? 0
        case .humanize:
            return LanguageLevel.allCases.firstIndex(of: preferences.lastLevel ?? preferences.defaultLevel) ?? 0
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
