import SwiftUI

struct ParameterPickerView: View {
    let sourceText: SourceText
    let action: TextAction
    let selectedIndex: Int
    let onChoose: (Int) -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(PanelTheme.title)
                .foregroundStyle(PanelTheme.textPrimary)

            VStack(alignment: .leading, spacing: 3) {
                ForEach(Array(optionTitles.enumerated()), id: \.offset) { index, optionTitle in
                    let isSelected = index == selectedIndex

                    HStack(spacing: 12) {
                        KeyCapsuleView(label: "\(index + 1)", isHighlighted: isSelected)

                        Text(optionTitle)
                            .font(PanelTheme.prominent)
                            .foregroundStyle(isSelected ? Color.white : PanelTheme.textPrimary)

                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 9)
                    .padding(.horizontal, 10)
                    .background(isSelected ? PanelTheme.selection : Color.clear, in: PanelTheme.rowShape)
                    .contentShape(Rectangle())
                    .onTapGesture { onChoose(index) }
                }
            }

            footer
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            KeyCapsuleView(label: "⌘←", isHighlighted: false)
            Text("back")
                .contentShape(Rectangle())
                .onTapGesture { onBack() }

            Spacer(minLength: 0)
        }
        .font(PanelTheme.caption)
        .foregroundStyle(PanelTheme.textSecondary)
    }

    private var title: String {
        sourceText.language == .russian ? action.titleRussian : action.titleEnglish
    }

    private var optionTitles: [String] {
        switch action.id {
        case .changeTone: return Tone.allCases.map(\.displayName)
        case .humanize: return LanguageLevel.allCases.map(\.displayName)
        default: return []
        }
    }
}

private extension Tone {
    var displayName: String {
        switch self {
        case .formal: return "Formal"
        case .casual: return "Casual"
        case .direct: return "Direct"
        case .friendly: return "Friendly"
        }
    }
}

private extension LanguageLevel {
    var displayName: String {
        switch self {
        case .b1: return "B1 — everyday"
        case .b2: return "B2 — comfortable"
        case .c1: return "C1 — advanced"
        }
    }
}
