import SwiftUI

struct ResultView: View {
    let sourceText: SourceText
    let action: TextAction
    let result: ActionResult
    let selectedIndex: Int
    let onCopySelected: () -> Void
    let onCopyAlternative: (Int) -> Void
    let onSelectOption: (Int) -> Void
    let onRerun: () -> Void
    let onExplain: () -> Void
    let onBack: () -> Void
    let isDiffShown: Bool
    let onToggleDiff: () -> Void

    // MARK: Static

    private static let unselectedLineLimit = 6

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            suggestions

            if result.notes.isEmpty == false {
                notesSection
            }

            footer
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Header

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

            Text(optionCount == 1 ? "1 suggestion" : "\(optionCount) suggestions")
                .font(PanelTheme.caption)
                .foregroundStyle(PanelTheme.textTertiary)
        }
    }

    // MARK: - Suggestions

    private var suggestions: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Suggestions")

            ForEach(0..<optionCount, id: \.self) { index in
                suggestionRow(at: index)
            }
        }
    }

    private func suggestionRow(at index: Int) -> some View {
        let isSelected = selectedIndex == index
        let text = optionText(at: index)

        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 10) {
                KeyCapsuleView(label: index == 0 ? "⏎" : "⌘\(index)", isHighlighted: isSelected)

                Text(text)
                    .font(index == 0 ? PanelTheme.prominent : PanelTheme.body)
                    .foregroundStyle(PanelTheme.textPrimary)
                    .lineSpacing(3)
                    .lineLimit(isSelected ? nil : Self.unselectedLineLimit)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 10) {
                Text("\(text.count) characters")
                    .font(PanelTheme.caption.monospacedDigit())
                    .foregroundStyle(PanelTheme.textTertiary)

                if isSelected, canShowDiff(for: text) {
                    tappableCaption(isDiffShown ? "hide diff" : "show diff", action: onToggleDiff)
                }

                Spacer(minLength: 0)

                Text(isSelected ? "click to copy" : "click to select")
                    .font(PanelTheme.caption)
                    .foregroundStyle(PanelTheme.textTertiary)
            }

            if isSelected, isDiffShown, canShowDiff(for: text) {
                diffSection(for: text)
            }
        }
        .padding(.leading, 10)
        .padding(.trailing, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? Color.clear : PanelTheme.surface, in: PanelTheme.cardShape)
        .overlay { PanelTheme.cardShape.strokeBorder(isSelected ? Color.clear : PanelTheme.hairline, lineWidth: 1) }
        .selectableRow(isSelected: isSelected, shape: PanelTheme.cardShape)
        .contentShape(Rectangle())
        .onTapGesture { tap(at: index, isSelected: isSelected) }
    }

    private func tap(at index: Int, isSelected: Bool) {
        guard isSelected else {
            onSelectOption(index)
            return
        }
        if index == 0 {
            onCopySelected()
        } else {
            onCopyAlternative(index - 1)
        }
    }

    // MARK: - Diff

    private func diffSection(for text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionLabel("Changes from the original")

            TextDiff.wordDiff(original: sourceText.content, revised: text)
                .reduce(Text("")) { partial, segment in
                    switch segment {
                    case .equal(let words):
                        return partial + Text(words + " ").foregroundColor(PanelTheme.textTertiary)
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
                .background(PanelTheme.background, in: PanelTheme.cardShape)
                .overlay { PanelTheme.cardShape.strokeBorder(PanelTheme.hairline, lineWidth: 1) }
        }
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            sectionLabel("What changed")

            ForEach(result.notes, id: \.self) { note in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(PanelTheme.textTertiary)
                        .frame(width: 3, height: 3)
                        .padding(.top, 6)

                    Text(note)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(PanelTheme.caption)
                .foregroundStyle(PanelTheme.textSecondary)
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 14) {
            footerItem(key: "⏎", label: "copy", action: onCopySelected)
            footerItem(key: "⌘⏎", label: "copy and chain", action: nil)
            footerItem(key: "⌘R", label: "rerun", action: onRerun)

            if canExplain {
                footerItem(key: "⌘E", label: "explain", action: onExplain)
            }

            footerItem(key: "⌘←", label: "back", action: onBack)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PanelTheme.surface, in: PanelTheme.rowShape)
    }

    private func footerItem(key: String, label: String, action: (() -> Void)?) -> some View {
        HStack(spacing: 6) {
            KeyCapsuleView(label: key, isHighlighted: false)
            Text(label)
                .font(PanelTheme.caption)
                .foregroundStyle(PanelTheme.textSecondary)
        }
        .contentShape(Rectangle())
        .onTapGesture { action?() }
    }

    // MARK: - Helpers

    private func sectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(PanelTheme.sectionLabel)
            .foregroundStyle(PanelTheme.textTertiary)
    }

    private func tappableCaption(_ label: String, action: @escaping () -> Void) -> some View {
        Text(label)
            .font(PanelTheme.caption)
            .foregroundStyle(PanelTheme.selection)
            .contentShape(Rectangle())
            .onTapGesture { action() }
    }

    private var optionCount: Int {
        1 + result.alternatives.count
    }

    private func optionText(at index: Int) -> String {
        index == 0 ? result.primary : result.alternatives[index - 1]
    }

    private var tierLabel: String {
        switch result.tier {
        case .standard: return "standard"
        case .economy: return "economy"
        }
    }

    private var canExplain: Bool {
        action.supportsExplanation && result.notes.isEmpty == false
    }

    private func canShowDiff(for text: String) -> Bool {
        action.supportsDiff && text != sourceText.content
    }

    private var title: String {
        sourceText.language == .russian ? action.titleRussian : action.titleEnglish
    }
}
