import SwiftUI

enum PanelFocus: Hashable {
    case root
    case draft
    case instruction
}

struct PanelRootView: View {
    let viewModel: PanelViewModel

    @FocusState private var focus: PanelFocus?

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                PanelGrabberView()

                ScrollView {
                    content
                        .padding(.horizontal, PanelTheme.contentPadding)
                        .padding(.bottom, PanelTheme.contentPadding)
                }
            }
            .frame(width: PanelTheme.width, alignment: .leading)

            PanelSidebarView(viewModel: viewModel)
        }
        .frame(width: PanelTheme.panelWidth(isSidebarExpanded: viewModel.isSidebarExpanded), alignment: .leading)
            .frame(maxHeight: viewModel.maxContentHeight)
            .frame(minHeight: viewModel.promptEditor == nil ? nil : PanelTheme.promptEditorMinHeight)
            .background(PanelTheme.background, in: PanelTheme.panelShape)
            .overlay { PanelTheme.panelShape.strokeBorder(PanelTheme.hairline, lineWidth: 1) }
            .focusable()
            .focusEffectDisabled()
            .focused($focus, equals: .root)
            .onKeyPress { press in viewModel.handle(press) }
            .onAppear { focus = .root }
            .onChange(of: viewModel.rootFocusRequestID) { _, _ in focus = .root }
            .overlay(alignment: .top) { budgetBanner }
            .overlay(alignment: .bottom) { hudOverlay }
            .overlay { explanationOverlay }
            .overlay { promptOverlay }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .capturing:
            capturingView

        case .manualEntry:
            ManualEntryView(viewModel: viewModel, focus: $focus)

        case .picking(let source, let selectedIndex):
            withSource(source) {
                ActionPickerView(
                    sourceText: source,
                    selectedIndex: selectedIndex,
                    onActivate: { action in viewModel.activate(action, source: source) },
                    onEdit: { viewModel.editCurrentSource() }
                )
            }

        case .parameterPicking(let source, let action, let selectedIndex):
            withSource(source) {
                ParameterPickerView(
                    sourceText: source,
                    action: action,
                    selectedIndex: selectedIndex,
                    onChoose: { index in viewModel.choose(index, action: action, source: source) },
                    onBack: { viewModel.goBackToPicking() }
                )
            }

        case .running(let source, let action):
            withSource(source) {
                RunningView(sourceText: source, action: action)
            }

        case .result(let source, let action, let result, let selectedIndex):
            withSource(source) {
                VStack(alignment: .leading, spacing: PanelTheme.sectionSpacing) {
                    ResultView(
                        sourceText: source,
                        action: action,
                        result: result,
                        selectedIndex: selectedIndex,
                        onCopyPrimary: { viewModel.copyPrimary() },
                        onCopyAlternative: { viewModel.copyAlternative(at: $0) },
                        onSelectOption: { viewModel.selectOption(at: $0) },
                        onRerun: { viewModel.rerun() },
                        onExplain: { viewModel.explainFixes() },
                        onBack: { viewModel.goBackToPicking() },
                        isDiffShown: viewModel.isDiffShown,
                        onToggleDiff: { viewModel.toggleDiff() }
                    )

                    ResultControlsView(viewModel: viewModel, action: action, focus: $focus)
                }
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
    private var promptOverlay: some View {
        if let promptEditor = viewModel.promptEditor {
            PromptOverlayView(
                state: promptEditor,
                actionTitle: promptEditor.actionTitle,
                onBodyChange: { viewModel.updatePromptBody($0) },
                onPersistenceChange: { viewModel.setPromptPersistent($0) },
                onReset: { viewModel.resetPrompt() },
                onApply: { viewModel.applyPromptEditor() },
                onDismiss: { viewModel.dismissPromptEditor() }
            )
        }
    }

    @ViewBuilder
    private var budgetBanner: some View {
        if viewModel.isOverBudget, let usageSnapshot = viewModel.usageSnapshot {
            BudgetWarningBanner(snapshot: usageSnapshot)
                .padding(.top, 10)
        }
    }

    private func withSource<Content: View>(
        _ source: SourceText,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: PanelTheme.sectionSpacing) {
            SourcePreviewView(
                sourceText: source,
                onCopyOriginal: { viewModel.copyOriginal() },
                onEditOriginal: { viewModel.editCurrentSource() }
            )
            HairlineDivider()
            content()
        }
    }
}

private struct ManualEntryView: View {
    let viewModel: PanelViewModel
    @FocusState.Binding var focus: PanelFocus?

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
                .focused($focus, equals: .draft)
                .padding(12)
                .background(PanelTheme.surface, in: PanelTheme.cardShape)
                .overlay { PanelTheme.cardShape.strokeBorder(PanelTheme.hairline, lineWidth: 1) }

            HStack(spacing: 10) {
                Button("Accept") { viewModel.acceptManualEntry() }
                    .controlSize(.regular)

                Button("Clear") {
                    viewModel.updateManualDraft("")
                    focus = .draft
                }
                .controlSize(.regular)

                Text("⇥ to accept")
                    .font(PanelTheme.caption)
                    .foregroundStyle(PanelTheme.textSecondary)
            }
        }
        .onAppear { focus = .draft }
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

private struct PanelGrabberView: View {
    var body: some View {
        Capsule()
            .fill(PanelTheme.hairline)
            .frame(width: 46, height: 4)
            .frame(maxWidth: .infinity)
            .frame(height: PanelTheme.grabberHeight)
            .contentShape(Rectangle())
            .gesture(WindowDragGesture())
    }
}
