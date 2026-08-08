import SwiftUI

struct KeyCapsuleView: View {
    let label: String
    let isHighlighted: Bool

    var body: some View {
        Text(label)
            .font(PanelTheme.key)
            .monospacedDigit()
            .foregroundStyle(isHighlighted ? PanelTheme.selectionText : PanelTheme.textSecondary)
            .frame(minWidth: 22)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(
                isHighlighted ? PanelTheme.selectionKeyCap : PanelTheme.keyCap,
                in: RoundedRectangle(cornerRadius: 6, style: .continuous)
            )
    }
}
