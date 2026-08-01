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
                    Text("reused")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.quaternary, in: Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
