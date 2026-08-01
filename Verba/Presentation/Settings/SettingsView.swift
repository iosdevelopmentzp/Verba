import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    let viewModel: SettingsViewModel

    var body: some View {
        Form {
            KeyboardShortcuts.Recorder("Toggle panel", name: viewModel.shortcutName)
        }
        .padding(20)
        .frame(width: 360)
    }
}
