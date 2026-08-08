import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    let viewModel: SettingsViewModel

    var body: some View {
        Form {
            KeyboardShortcuts.Recorder("Toggle panel", name: viewModel.shortcutName)
            ProviderSettingsSection(viewModel: viewModel)

            Section("Panel") {
                Button("Reset panel position") { viewModel.resetPanelPosition() }
                    .disabled(viewModel.hasSavedPanelPosition == false)

                Button("Reset saved prompt edits") { viewModel.resetPromptOverrides() }
                    .disabled(viewModel.hasPromptOverrides == false)
            }
        }
        .padding(20)
        .frame(width: 420)
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.cancelTesting() }
    }
}
