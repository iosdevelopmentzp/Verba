import AppKit

@MainActor
struct PasteboardResultSink: ResultDelivering {
    func deliver(_ text: String) async {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
