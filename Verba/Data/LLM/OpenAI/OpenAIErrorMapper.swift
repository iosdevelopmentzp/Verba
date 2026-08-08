import Foundation

enum OpenAIErrorMapper {
    static func map(networkError: Error) -> AppError {
        if let appError = networkError as? AppError { return appError }
        if networkError is CancellationError { return .cancelled }
        guard let urlError = networkError as? URLError else { return .unknown }

        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .dataNotAllowed:
            return .offline
        case .timedOut:
            return .timedOut
        case .cancelled:
            return .cancelled
        default:
            return .unknown
        }
    }

    static func map(httpStatus: Int, retryAfter: TimeInterval?) -> AppError {
        switch httpStatus {
        case 400, 404, 422:
            return .malformedRequest(status: httpStatus)
        case 401, 403:
            return .unauthorized
        case 429:
            return .rateLimited(retryAfter: retryAfter)
        case 500...599:
            return .providerUnavailable(status: httpStatus)
        default:
            return .unknown
        }
    }
}
