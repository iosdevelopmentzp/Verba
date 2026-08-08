import SwiftUI

struct ResultControlsView: View {
    let viewModel: PanelViewModel
    let action: TextAction
    @FocusState.Binding var focus: PanelFocus?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HairlineDivider()

            HStack(spacing: 8) {
                Text("EXTRA INSTRUCTION")
                    .font(PanelTheme.sectionLabel)
                    .foregroundStyle(PanelTheme.textTertiary)

                Text("for \(actionName)")
                    .font(PanelTheme.caption)
                    .foregroundStyle(PanelTheme.textTertiary)

                Spacer(minLength: 0)

                KeyCapsuleView(label: "⌘I", isHighlighted: false)
            }

            TextField("Add a one-off instruction, then press ⏎", text: instructionBinding)
                .textFieldStyle(.plain)
                .font(PanelTheme.secondary)
                .foregroundStyle(PanelTheme.textPrimary)
                .focused($focus, equals: .instruction)
                .onSubmit { viewModel.applyExtraInstruction() }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(PanelTheme.surface, in: PanelTheme.rowShape)
                .overlay { PanelTheme.rowShape.strokeBorder(PanelTheme.hairline, lineWidth: 1) }

            HStack(spacing: 8) {
                KeyCapsuleView(label: "⌘P", isHighlighted: false)
                Text("view and edit the full prompt")
                    .font(PanelTheme.caption)
                    .foregroundStyle(PanelTheme.textSecondary)
                    .contentShape(Rectangle())
                    .onTapGesture { viewModel.openPromptEditor() }

                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onChange(of: viewModel.instructionFocusRequestID) { _, _ in focus = .instruction }
    }

    private var actionName: String {
        action.titleEnglish.lowercased()
    }

    private var instructionBinding: Binding<String> {
        Binding(
            get: { viewModel.extraInstruction(for: action) },
            set: { viewModel.updateExtraInstruction($0, for: action) }
        )
    }
}

struct ChipView: View {
    let label: String
    let isSelected: Bool

    var body: some View {
        Text(label)
            .font(PanelTheme.caption)
            .foregroundStyle(isSelected ? Color.white : PanelTheme.textSecondary)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(isSelected ? PanelTheme.selection : PanelTheme.keyCap, in: Capsule())
            .contentShape(Capsule())
    }
}

extension TextLanguage {
    var displayName: String {
        switch self {
        case .english: return "English"
        case .russian: return "Русский"
        case .ukrainian: return "Українська"
        case .spanish: return "Español"
        case .other: return "Other"
        }
    }
}

extension Creativity {
    var displayName: String {
        switch self {
        case .precise: return "Precise"
        case .balanced: return "Balanced"
        case .creative: return "Creative"
        }
    }
}
