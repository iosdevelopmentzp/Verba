import SwiftUI

struct ExplanationOverlayView: View {
    let state: ExplanationState
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .contentShape(Rectangle())
                .onTapGesture { onDismiss() }

            card
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Why these fixes?")
                .font(PanelTheme.title)
                .foregroundStyle(PanelTheme.textPrimary)

            content

            Text("Esc to close")
                .font(PanelTheme.caption)
                .foregroundStyle(PanelTheme.textTertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PanelTheme.background, in: PanelTheme.cardShape)
        .overlay { PanelTheme.cardShape.strokeBorder(PanelTheme.hairline, lineWidth: 1) }
        .shadow(color: .black.opacity(0.18), radius: 16, y: 6)
        .padding(24)
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .loading:
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Working out the rules…")
                    .font(PanelTheme.body)
                    .foregroundStyle(PanelTheme.textSecondary)
            }

        case .loaded(let explanations):
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(explanations.enumerated()), id: \.offset) { _, explanation in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                        Text(explanation)
                            .textSelection(.enabled)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .font(PanelTheme.body)
            .foregroundStyle(PanelTheme.textPrimary)

        case .failed(let error):
            Text(ErrorPresentation.message(for: error))
                .font(PanelTheme.body)
                .foregroundStyle(PanelTheme.textPrimary)
        }
    }
}
