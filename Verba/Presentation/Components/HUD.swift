import SwiftUI

struct HUD: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "checkmark.circle.fill")
            .font(PanelTheme.secondary.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(Color.accentColor, in: Capsule())
            .shadow(color: .black.opacity(0.18), radius: 8, y: 3)
    }
}
