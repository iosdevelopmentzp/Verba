import Foundation

enum ErrorPresentation {
    static func message(for error: AppError) -> String {
        switch error {
        case .missingAPIKey:
            return "Add your OpenAI API key to get started."
        case .emptyInput:
            return "Nothing to work with — copy some text first."
        case .inputTooLong(let actual, let limit):
            return "Text too long — \(actual.formatted()) characters, limit is \(limit.formatted())."
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
        case .malformedRequest:
            return "Verba sent a request this model rejected. Try another model in Settings."
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
