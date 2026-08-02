import SwiftUI

struct ActionPickerView: View {
    let sourceText: SourceText
    let selectedIndex: Int
    let onActivate: (TextAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(Array(ActionRegistry.all.enumerated()), id: \.element.id) { index, action in
                ActionRowView(action: action, language: sourceText.language, isSelected: index == selectedIndex)
                    .contentShape(Rectangle())
                    .onTapGesture { onActivate(action) }
            }
        }
    }
}

private struct ActionRowView: View {
    let action: TextAction
    let language: TextLanguage
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            KeyCapsuleView(label: "\(action.numberKey)", isHighlighted: isSelected)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(PanelTheme.prominent)
                    .foregroundStyle(isSelected ? Color.white : PanelTheme.textPrimary)

                if action.needsParameters {
                    Text("⇧\(action.numberKey) to choose \(parameterName)")
                        .font(PanelTheme.caption)
                        .foregroundStyle(isSelected ? Color.white.opacity(0.75) : PanelTheme.textSecondary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 10)
        .background(isSelected ? PanelTheme.selection : Color.clear, in: PanelTheme.rowShape)
    }

    private var title: String {
        language == .russian ? action.titleRussian : action.titleEnglish
    }

    private var parameterName: String {
        switch action.id {
        case .changeTone: return "tone"
        case .humanize: return "level"
        default: return "options"
        }
    }
}
