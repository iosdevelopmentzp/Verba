# Errors and logging

`AppError` is the only error type allowed to cross a layer boundary.
`Data` maps `URLError`, HTTP status codes, and decoding failures into it;
nothing above `Data` ever sees an `NSError`, a raw `URLError`, or a
string error.

```swift
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
```

## Mapping (`OpenAIErrorMapper`)

| Condition | `AppError` |
|---|---|
| `.notConnectedToInternet`, `.networkConnectionLost`, `.cannotFindHost`, `.dataNotAllowed` | `.offline` |
| `URLError.timedOut` or the 20s deadline | `.timedOut` |
| `CancellationError`, `URLError.cancelled` | `.cancelled` |
| HTTP 401, 403 | `.unauthorized` |
| HTTP 429 | `.rateLimited(retryAfter:)` from `Retry-After` |
| HTTP 500–599 | `.providerUnavailable(status:)` |
| JSON decode failure, missing fields, non-JSON content | `.malformedResponse` |
| anything else | `.unknown` |

Never put the response body into the error.

## Logging (`AppLogger`)

Thin wrapper over `os.Logger`, subsystem `com.dmytrovorko.verba`,
categories: `app`, `hotkey`, `panel`, `capture`, `llm`, `keychain`,
`usage`.

**Allowed:** action id, model id, provider id, character count, latency
in ms, token counts, HTTP status, `AppError` case name, cache hit/miss.

**Forbidden:** the text, any substring of it, clipboard contents, the
API key, the response body, the prompt with the text interpolated.

Logging helpers take `charCount: Int`, never `text: String`, so a caller
cannot accidentally pass raw text.
