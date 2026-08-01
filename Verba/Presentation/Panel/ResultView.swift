import SwiftUI

struct ResultView: View {
    let sourceText: SourceText
    let action: TextAction
    let result: ActionResult
    let onCopyPrimary: () -> Void
    let onCopyAlternative: (Int) -> Void
    let onRerun: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            Text(result.primary)
                .font(.body)
                .textSelection(.enabled)
                .contentShape(Rectangle())
                .onTapGesture { onCopyPrimary() }

            if result.alternatives.isEmpty == false {
                alternativesSection
            }

            if result.notes.isEmpty == false {
                notesSection
            }

            footer
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.headline)

            Badge(text: tierLabel)

            if result.cameFromCache {
                Badge(text: "cached")
            }

            Spacer(minLength: 0)
        }
    }

    private var tierLabel: String {
        switch result.tier {
        case .standard: return "standard"
        case .economy: return "economy"
        }
    }

    private var alternativesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(result.alternatives.enumerated()), id: \.offset) { index, alternative in
                HStack(alignment: .top, spacing: 8) {
                    KeyCapsuleView(label: "⌘\(index + 1)")
                    Text(alternative)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
                .onTapGesture { onCopyAlternative(index) }
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(result.notes, id: \.self) { note in
                HStack(alignment: .top, spacing: 6) {
                    Text("•")
                    Text(note)
                }
                .font(.caption)
                .foregroundStyle(.tertiary)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 14) {
            Text("⏎ copy")
            Text("⌘R rerun")
                .contentShape(Rectangle())
                .onTapGesture { onRerun() }
            Spacer(minLength: 0)
        }
        .font(.caption2)
        .foregroundStyle(.tertiary)
    }

    private var title: String {
        sourceText.language == .russian ? action.titleRussian : action.titleEnglish
    }
}
