import SwiftUI

struct Badge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(PanelTheme.caption)
            .foregroundStyle(PanelTheme.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(PanelTheme.keyCap, in: Capsule())
    }
}
