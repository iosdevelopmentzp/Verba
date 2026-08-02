import AppKit
import Observation
import SwiftUI

@MainActor
final class PanelWindowController: NSObject {

    // MARK: Dependencies

    private let logger: AppLogger

    // MARK: Private properties

    private let panel: FloatingPanel
    private let viewModel: PanelViewModel

    // MARK: Static

    private static let width: CGFloat = PanelTheme.width
    private static let minimumHeight: CGFloat = 80
    private static let topScreenFraction: CGFloat = 0.28
    private static let bottomMargin: CGFloat = 24
    private static let animationDuration: TimeInterval = 0.12
    private static let pasteboardPrivacyPaneURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Pasteboard"
    )!

    // MARK: Init

    init(
        logger: AppLogger,
        captureTextUseCase: CaptureTextUseCase,
        processTextUseCase: ProcessTextUseCase,
        deliverResultUseCase: DeliverResultUseCase,
        preferences: PreferenceStoring,
        usageMeter: UsageMetering
    ) {
        self.logger = logger
        panel = FloatingPanel(contentRect: NSRect(x: 0, y: 0, width: Self.width, height: 0))
        viewModel = PanelViewModel(
            captureTextUseCase: captureTextUseCase,
            processTextUseCase: processTextUseCase,
            deliverResultUseCase: deliverResultUseCase,
            preferences: preferences,
            usageMeter: usageMeter,
            logger: logger
        )
        super.init()
    }

    // MARK: Lifecycle

    func start() {
        viewModel.onRequestClose = { [weak self] in self?.hide() }
        viewModel.onOpenSettingsRequested = {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }
        viewModel.onOpenSystemSettingsRequested = {
            NSWorkspace.shared.open(Self.pasteboardPrivacyPaneURL)
        }

        let hostingView = NSHostingView(rootView: PanelRootView(viewModel: viewModel))
        hostingView.autoresizingMask = [.width, .height]
        panel.contentView = hostingView
        panel.onCancel = { [weak self] in self?.hide() }

        observeContentChanges()
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
        reveal()
        viewModel.beginCapture()
    }

    func present(_ sourceText: SourceText) {
        viewModel.present(sourceText)
        guard panel.isVisible == false else { return }
        reveal()
    }

    func hide() {
        guard panel.isVisible else { return }
        viewModel.prepareForDismissal()
        panel.orderOut(nil)
        logger.panelHidden(windowCount: NSApp.windows.count)
    }

    // MARK: Private methods

    private func observeContentChanges() {
        withObservationTracking {
            _ = viewModel.state
        } onChange: { [weak self] in
            Task { @MainActor in
                self?.resizeToFitContent()
                self?.observeContentChanges()
            }
        }
    }

    private func resizeToFitContent() {
        guard panel.isVisible else { return }
        var frame = panel.frame
        let topEdge = frame.maxY
        let newHeight = contentHeight()
        guard abs(frame.height - newHeight) > 0.5 else { return }

        frame.size.height = newHeight
        frame.origin.y = topEdge - newHeight
        let animate = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion == false
        panel.setFrame(frame, display: true, animate: animate)
        panel.invalidateShadow()
    }

    private func reveal() {
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

    private func frameCenteredOnMouseScreen() -> NSRect {
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) }) ?? NSScreen.main
        guard let screen else { return panel.frame }

        let topInset = screen.frame.height * Self.topScreenFraction
        viewModel.maxContentHeight = screen.frame.height - topInset - Self.bottomMargin

        let height = contentHeight()
        let originX = screen.frame.midX - Self.width / 2
        let originY = screen.frame.maxY - topInset - height
        return NSRect(x: originX, y: originY, width: Self.width, height: height)
    }

    private func contentHeight() -> CGFloat {
        guard let contentView = panel.contentView else { return Self.minimumHeight }
        contentView.setFrameSize(NSSize(width: Self.width, height: contentView.frame.height))
        contentView.layoutSubtreeIfNeeded()
        return max(contentView.fittingSize.height, Self.minimumHeight)
    }
}
