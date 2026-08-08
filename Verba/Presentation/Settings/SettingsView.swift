import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    let viewModel: SettingsViewModel

    var body: some View {
        Form {
            KeyboardShortcuts.Recorder("Toggle panel", name: viewModel.shortcutName)
            ProviderSettingsSection(viewModel: viewModel)

            Section("Speech") {
                Text(viewModel.voiceSummary)
                    .font(.callout)
                    .foregroundStyle(.secondary)

                if viewModel.needsBetterVoices {
                    Text("Only compact voices are installed. Enhanced and Premium voices are free and sound much better.")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    Button("Open Accessibility settings") { viewModel.openVoiceDownloads() }
                    Text("Spoken Content › System Voice › Manage Voices")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

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
