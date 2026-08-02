import SwiftUI

struct ResultView: View {
    let sourceText: SourceText
    let action: TextAction
    let result: ActionResult
    let onCopyPrimary: () -> Void
    let onCopyAlternative: (Int) -> Void
    let onRerun: () -> Void

    // MARK: Static

    private static let primaryLineLimit = 14
    private static let alternativeLineLimit = 4

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            primaryCard

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
                .font(PanelTheme.title)
                .foregroundStyle(PanelTheme.textPrimary)

            Badge(text: tierLabel)

            if result.cameFromCache {
                Badge(text: "cached")
            }

            Spacer(minLength: 0)
        }
    }

    private var primaryCard: some View {
        Text(result.primary)
            .font(PanelTheme.prominent)
            .foregroundStyle(PanelTheme.textPrimary)
            .lineSpacing(3)
            .lineLimit(Self.primaryLineLimit)
            .fixedSize(horizontal: false, vertical: true)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(PanelTheme.surface, in: PanelTheme.cardShape)
            .overlay { PanelTheme.cardShape.strokeBorder(PanelTheme.hairline, lineWidth: 1) }
            .contentShape(Rectangle())
            .onTapGesture { onCopyPrimary() }
    }

    private var tierLabel: String {
        switch result.tier {
        case .standard: return "standard"
        case .economy: return "economy"
        }
    }

    private var alternativesSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(result.alternatives.enumerated()), id: \.offset) { index, alternative in
                HStack(alignment: .top, spacing: 12) {
                    KeyCapsuleView(label: "⌘\(index + 1)", isHighlighted: false)

                    Text(alternative)
                        .font(PanelTheme.body)
                        .foregroundStyle(PanelTheme.textSecondary)
                        .lineSpacing(2)
                        .lineLimit(Self.alternativeLineLimit)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)

                    Spacer(minLength: 0)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .contentShape(Rectangle())
                .onTapGesture { onCopyAlternative(index) }
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(result.notes, id: \.self) { note in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                    Text(note)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(PanelTheme.caption)
                .foregroundStyle(PanelTheme.textSecondary)
            }
        }
        .padding(.horizontal, 2)
    }

    private var footer: some View {
        HStack(spacing: 8) {
            KeyCapsuleView(label: "⏎", isHighlighted: false)
            Text("copy")

            KeyCapsuleView(label: "⌘R", isHighlighted: false)
            Text("rerun")
                .contentShape(Rectangle())
                .onTapGesture { onRerun() }

            Spacer(minLength: 0)
        }
        .font(PanelTheme.caption)
        .foregroundStyle(PanelTheme.textSecondary)
    }

    private var title: String {
        sourceText.language == .russian ? action.titleRussian : action.titleEnglish
    }
}
