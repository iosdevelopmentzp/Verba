import SwiftUI

struct PromptOverlayView: View {
    let state: PromptEditorState
    let actionTitle: String
    let onBodyChange: (String) -> Void
    let onPersistenceChange: (Bool) -> Void
    let onReset: () -> Void
    let onApply: () -> Void
    let onDismiss: () -> Void

    // MARK: Static

    private static let editorMinHeight: CGFloat = 150

    // MARK: Body

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
        VStack(alignment: .leading, spacing: 0) {
            header
            HairlineDivider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    lockedSection
                    editorSection
                }
                .padding(16)
            }

            HairlineDivider()
            footer
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PanelTheme.background, in: PanelTheme.cardShape)
        .overlay { PanelTheme.cardShape.strokeBorder(PanelTheme.hairline, lineWidth: 1) }
        .clipShape(PanelTheme.cardShape)
        .shadow(color: .black.opacity(0.22), radius: 20, y: 8)
        .padding(20)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Prompt")
                    .font(PanelTheme.title)
                    .foregroundStyle(PanelTheme.textPrimary)

                Text("What Verba tells the model when you run \(actionTitle)")
                    .font(PanelTheme.caption)
                    .foregroundStyle(PanelTheme.textTertiary)
            }

            Spacer(minLength: 0)

            if isModified {
                Badge(text: "edited")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var lockedSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Always sent", systemImage: "lock.fill", tint: PanelTheme.textTertiary)

            Text(state.preamble)
                .font(PanelTheme.mono)
                .foregroundStyle(PanelTheme.textTertiary)
                .lineSpacing(2)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(PanelTheme.locked, in: PanelTheme.cardShape)

            Text("Defines the JSON contract. Not editable.")
                .font(PanelTheme.caption)
                .foregroundStyle(PanelTheme.textTertiary)
        }
    }

    private var editorSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("Your instruction", systemImage: "pencil", tint: PanelTheme.editableBorder)

            TextEditor(text: bodyBinding)
                .font(PanelTheme.mono)
                .foregroundStyle(PanelTheme.textPrimary)
                .lineSpacing(2)
                .scrollContentBackground(.hidden)
                .frame(minHeight: Self.editorMinHeight)
                .padding(8)
                .background(PanelTheme.editable, in: PanelTheme.cardShape)
                .overlay { PanelTheme.cardShape.strokeBorder(PanelTheme.editableBorder.opacity(0.55), lineWidth: 1) }

            HStack(spacing: 8) {
                Text("\(state.body.count) characters")
                    .font(PanelTheme.caption.monospacedDigit())
                    .foregroundStyle(PanelTheme.textTertiary)

                Spacer(minLength: 0)

                if isModified {
                    Text("Reset to default")
                        .font(PanelTheme.caption)
                        .foregroundStyle(PanelTheme.textSecondary)
                        .contentShape(Rectangle())
                        .onTapGesture { onReset() }
                }
            }
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("KEEP THIS EDIT")
                    .font(PanelTheme.sectionLabel)
                    .foregroundStyle(PanelTheme.textTertiary)

                ChipView(label: "This run only", isSelected: state.isPersistent == false)
                    .onTapGesture { onPersistenceChange(false) }

                ChipView(label: "Until I reset it", isSelected: state.isPersistent)
                    .onTapGesture { onPersistenceChange(true) }

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                Button("Apply and rerun") { onApply() }
                    .controlSize(.regular)
                    .keyboardShortcut(.defaultAction)

                Button("Cancel") { onDismiss() }
                    .controlSize(.regular)

                Spacer(minLength: 0)

                Text(state.isPersistent ? "Saved for every future run" : "Forgotten when the panel closes")
                    .font(PanelTheme.caption)
                    .foregroundStyle(PanelTheme.textTertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(PanelTheme.surface)
    }

    private func sectionLabel(_ title: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: 9, weight: .semibold))
            Text(title.uppercased())
                .font(PanelTheme.sectionLabel)
        }
        .foregroundStyle(tint)
    }

    private var isModified: Bool {
        state.body.trimmingCharacters(in: .whitespacesAndNewlines)
            != state.defaultBody.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var bodyBinding: Binding<String> {
        Binding(
            get: { state.body },
            set: { onBodyChange($0) }
        )
    }
}
