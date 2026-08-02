import SwiftUI

struct RunningView: View {
    let sourceText: SourceText
    let action: TextAction

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ProgressView()
                    .controlSize(.small)

                Text(title)
                    .font(PanelTheme.title)
            }

            HStack(spacing: 8) {
                KeyCapsuleView(label: "⎋", isHighlighted: false)
                Text("to cancel")
            }
            .font(PanelTheme.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var title: String {
        sourceText.language == .russian ? action.titleRussian : action.titleEnglish
    }
}
