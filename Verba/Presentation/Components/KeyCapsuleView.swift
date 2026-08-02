import SwiftUI

struct KeyCapsuleView: View {
    let label: String
    let isHighlighted: Bool

    var body: some View {
        Text(label)
            .font(PanelTheme.key)
            .monospacedDigit()
            .foregroundStyle(isHighlighted ? Color.white : PanelTheme.textSecondary)
            .frame(minWidth: 22)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(
                isHighlighted ? Color.white.opacity(0.22) : PanelTheme.keyCap,
                in: RoundedRectangle(cornerRadius: 6, style: .continuous)
            )
    }
}
