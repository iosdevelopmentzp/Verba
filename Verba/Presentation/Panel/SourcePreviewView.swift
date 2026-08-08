import SwiftUI

struct SourcePreviewView: View {
    let sourceText: SourceText
    let onCopyOriginal: () -> Void
    let onEditOriginal: () -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(sourceText.content)
                .font(PanelTheme.secondary)
                .foregroundStyle(PanelTheme.textSecondary)
                .lineSpacing(2)
                .lineLimit(isExpanded ? nil : 2)
                .truncationMode(.tail)
                .fixedSize(horizontal: false, vertical: true)
                .contentShape(Rectangle())
                .onTapGesture { isExpanded.toggle() }

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

                Spacer(minLength: 0)

                KeyCapsuleView(label: "⌘C", isHighlighted: false)
                Text("copy")
                    .font(PanelTheme.caption)
                    .foregroundStyle(PanelTheme.textSecondary)
                    .contentShape(Rectangle())
                    .onTapGesture { onCopyOriginal() }

                KeyCapsuleView(label: "⇥", isHighlighted: false)
                Text("edit")
                    .font(PanelTheme.caption)
                    .foregroundStyle(PanelTheme.textSecondary)
                    .contentShape(Rectangle())
                    .onTapGesture { onEditOriginal() }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
