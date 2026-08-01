import Observation
import KeyboardShortcuts

@MainActor
@Observable
final class SettingsViewModel {
    let shortcutName = KeyboardShortcuts.Name.togglePanel
}
