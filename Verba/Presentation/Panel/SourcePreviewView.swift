import SwiftUI

struct SourcePreviewView: View {
    let sourceText: SourceText

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(sourceText.content)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .truncationMode(.tail)

            HStack(spacing: 6) {
                Text("\(sourceText.content.count) characters")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.tertiary)

                if case .pasteboard(isReused: true) = sourceText.origin {
                    Badge(text: "reused")
                }

                if sourceText.content.count > InputLimits.hardMax {
                    Text("exceeds \(InputLimits.hardMax.formatted()) character limit")
                        .font(.caption2)
                        .foregroundStyle(.red)
                } else if sourceText.content.count > InputLimits.softWarn {
                    Text("long input, higher cost")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
