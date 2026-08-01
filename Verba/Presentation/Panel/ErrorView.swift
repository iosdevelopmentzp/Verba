import SwiftUI

struct ErrorView: View {
    let error: AppError
    let onRetry: () -> Void
    let onOpenSettings: () -> Void

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
        case .offline, .timedOut, .rateLimited, .providerUnavailable, .malformedResponse, .unknown:
            return Recovery(title: "Retry", action: onRetry)
        case .emptyInput, .inputTooLong, .pasteboardAccessDenied, .cancelled:
            return nil
        }
    }

    private var message: String {
        switch error {
        case .missingAPIKey:
            return "Add your OpenAI API key to get started."
        case .emptyInput:
            return "Nothing to work with — copy some text first."
        case .inputTooLong(let actual, let limit):
            return "Text too long — \(actual) characters, limit is \(limit)."
        case .offline:
            return "No internet connection."
        case .timedOut:
            return "The request timed out."
        case .rateLimited:
            return "Still rate limited."
        case .unauthorized:
            return "The API key was rejected."
        case .providerUnavailable(let status):
            return "OpenAI is having trouble (\(status))."
        case .malformedResponse:
            return "Couldn't read the model's response."
        case .pasteboardAccessDenied:
            return "Verba needs clipboard access. Allow it in System Settings → Privacy & Security → Pasteboard."
        case .cancelled:
            return ""
        case .unknown:
            return "Something went wrong."
        }
    }
}
