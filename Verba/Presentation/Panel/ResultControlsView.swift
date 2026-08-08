import SwiftUI

struct ResultControlsView: View {
    let viewModel: PanelViewModel
    let action: TextAction
    let isHighlighted: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("EXTRA INSTRUCTION")
                .font(PanelTheme.sectionLabel)
                .foregroundStyle(PanelTheme.textTertiary)

            instructionRow

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
    }

    private var instructionRow: some View {
        HStack(alignment: .top, spacing: 10) {
            KeyCapsuleView(label: "⌘I", isHighlighted: isHighlighted)

            VStack(alignment: .leading, spacing: 2) {
                Text(instruction.isEmpty ? "Add a one-off instruction for \(actionName)" : instruction)
                    .font(PanelTheme.secondary)
                    .foregroundStyle(instruction.isEmpty ? PanelTheme.textTertiary : PanelTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isHighlighted {
                    Text(instruction.isEmpty ? "⏎ to write one" : "⏎ to edit")
                        .font(PanelTheme.caption)
                        .foregroundStyle(PanelTheme.textTertiary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.leading, 10)
        .padding(.trailing, 12)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isHighlighted ? PanelTheme.selectionSoft : PanelTheme.surface, in: PanelTheme.cardShape)
        .overlay(alignment: .leading) {
            if isHighlighted {
                Rectangle()
                    .fill(PanelTheme.selection)
                    .frame(width: 3)
                    .clipShape(PanelTheme.cardShape)
            }
        }
        .overlay {
            PanelTheme.cardShape
                .strokeBorder(isHighlighted ? PanelTheme.selectionBorder : PanelTheme.hairline, lineWidth: 1)
        }
        .contentShape(Rectangle())
        .onTapGesture { viewModel.openInstructionEditor() }
    }

    private var instruction: String {
        viewModel.extraInstruction(for: action)
    }

    private var actionName: String {
        action.titleEnglish.lowercased()
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
