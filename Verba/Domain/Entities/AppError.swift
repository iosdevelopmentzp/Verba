import Foundation

enum AppError: Error, Equatable, Sendable {
    case missingAPIKey
    case emptyInput
    case inputTooLong(actual: Int, limit: Int)
    case offline
    case timedOut
    case rateLimited(retryAfter: TimeInterval?)
    case unauthorized
    case providerUnavailable(status: Int)
    case malformedResponse
    case pasteboardAccessDenied
    case cancelled
    case unknown
}
