import SwiftUI

struct ActionPickerView: View {
    let sourceText: SourceText
    let selectedIndex: Int
    let onActivate: (TextAction) -> Void
    let onEdit: () -> Void
    let onCopyOriginal: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                ForEach(Array(ActionRegistry.all.enumerated()), id: \.element.id) { index, action in
                    ActionRowView(action: action, language: sourceText.language, isSelected: index == selectedIndex)
                        .contentShape(Rectangle())
                        .onTapGesture { onActivate(action) }
                }
            }

            footer
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            KeyCapsuleView(label: "⇥", isHighlighted: false)
            Text("edit text")
                .contentShape(Rectangle())
                .onTapGesture { onEdit() }

            KeyCapsuleView(label: "⌘C", isHighlighted: false)
            Text("copy original")
                .contentShape(Rectangle())
                .onTapGesture { onCopyOriginal() }

            Spacer(minLength: 0)
        }
        .font(PanelTheme.caption)
        .foregroundStyle(PanelTheme.textSecondary)
    }
}

private struct ActionRowView: View {
    let action: TextAction
    let language: TextLanguage
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            KeyCapsuleView(label: "\(action.numberKey)", isHighlighted: isSelected)

            Text(title)
                .font(PanelTheme.prominent)
                .foregroundStyle(isSelected ? Color.white : PanelTheme.textPrimary)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 10)
        .background(isSelected ? PanelTheme.selection : Color.clear, in: PanelTheme.rowShape)
    }

    private var title: String {
        language == .russian ? action.titleRussian : action.titleEnglish
    }
}
