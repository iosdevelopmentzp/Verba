import AppKit
import SwiftUI

@MainActor
final class PanelWindowController: NSObject {

    // MARK: Dependencies

    private let logger: AppLogger

    // MARK: Private properties

    private let panel: FloatingPanel

    // MARK: Static

    private static let width: CGFloat = 560
    private static let topScreenFraction: CGFloat = 0.28
    private static let animationDuration: TimeInterval = 0.12

    // MARK: Init

    init(logger: AppLogger) {
        self.logger = logger
        panel = FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: Self.width, height: 0))
        super.init()
    }

    // MARK: Lifecycle

    func start() {
        let hostingView = NSHostingView(rootView: PanelRootView())
        hostingView.autoresizingMask = [.width, .height]
        panel.contentView = hostingView
        panel.delegate = self
        panel.onCancel = { [weak self] in self?.hide() }
    }

    // MARK: Public methods

    func toggle() {
        if panel.isVisible {
            hide()
        } else {
            show()
        }
    }

    func show() {
        guard panel.isVisible == false else { return }

        let frame = frameCenteredOnMouseScreen()
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

        guard reduceMotion == false else {
            panel.setFrame(frame, display: true)
            panel.alphaValue = 1
            panel.orderFrontRegardless()
            panel.makeKey()
            logger.panelShown(windowCount: NSApp.windows.count)
            return
        }

        panel.alphaValue = 0
        panel.setFrame(frame, display: true)
        panel.orderFrontRegardless()
        panel.makeKey()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = Self.animationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        }

        logger.panelShown(windowCount: NSApp.windows.count)
    }

    func hide() {
        guard panel.isVisible else { return }
        panel.orderOut(nil)
        logger.panelHidden(windowCount: NSApp.windows.count)
    }

    // MARK: Private methods

    private func frameCenteredOnMouseScreen() -> NSRect {
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) }) ?? NSScreen.main
        guard let screen else { return panel.frame }

        let height = contentHeight()
        let originX = screen.frame.midX - Self.width / 2
        let topInset = screen.frame.height * Self.topScreenFraction
        let originY = screen.frame.maxY - topInset - height
        return NSRect(x: originX, y: originY, width: Self.width, height: height)
    }

    private func contentHeight() -> CGFloat {
        guard let contentView = panel.contentView else { return 0 }
        contentView.setFrameSize(NSSize(width: Self.width, height: contentView.frame.height))
        return contentView.fittingSize.height
    }
}

extension PanelWindowController: NSWindowDelegate {
    func windowDidResignKey(_ notification: Notification) {
        hide()
    }
}
