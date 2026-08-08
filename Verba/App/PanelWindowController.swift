import AppKit
import Observation
import SwiftUI

@MainActor
final class PanelWindowController: NSObject {

    // MARK: Dependencies

    private let logger: AppLogger
    private let preferences: PreferenceStoring

    // MARK: Private properties

    private let panel: FloatingPanel
    private let viewModel: PanelViewModel
    private var isPositioningProgrammatically = false

    private var width: CGFloat {
        PanelTheme.panelWidth(isSidebarExpanded: viewModel.isSidebarExpanded)
    }

    // MARK: Static

    private static let minimumHeight: CGFloat = 80
    private static let topScreenFraction: CGFloat = 0.28
    private static let bottomMargin: CGFloat = 24
    private static let animationDuration: TimeInterval = 0.12
    private static let pasteboardPrivacyPaneURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Pasteboard"
    )!
    private static let copySoundName = NSSound.Name("Tink")

    // MARK: Init

    init(
        logger: AppLogger,
        captureTextUseCase: CaptureTextUseCase,
        processTextUseCase: ProcessTextUseCase,
        deliverResultUseCase: DeliverResultUseCase,
        explainFixesUseCase: ExplainFixesUseCase,
        promptPreview: PromptPreviewing,
        speechSynthesizer: SpeechSynthesizing,
        preferences: PreferenceStoring,
        usageMeter: UsageMetering
    ) {
        self.logger = logger
        self.preferences = preferences
        panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: PanelTheme.width, height: 0)
        )
        viewModel = PanelViewModel(
            captureTextUseCase: captureTextUseCase,
            processTextUseCase: processTextUseCase,
            deliverResultUseCase: deliverResultUseCase,
            explainFixesUseCase: explainFixesUseCase,
            promptPreview: promptPreview,
            speechSynthesizer: speechSynthesizer,
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
        viewModel.onCopyCompleted = {
            NSSound(named: Self.copySoundName)?.play()
        }
        viewModel.onAppearanceChanged = { [weak self] appearance in
            self?.panel.apply(appearance)
        }
        panel.apply(viewModel.panelAppearance)
        panel.onCopyRequested = { [weak viewModel] in viewModel?.copyOriginal() }

        let hostingView = NSHostingView(rootView: PanelRootView(viewModel: viewModel))
        hostingView.autoresizingMask = [.width, .height]
        panel.contentView = hostingView
        panel.onCancel = { [weak viewModel] in viewModel?.handleEscape() }
        panel.delegate = self

        viewModel.startSpeechObservation()
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

    // MARK: - Private

    private func observeContentChanges() {
        withObservationTracking {
            viewModel.trackLayoutInputs()
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
        let newWidth = width
        guard abs(frame.height - newHeight) > 0.5 || abs(frame.width - newWidth) > 0.5 else { return }

        frame.size.height = newHeight
        frame.size.width = newWidth
        frame.origin.y = topEdge - newHeight
        setFrameProgrammatically(Self.clamped(frame, to: screen(containing: frame)), animate: false)
        panel.invalidateShadow()
    }

    private func setFrameProgrammatically(_ frame: NSRect, animate: Bool) {
        isPositioningProgrammatically = true
        panel.setFrame(frame, display: true, animate: animate)
        isPositioningProgrammatically = false
    }

    private func reveal() {
        let frame = targetFrame(preferringSavedOrigin: true)
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion

        guard reduceMotion == false else {
            setFrameProgrammatically(frame, animate: false)
            panel.alphaValue = 1
            panel.orderFrontRegardless()
            panel.makeKey()
            logger.panelShown(windowCount: NSApp.windows.count)
            return
        }

        panel.alphaValue = 0
        setFrameProgrammatically(frame, animate: false)
        panel.orderFrontRegardless()
        panel.makeKey()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = Self.animationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        }

        logger.panelShown(windowCount: NSApp.windows.count)
    }

    private func targetFrame(preferringSavedOrigin: Bool) -> NSRect {
        let savedTopLeft = preferringSavedOrigin ? self.savedTopLeft : nil
        let anchor = savedTopLeft ?? NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { $0.visibleFrame.contains(anchor) })
            ?? NSScreen.screens.first(where: { $0.frame.contains(NSEvent.mouseLocation) })
            ?? NSScreen.main
        guard let screen else { return panel.frame }

        let topInset = screen.frame.height * Self.topScreenFraction
        viewModel.maxContentHeight = screen.frame.height - topInset - Self.bottomMargin

        let height = contentHeight()
        guard let savedTopLeft else {
            let originX = screen.frame.midX - width / 2
            let originY = screen.frame.maxY - topInset - height
            return NSRect(x: originX, y: originY, width: width, height: height)
        }

        let frame = NSRect(x: savedTopLeft.x, y: savedTopLeft.y - height, width: width, height: height)
        return Self.clamped(frame, to: screen)
    }

    private var savedTopLeft: NSPoint? {
        guard let x = preferences.panelOriginX, let y = preferences.panelTopY else { return nil }
        return NSPoint(x: x, y: y)
    }

    private func screen(containing frame: NSRect) -> NSScreen? {
        let best = NSScreen.screens.max { lhs, rhs in
            Self.overlapArea(frame, lhs.visibleFrame) < Self.overlapArea(frame, rhs.visibleFrame)
        }
        return best ?? NSScreen.main
    }

    private static func overlapArea(_ frame: NSRect, _ other: NSRect) -> CGFloat {
        let intersection = frame.intersection(other)
        return intersection.isNull ? 0 : intersection.width * intersection.height
    }

    private static func clamped(_ frame: NSRect, to screen: NSScreen?) -> NSRect {
        guard let screen else { return frame }
        let bounds = screen.visibleFrame
        var clamped = frame
        clamped.origin.x = min(max(frame.origin.x, bounds.minX), max(bounds.minX, bounds.maxX - frame.width))
        clamped.origin.y = min(max(frame.origin.y, bounds.minY), max(bounds.minY, bounds.maxY - frame.height))
        return clamped
    }

    private func contentHeight() -> CGFloat {
        guard let contentView = panel.contentView else { return Self.minimumHeight }
        contentView.setFrameSize(NSSize(width: width, height: contentView.frame.height))
        contentView.layoutSubtreeIfNeeded()
        return max(contentView.fittingSize.height, Self.minimumHeight)
    }
}

extension PanelWindowController: NSWindowDelegate {
    func windowDidMove(_ notification: Notification) {
        guard isPositioningProgrammatically == false, panel.isVisible else { return }
        preferences.panelOriginX = panel.frame.origin.x
        preferences.panelTopY = panel.frame.maxY
    }
}
