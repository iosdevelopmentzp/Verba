import SwiftUI

struct PanelSidebarView: View {
    let viewModel: PanelViewModel

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(PanelTheme.hairline)
                .frame(width: 1)

            if viewModel.isSidebarExpanded {
                expanded
            } else {
                rail
            }
        }
        .background(PanelTheme.sidebarBackground)
    }

    // MARK: - Collapsed

    private var rail: some View {
        VStack(spacing: 8) {
            chevron
            Text("OPTIONS")
                .font(PanelTheme.sectionLabel)
                .foregroundStyle(PanelTheme.textTertiary)
                .fixedSize()
                .rotationEffect(.degrees(90))
                .frame(width: PanelTheme.sidebarRailWidth, height: 78)
            Spacer(minLength: 0)
        }
        .padding(.top, 10)
        .frame(width: PanelTheme.sidebarRailWidth)
        .contentShape(Rectangle())
        .onTapGesture { viewModel.toggleSidebar() }
    }

    // MARK: - Expanded

    private var expanded: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                header

                group("Style", key: "⌘J") {
                    ForEach(Creativity.allCases, id: \.self) { option in
                        listRow(
                            title: option.displayName,
                            detail: option.detail,
                            isSelected: option == viewModel.creativity
                        ) { viewModel.setCreativity(option) }
                    }
                }

                group("Model", key: nil) {
                    chips(["Standard", "Economy"], selected: viewModel.economyMode ? 1 : 0) { index in
                        viewModel.setEconomyMode(index == 1)
                    }
                }

                if viewModel.canToggleDiff {
                    group("Diff", key: "⌘D") {
                        chips(["Shown", "Hidden"], selected: viewModel.isDiffShown ? 0 : 1) { index in
                            guard (index == 0) != viewModel.isDiffShown else { return }
                            viewModel.toggleDiff()
                        }
                    }
                }

                group("Theme", key: nil) {
                    chips(
                        PanelAppearance.allCases.map(\.displayName),
                        selected: PanelAppearance.allCases.firstIndex(of: viewModel.panelAppearance)
                    ) { index in
                        viewModel.setPanelAppearance(PanelAppearance.allCases[index])
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 11)
        }
        .frame(width: PanelTheme.sidebarWidth)
    }

    private var header: some View {
        HStack(spacing: 6) {
            chevron
            Text("OPTIONS")
                .font(PanelTheme.sectionLabel)
                .lineLimit(1)
                .fixedSize()
                .foregroundStyle(PanelTheme.textTertiary)
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
        .onTapGesture { viewModel.toggleSidebar() }
    }

    private var chevron: some View {
        Image(systemName: viewModel.isSidebarExpanded ? "chevron.right" : "chevron.left")
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(PanelTheme.textTertiary)
    }

    // MARK: - Building blocks

    private func group<Content: View>(
        _ title: String,
        key: String?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(title.uppercased())
                    .font(PanelTheme.sectionLabel)
                    .lineLimit(1)
                    .fixedSize()
                    .foregroundStyle(PanelTheme.textTertiary)
                Spacer(minLength: 0)
                if let key {
                    KeyCapsuleView(label: key, isHighlighted: false)
                }
            }
            content()
        }
    }

    private func chips(
        _ labels: [String],
        selected: Int?,
        select: @escaping (Int) -> Void
    ) -> some View {
        HStack(spacing: 4) {
            ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                ChipView(label: label, isSelected: index == selected)
                    .onTapGesture { select(index) }
            }
            Spacer(minLength: 0)
        }
    }

    private func listRow(
        title: String,
        detail: String,
        isSelected: Bool,
        select: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(PanelTheme.secondary)
                .lineLimit(1)
                .foregroundStyle(PanelTheme.textPrimary)
            Text(detail)
                .font(PanelTheme.caption)
                .lineLimit(1)
                .foregroundStyle(PanelTheme.textTertiary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .selectableRow(isSelected: isSelected)
        .contentShape(Rectangle())
        .onTapGesture { select() }
    }

    private var languageSummary: String {
        let from = viewModel.sourceLanguage?.displayName ?? "Detected"
        return "\(from) → \(viewModel.targetLanguage.displayName)"
    }
}

private extension Creativity {
    var detail: String {
        switch self {
        case .precise: return "Stay literal"
        case .balanced: return "Default"
        case .creative: return "Bolder rewrites"
        }
    }
}

extension SpeechVoiceQuality {
    var displayName: String {
        switch self {
        case .missing: return "none installed"
        case .compact: return "compact"
        case .enhanced: return "enhanced"
        case .premium: return "premium"
        }
    }
}

extension PanelAppearance {
    var displayName: String {
        switch self {
        case .system: return "Auto"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

extension TextLanguage {
    var shortCode: String {
        switch self {
        case .english: return "EN"
        case .russian: return "RU"
        case .ukrainian: return "UA"
        case .spanish: return "ES"
        case .other: return "—"
        }
    }
}
