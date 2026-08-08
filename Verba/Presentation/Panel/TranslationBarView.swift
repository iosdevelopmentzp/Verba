import SwiftUI

struct TranslationBarView: View {
    let viewModel: PanelViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            row(title: "From", key: "⌘⇧T") {
                ChipView(label: "Auto", isSelected: viewModel.sourceLanguage == nil)
                    .onTapGesture { viewModel.setSourceLanguage(nil) }

                ForEach(TextLanguage.selectable, id: \.self) { language in
                    ChipView(label: language.shortCode, isSelected: viewModel.sourceLanguage == language)
                        .onTapGesture { viewModel.setSourceLanguage(language) }
                }

                Spacer(minLength: 0)

                if viewModel.sourceLanguage == nil {
                    Text(detectedSummary)
                        .font(PanelTheme.caption)
                        .lineLimit(1)
                        .foregroundStyle(PanelTheme.textTertiary)
                }
            }

            row(title: "Into", key: "⌘T") {
                ForEach(TextLanguage.selectable, id: \.self) { language in
                    ChipView(label: language.shortCode, isSelected: viewModel.targetLanguage == language)
                        .onTapGesture { viewModel.setTargetLanguage(language) }
                }

                Spacer(minLength: 0)

                Text(viewModel.targetLanguage.displayName)
                    .font(PanelTheme.caption)
                    .lineLimit(1)
                    .foregroundStyle(PanelTheme.textTertiary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PanelTheme.surface, in: PanelTheme.rowShape)
        .overlay { PanelTheme.rowShape.strokeBorder(PanelTheme.hairline, lineWidth: 1) }
    }

    private func row<Content: View>(
        title: String,
        key: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 6) {
            Text(title.uppercased())
                .font(PanelTheme.sectionLabel)
                .lineLimit(1)
                .foregroundStyle(PanelTheme.textTertiary)
                .frame(width: 34, alignment: .leading)

            KeyCapsuleView(label: key, isHighlighted: false)

            content()
        }
    }

    private var detectedSummary: String {
        guard let detected = viewModel.detectedLanguage, detected != .other else {
            return "Detected by the model"
        }
        return "Detected: \(detected.displayName)"
    }
}
