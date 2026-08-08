import SwiftUI

struct TranslationBarView: View {
    let viewModel: PanelViewModel

    var body: some View {
        HStack(spacing: 8) {
            label("From", key: "⌘⇧T")

            ChipView(label: "Auto", isSelected: viewModel.sourceLanguage == nil)
                .onTapGesture { viewModel.setSourceLanguage(nil) }

            ForEach(TextLanguage.selectable, id: \.self) { language in
                ChipView(label: language.shortCode, isSelected: viewModel.sourceLanguage == language)
                    .onTapGesture { viewModel.setSourceLanguage(language) }
            }

            Image(systemName: "arrow.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(PanelTheme.textTertiary)
                .padding(.horizontal, 2)

            label("Into", key: "⌘T")

            ForEach(TextLanguage.selectable, id: \.self) { language in
                ChipView(label: language.shortCode, isSelected: viewModel.targetLanguage == language)
                    .onTapGesture { viewModel.setTargetLanguage(language) }
            }

            Spacer(minLength: 0)

            Text(summary)
                .font(PanelTheme.caption)
                .foregroundStyle(PanelTheme.textTertiary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PanelTheme.surface, in: PanelTheme.rowShape)
        .overlay { PanelTheme.rowShape.strokeBorder(PanelTheme.hairline, lineWidth: 1) }
    }

    private func label(_ text: String, key: String) -> some View {
        HStack(spacing: 5) {
            Text(text.uppercased())
                .font(PanelTheme.sectionLabel)
                .foregroundStyle(PanelTheme.textTertiary)
            KeyCapsuleView(label: key, isHighlighted: false)
        }
    }

    private var summary: String {
        "\(viewModel.sourceLanguage?.displayName ?? "Detected") → \(viewModel.targetLanguage.displayName)"
    }
}
