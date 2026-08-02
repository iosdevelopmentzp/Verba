import SwiftUI

struct ErrorView: View {
    let error: AppError
    let onRetry: () -> Void
    let onOpenSettings: () -> Void
    let onOpenSystemSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)

                Text(message)
                    .font(PanelTheme.prominent)
                    .foregroundStyle(PanelTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let recovery {
                Button(recovery.title, action: recovery.action)
                    .controlSize(.regular)
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
