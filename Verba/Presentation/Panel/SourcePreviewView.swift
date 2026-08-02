import SwiftUI

struct SourcePreviewView: View {
    let sourceText: SourceText

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(sourceText.content)
                .font(PanelTheme.secondary)
                .foregroundStyle(PanelTheme.textSecondary)
                .lineSpacing(2)
                .lineLimit(2)
                .truncationMode(.tail)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Text("\(sourceText.content.count) characters")
                    .font(PanelTheme.caption.monospacedDigit())
                    .foregroundStyle(PanelTheme.textTertiary)

                if case .pasteboard(isReused: true) = sourceText.origin {
                    Badge(text: "reused")
                }

                if sourceText.content.count > InputLimits.hardMax {
                    Text("exceeds \(InputLimits.hardMax.formatted()) character limit")
                        .font(PanelTheme.caption)
                        .foregroundStyle(.red)
                } else if sourceText.content.count > InputLimits.softWarn {
                    Text("long input, higher cost")
                        .font(PanelTheme.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
