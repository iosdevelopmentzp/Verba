import SwiftUI

struct ActionPickerView: View {
    let sourceText: SourceText
    let selectedIndex: Int
    let onActivate: (TextAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
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
        HStack(spacing: 10) {
            KeyCapsuleView(label: "\(action.numberKey)")

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)

                if action.needsParameters {
                    Text("⇧\(action.numberKey) to choose \(parameterName)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear, in: RoundedRectangle(cornerRadius: 6))
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
