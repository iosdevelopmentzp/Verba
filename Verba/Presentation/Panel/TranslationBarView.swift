import SwiftUI

struct TranslationBarView: View {
    let viewModel: PanelViewModel

    // MARK: Static

    private static let labelWidth: CGFloat = 36

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            row(title: "From", key: "⌘⇧T") {
                ChipView(label: "Auto", isSelected: viewModel.sourceLanguage == nil)
                    .onTapGesture { viewModel.setSourceLanguage(nil) }

                ForEach(TextLanguage.selectable, id: \.self) { language in
                    ChipView(label: language.shortCode, isSelected: viewModel.sourceLanguage == language)
                        .onTapGesture { viewModel.setSourceLanguage(language) }
                }
            }

            row(title: "Into", key: "⌘T") {
                ForEach(TextLanguage.selectable, id: \.self) { language in
                    ChipView(label: language.shortCode, isSelected: viewModel.targetLanguage == language)
                        .onTapGesture { viewModel.setTargetLanguage(language) }
                }
            }

            Text(summary)
                .font(PanelTheme.caption)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(PanelTheme.textTertiary)
                .padding(.leading, Self.labelWidth)
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
                .fixedSize()
                .foregroundStyle(PanelTheme.textTertiary)
                .frame(width: Self.labelWidth, alignment: .leading)

            KeyCapsuleView(label: key, isHighlighted: false)

            content()

            Spacer(minLength: 0)
        }
    }

    private var summary: String {
        "\(sourceName) → \(viewModel.targetLanguage.displayName)"
    }

    private var sourceName: String {
        guard viewModel.sourceLanguage == nil else {
            return viewModel.sourceLanguage?.displayName ?? ""
        }
        guard let detected = viewModel.detectedLanguage, detected != .other else {
            return "Detected by the model"
        }
        return "Detected: \(detected.displayName)"
    }
}
