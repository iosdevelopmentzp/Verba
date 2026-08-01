import Foundation

struct RetryPolicy: Sendable {

    // MARK: Static

    private static let baseDelay: TimeInterval = 1.5
    private static let jitterUpperBound: TimeInterval = 0.5

    // MARK: Public methods

    func shouldRetry(_ error: AppError) -> Bool {
        switch error {
        case .rateLimited, .providerUnavailable:
            return true
        default:
            return false
        }
    }

    func delay(for error: AppError) -> Duration {
        if case .rateLimited(let retryAfter) = error, let retryAfter {
            return .seconds(retryAfter)
        }
        let jitter = Double.random(in: 0...Self.jitterUpperBound)
        return .seconds(Self.baseDelay + jitter)
    }
}
