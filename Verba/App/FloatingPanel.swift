import AppKit

@MainActor
final class FloatingPanel: NSPanel {

    // MARK: Public properties

    var onCancel: (() -> Void)?

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
        isMovableByWindowBackground = false
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
}
