import SwiftUI

struct InstructionOverlayView: View {
    let state: InstructionEditorState
    let onDraftChange: (String) -> Void
    let onClear: () -> Void
    let onApply: () -> Void
    let onDismiss: () -> Void

    @FocusState private var isFieldFocused: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.42)
                .contentShape(Rectangle())
                .onTapGesture { onDismiss() }

            card
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Extra instruction")
                    .font(PanelTheme.title)
                    .foregroundStyle(PanelTheme.textPrimary)

                Text("Applies on top of the \(state.actionTitle.lowercased()) prompt, for this panel session only")
                    .font(PanelTheme.caption)
                    .foregroundStyle(PanelTheme.textTertiary)
            }

            TextField("Keep the emoji. Do not shorten the last sentence.", text: draftBinding)
                .textFieldStyle(.plain)
                .font(PanelTheme.body)
                .foregroundStyle(PanelTheme.textPrimary)
                .focused($isFieldFocused)
                .onSubmit { onApply() }
                .padding(10)
                .background(PanelTheme.editable, in: PanelTheme.cardShape)
                .overlay { PanelTheme.cardShape.strokeBorder(PanelTheme.editableBorder.opacity(0.55), lineWidth: 1) }

            HStack(spacing: 10) {
                Button(applyTitle) { onApply() }
                    .controlSize(.regular)
                    .keyboardShortcut(.defaultAction)

                if state.draft.isEmpty == false {
                    Button("Clear") { onClear() }
                        .controlSize(.regular)
                }

                Spacer(minLength: 0)

                Text("⏎ apply · esc cancel")
                    .font(PanelTheme.caption)
                    .foregroundStyle(PanelTheme.textTertiary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PanelTheme.background, in: PanelTheme.cardShape)
        .overlay { PanelTheme.cardShape.strokeBorder(PanelTheme.hairline, lineWidth: 1) }
        .shadow(color: .black.opacity(0.22), radius: 20, y: 8)
        .padding(.horizontal, 28)
        .onAppear { isFieldFocused = true }
    }

    private var applyTitle: String {
        state.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && state.hadInstruction
            ? "Remove and rerun"
            : "Apply and rerun"
    }

    private var draftBinding: Binding<String> {
        Binding(
            get: { state.draft },
            set: { onDraftChange($0) }
        )
    }
}
