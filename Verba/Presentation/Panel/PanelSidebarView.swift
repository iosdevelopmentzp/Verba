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

    private var rail: some View {
        VStack(spacing: 6) {
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

    private var expanded: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                chevron
                Text("OPTIONS")
                    .font(PanelTheme.sectionLabel)
                    .foregroundStyle(PanelTheme.textTertiary)
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
            .onTapGesture { viewModel.toggleSidebar() }

            group(title: "Style", keyLabel: "⌘J") {
                ForEach(Creativity.allCases, id: \.self) { option in
                    OptionRow(
                        title: option.displayName,
                        detail: option.detail,
                        isSelected: option == viewModel.creativity
                    )
                    .onTapGesture { viewModel.setCreativity(option) }
                }
            }

            if viewModel.canConfigureLanguages {
                group(title: "Translate from", keyLabel: "⌘⇧T") {
                    OptionRow(title: "Detect", detail: nil, isSelected: viewModel.sourceLanguage == nil)
                        .onTapGesture { viewModel.setSourceLanguage(nil) }

                    ForEach(TextLanguage.selectable, id: \.self) { language in
                        OptionRow(
                            title: language.displayName,
                            detail: nil,
                            isSelected: viewModel.sourceLanguage == language
                        )
                        .onTapGesture { viewModel.setSourceLanguage(language) }
                    }
                }

                group(title: "Translate into", keyLabel: "⌘T") {
                    ForEach(TextLanguage.selectable, id: \.self) { language in
                        OptionRow(
                            title: language.displayName,
                            detail: nil,
                            isSelected: viewModel.targetLanguage == language
                        )
                        .onTapGesture { viewModel.setTargetLanguage(language) }
                    }
                }
            }

            group(title: "Model", keyLabel: nil) {
                OptionRow(title: "Standard", detail: "Better output", isSelected: viewModel.economyMode == false)
                    .onTapGesture { viewModel.setEconomyMode(false) }
                OptionRow(title: "Economy", detail: "Cheaper, faster", isSelected: viewModel.economyMode)
                    .onTapGesture { viewModel.setEconomyMode(true) }
            }

            if viewModel.canToggleDiff {
                group(title: "Diff", keyLabel: "⌘D") {
                    OptionRow(title: viewModel.isDiffShown ? "Shown" : "Hidden", detail: nil, isSelected: viewModel.isDiffShown)
                        .onTapGesture { viewModel.toggleDiff() }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(width: PanelTheme.sidebarWidth, alignment: .leading)
    }

    private var chevron: some View {
        Image(systemName: viewModel.isSidebarExpanded ? "chevron.right" : "chevron.left")
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(PanelTheme.textTertiary)
    }

    private func group<Content: View>(
        title: String,
        keyLabel: String?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(title.uppercased())
                    .font(PanelTheme.sectionLabel)
                    .foregroundStyle(PanelTheme.textTertiary)
                Spacer(minLength: 0)
                if let keyLabel {
                    KeyCapsuleView(label: keyLabel, isHighlighted: false)
                }
            }
            content()
        }
    }
}

private struct OptionRow: View {
    let title: String
    let detail: String?
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(PanelTheme.secondary)
                    .foregroundStyle(isSelected ? Color.white : PanelTheme.textPrimary)
                if let detail {
                    Text(detail)
                        .font(PanelTheme.caption)
                        .foregroundStyle(isSelected ? Color.white.opacity(0.75) : PanelTheme.textTertiary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? PanelTheme.selection : Color.clear, in: PanelTheme.rowShape)
        .contentShape(Rectangle())
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
