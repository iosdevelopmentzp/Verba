import SwiftUI

struct PanelRootView: View {
    @Bindable var viewModel: PanelContentViewModel
    @FocusState private var isDraftFocused: Bool

    var body: some View {
        content
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var content: some View {
        if let sourceText = viewModel.sourceText {
            SourcePreviewView(sourceText: sourceText)
        } else {
            manualEntry
        }
    }

    private var manualEntry: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Verba")
                .font(.title2.weight(.semibold))

            TextField("⌘C some text, or type here", text: $viewModel.manualDraft, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.body)
                .lineLimit(1...5)
                .focused($isDraftFocused)

            Button("Accept") { viewModel.acceptManualEntry() }
                .keyboardShortcut(.return, modifiers: .command)
                .controlSize(.small)
        }
        .onAppear { isDraftFocused = true }
    }
}
