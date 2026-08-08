import AppKit

@MainActor
final class FloatingPanel: NSPanel {

    // MARK: Public properties

    var onCancel: (() -> Void)?
    var onCopyRequested: (() -> Void)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    // MARK: Init

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        isFloatingPanel = true
        hidesOnDeactivate = false
        becomesKeyOnlyIfNeeded = false
        isMovableByWindowBackground = true
        isReleasedWhenClosed = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        appearance = NSAppearance(named: .aqua)
    }

    // MARK: Public methods

    override func cancelOperation(_ sender: Any?) {
        onCancel?()
    }

    // The Edit menu's default Copy item claims ⌘C as a key equivalent before
    // SwiftUI's onKeyPress ever sees the event; @objc exposes this to that
    // same responder-chain action dispatch so it lands here instead of
    // NSBeep-ing for an unimplemented selector.
    @objc func copy(_ sender: Any?) {
        onCopyRequested?()
    }
}
