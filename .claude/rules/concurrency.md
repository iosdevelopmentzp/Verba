# Concurrency

- `@MainActor` on view models and anything touching AppKit; nothing else.
- Long-lived mutable state that is not UI lives in an `actor`
  (`ResultCache`, `UsageMeter`).
- Every `Task` started from the panel is stored and cancelled on
  dismiss. No fire-and-forget `Task {}` in view models.
- No `DispatchQueue`, no `@unchecked Sendable`, no
  `nonisolated(unsafe)` — if the compiler complains, fix the design.
- Swift 6.2 strict concurrency (`SWIFT_STRICT_CONCURRENCY = complete`)
  is on project-wide; every type crossing an `async` boundary must be
  genuinely `Sendable`.

## Cancellation on dismiss

Dismissing the panel (Esc, resign-key, a second hotkey press, or a
completed copy) must cancel any in-flight `Task` for that panel session
before starting or reusing another one. A cancelled request propagates
as `AppError.cancelled` and must not write to the cache or the usage
meter — cancellation is silent to the user (no error UI, just close).

Re-running an action on the same captured text reuses the existing
`SourceText`; it does not need a new capture, but it does need a fresh
`Task` for the new request.
