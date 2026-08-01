import SwiftUI

struct PanelRootView: View {
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Verba")
                .font(.title2.weight(.semibold))
            Text("Stage 1 — panel skeleton")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .focusable()
        .focused($isFocused)
        .onAppear { isFocused = true }
    }
}
