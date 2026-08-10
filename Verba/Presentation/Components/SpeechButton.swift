import SwiftUI

struct SpeechButton: View {
    let isSpeaking: Bool
    let action: () -> Void

    var body: some View {
        Image(systemName: isSpeaking ? "stop.fill" : "speaker.wave.2.fill")
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(isSpeaking ? PanelTheme.selectionText : PanelTheme.textTertiary)
            .frame(width: 22, height: 18)
            .background(isSpeaking ? PanelTheme.selectionKeyCap : PanelTheme.keyCap, in: Capsule())
            .contentShape(Capsule())
            .onTapGesture { action() }
            .help(isSpeaking ? "Stop" : "Listen")
    }
}
