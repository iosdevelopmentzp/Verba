import AppKit
import Foundation

@MainActor
final class PasteboardTextSource: TextCapturing {

    // MARK: Private properties

    private var lastSeenChangeCount: Int?

    // MARK: Public methods

    func capture() async throws -> CapturedText? {
        let pasteboard = NSPasteboard.general

        guard pasteboard.accessBehavior != .alwaysDeny else {
            throw AppError.pasteboardAccessDenied
        }

        let stringTypePresent = pasteboard.canReadItem(
            withDataConformingToTypes: [NSPasteboard.PasteboardType.string.rawValue]
        )
        guard stringTypePresent else {
            lastSeenChangeCount = pasteboard.changeCount
            return nil
        }

        guard let rawContent = pasteboard.string(forType: .string) else {
            throw AppError.pasteboardAccessDenied
        }

        let isReused = pasteboard.changeCount == lastSeenChangeCount
        lastSeenChangeCount = pasteboard.changeCount

        let trimmed = rawContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return nil }

        return CapturedText(content: trimmed, origin: .pasteboard(isReused: isReused))
    }
}
