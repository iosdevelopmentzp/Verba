import SwiftUI

struct ParameterPickerView: View {
    let sourceText: SourceText
    let action: TextAction
    let selectedIndex: Int
    let onChoose: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            VStack(alignment: .leading, spacing: 2) {
                ForEach(Array(optionTitles.enumerated()), id: \.offset) { index, optionTitle in
                    HStack(spacing: 10) {
                        KeyCapsuleView(label: "\(index + 1)")
                        Text(optionTitle)
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(
                        index == selectedIndex ? Color.accentColor.opacity(0.15) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 6)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { onChoose(index) }
                }
            }
        }
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
