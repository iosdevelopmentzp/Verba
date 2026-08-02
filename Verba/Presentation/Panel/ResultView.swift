import SwiftUI

struct ResultView: View {
    let sourceText: SourceText
    let action: TextAction
    let result: ActionResult
    let selectedIndex: Int
    let onCopyPrimary: () -> Void
    let onCopyAlternative: (Int) -> Void
    let onRerun: () -> Void
    let onExplain: () -> Void
    let onBack: () -> Void

    // MARK: Static

    private static let primaryLineLimit = 14
    private static let alternativeLineLimit = 4

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            VStack(alignment: .leading, spacing: 4) {
                primaryCard
                characterCountLabel(result.primary, color: PanelTheme.textTertiary)
            }

            if canShowDiff {
                diffSection
            }

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

    private var isPrimarySelected: Bool {
        selectedIndex == 0
    }

    private var primaryCard: some View {
        Text(result.primary)
            .font(PanelTheme.prominent)
            .foregroundStyle(isPrimarySelected ? Color.white : PanelTheme.textPrimary)
            .lineSpacing(3)
            .lineLimit(isPrimarySelected ? nil : Self.primaryLineLimit)
            .fixedSize(horizontal: false, vertical: true)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(isPrimarySelected ? PanelTheme.selection : PanelTheme.surface, in: PanelTheme.cardShape)
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
                let isSelected = selectedIndex == index + 1

                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .top, spacing: 12) {
                        KeyCapsuleView(label: "\(index + 1)", isHighlighted: isSelected)

                        Text(alternative)
                            .font(PanelTheme.body)
                            .foregroundStyle(isSelected ? Color.white : PanelTheme.textSecondary)
                            .lineSpacing(2)
                            .lineLimit(isSelected ? nil : Self.alternativeLineLimit)
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)

                        Spacer(minLength: 0)
                    }

                    characterCountLabel(alternative, color: isSelected ? Color.white.opacity(0.7) : PanelTheme.textTertiary)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(isSelected ? PanelTheme.selection : Color.clear, in: PanelTheme.rowShape)
                .contentShape(Rectangle())
                .onTapGesture { onCopyAlternative(index) }
            }
        }
    }

    private func characterCountLabel(_ text: String, color: Color) -> some View {
        Text("\(text.count) characters")
            .font(PanelTheme.caption)
            .foregroundStyle(color)
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

    private var canExplain: Bool {
        action.supportsExplanation && result.notes.isEmpty == false
    }

    private var canShowDiff: Bool {
        action.supportsDiff && result.primary != sourceText.content
    }

    private var diffSection: some View {
        TextDiff.wordDiff(original: sourceText.content, revised: result.primary)
            .reduce(Text("")) { partial, segment in
                switch segment {
                case .equal(let words):
                    return partial + Text(words + " ").foregroundColor(PanelTheme.textSecondary)
                case .removed(let words):
                    return partial + Text(words + " ").strikethrough().foregroundColor(PanelTheme.diffRemoved)
                case .added(let words):
                    return partial + Text(words + " ").bold().foregroundColor(PanelTheme.diffAdded)
                }
            }
            .font(PanelTheme.body)
            .lineSpacing(2)
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PanelTheme.surface, in: PanelTheme.cardShape)
            .overlay { PanelTheme.cardShape.strokeBorder(PanelTheme.hairline, lineWidth: 1) }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            KeyCapsuleView(label: "⏎", isHighlighted: false)
            Text("copy")

            KeyCapsuleView(label: "⌘R", isHighlighted: false)
            Text("rerun")
                .contentShape(Rectangle())
                .onTapGesture { onRerun() }

            if canExplain {
                KeyCapsuleView(label: "⌘E", isHighlighted: false)
                Text("explain")
                    .contentShape(Rectangle())
                    .onTapGesture { onExplain() }
            }

            KeyCapsuleView(label: "⌘←", isHighlighted: false)
            Text("back")
                .contentShape(Rectangle())
                .onTapGesture { onBack() }

            Spacer(minLength: 0)
        }
        .font(PanelTheme.caption)
        .foregroundStyle(PanelTheme.textSecondary)
    }

    private var title: String {
        sourceText.language == .russian ? action.titleRussian : action.titleEnglish
    }
}
