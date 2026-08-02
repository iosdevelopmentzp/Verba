import SwiftUI

struct ErrorView: View {
    let error: AppError
    let onRetry: () -> Void
    let onOpenSettings: () -> Void
    let onOpenSystemSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(message)
                .font(.body)

            if let recovery {
                Button(recovery.title, action: recovery.action)
                    .controlSize(.small)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private struct Recovery {
        let title: String
        let action: () -> Void
    }

    private var recovery: Recovery? {
        switch error {
        case .missingAPIKey, .unauthorized:
            return Recovery(title: "Open Settings", action: onOpenSettings)
        case .pasteboardAccessDenied:
            return Recovery(title: "Open System Settings", action: onOpenSystemSettings)
        case .offline, .timedOut, .rateLimited, .providerUnavailable, .malformedResponse, .unknown:
            return Recovery(title: "Retry", action: onRetry)
        case .emptyInput, .inputTooLong, .cancelled:
            return nil
        }
    }

    private var message: String {
        ErrorPresentation.message(for: error)
    }
}
