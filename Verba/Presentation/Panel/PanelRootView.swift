import SwiftUI

struct PanelRootView: View {
    let viewModel: PanelViewModel

    @FocusState private var isRootFocused: Bool

    var body: some View {
        ScrollView {
            content
                .padding(PanelTheme.contentPadding)
        }
        .frame(width: PanelTheme.width, alignment: .leading)
            .frame(maxHeight: viewModel.maxContentHeight)
            .background(PanelTheme.background, in: PanelTheme.panelShape)
            .overlay { PanelTheme.panelShape.strokeBorder(PanelTheme.hairline, lineWidth: 1) }
            .focusable()
            .focusEffectDisabled()
            .focused($isRootFocused)
            .onKeyPress { press in viewModel.handle(press) }
            .onAppear { isRootFocused = true }
            .onChange(of: isManualEntry) { _, newValue in
                guard newValue == false else { return }
                isRootFocused = true
            }
            .overlay(alignment: .top) { budgetBanner }
            .overlay(alignment: .bottom) { hudOverlay }
            .overlay { explanationOverlay }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .capturing:
            capturingView

        case .manualEntry:
            ManualEntryView(viewModel: viewModel)

        case .picking(let source, let selectedIndex):
            withSource(source) {
                ActionPickerView(
                    sourceText: source,
                    selectedIndex: selectedIndex,
                    onActivate: { action in viewModel.activate(action, source: source) },
                    onEdit: { viewModel.editCurrentSource() },
                    onCopyOriginal: { viewModel.copyOriginal() }
                )
            }

        case .parameterPicking(let source, let action, let selectedIndex):
            withSource(source) {
                ParameterPickerView(
                    sourceText: source,
                    action: action,
                    selectedIndex: selectedIndex,
                    onChoose: { index in viewModel.choose(index, action: action, source: source) },
                    onBack: { viewModel.goBackToPicking() },
                    onCopyOriginal: { viewModel.copyOriginal() }
                )
            }

        case .running(let source, let action):
            withSource(source) {
                RunningView(sourceText: source, action: action)
            }

        case .result(let source, let action, let result, let selectedIndex):
            withSource(source) {
                ResultView(
                    sourceText: source,
                    action: action,
                    result: result,
                    selectedIndex: selectedIndex,
                    onCopyPrimary: { viewModel.copyPrimary() },
                    onCopyAlternative: { viewModel.copyAlternative(at: $0) },
                    onRerun: { viewModel.rerun() },
                    onExplain: { viewModel.explainFixes() },
                    onBack: { viewModel.goBackToPicking() },
                    onCopyOriginal: { viewModel.copyOriginal() },
                    isDiffShown: viewModel.isDiffShown,
                    onToggleDiff: { viewModel.toggleDiff() }
                )
            }

        case .failed(let source, _, let error):
            errorContent(source: source, error: error)
        }
    }

    @ViewBuilder
    private func errorContent(source: SourceText?, error: AppError) -> some View {
        let errorView = ErrorView(
            error: error,
            onRetry: { viewModel.rerun() },
            onOpenSettings: { viewModel.openSettings() },
            onOpenSystemSettings: { viewModel.openSystemSettings() }
        )

        if let source {
            withSource(source) { errorView }
        } else {
            errorView
        }
    }

    private var capturingView: some View {
        HStack {
            Spacer()
            ProgressView()
                .controlSize(.small)
            Spacer()
        }
        .frame(minHeight: 60)
    }

    @ViewBuilder
    private var hudOverlay: some View {
        if viewModel.isHUDVisible {
            HUD(message: "Copied")
                .padding(.bottom, 16)
                .transition(.opacity)
                .animation(.easeOut(duration: 0.15), value: viewModel.isHUDVisible)
        }
    }

    @ViewBuilder
    private var explanationOverlay: some View {
        if let explanation = viewModel.explanation {
            ExplanationOverlayView(state: explanation) { viewModel.dismissExplanation() }
        }
    }

    @ViewBuilder
    private var budgetBanner: some View {
        if viewModel.isOverBudget, let usageSnapshot = viewModel.usageSnapshot {
            BudgetWarningBanner(snapshot: usageSnapshot)
                .padding(.top, 10)
        }
    }

    private var isManualEntry: Bool {
        guard case .manualEntry = viewModel.state else { return false }
        return true
    }

    private func withSource<Content: View>(
        _ source: SourceText,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: PanelTheme.sectionSpacing) {
            SourcePreviewView(sourceText: source)
            HairlineDivider()
            content()
        }
    }
}

private struct ManualEntryView: View {
    let viewModel: PanelViewModel
    @FocusState private var isDraftFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Verba")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(PanelTheme.textPrimary)

            TextField("⌘C some text, or type here", text: draftBinding, axis: .vertical)
                .textFieldStyle(.plain)
                .font(PanelTheme.prominent)
                .foregroundStyle(PanelTheme.textPrimary)
                .lineLimit(1...6)
                .focused($isDraftFocused)
                .padding(12)
                .background(PanelTheme.surface, in: PanelTheme.cardShape)
                .overlay { PanelTheme.cardShape.strokeBorder(PanelTheme.hairline, lineWidth: 1) }

            HStack(spacing: 10) {
                Button("Accept") { viewModel.acceptManualEntry() }
                    .controlSize(.regular)

                Button("Clear") {
                    viewModel.updateManualDraft("")
                    isDraftFocused = true
                }
                .controlSize(.regular)

                Text("⇥ to accept")
                    .font(PanelTheme.caption)
                    .foregroundStyle(PanelTheme.textSecondary)
            }
        }
        .onAppear { isDraftFocused = true }
    }

    private var draftBinding: Binding<String> {
        Binding(
            get: { viewModel.manualDraft },
            set: { viewModel.updateManualDraft($0) }
        )
    }
}

private struct BudgetWarningBanner: View {
    let snapshot: UsageSnapshot

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(PanelTheme.caption.weight(.medium))
            .foregroundStyle(.orange)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(PanelTheme.background, in: Capsule())
            .overlay { Capsule().strokeBorder(PanelTheme.hairline, lineWidth: 1) }
    }

    private var message: String {
        "Monthly budget exceeded — \(Self.currency(snapshot.costMonthUSD)) of \(Self.currency(snapshot.budgetMonthUSD))"
    }

    private static func currency(_ value: Decimal) -> String {
        value.formatted(.currency(code: "USD"))
    }
}
