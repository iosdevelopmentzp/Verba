# Architecture

Four layers, one target, separated by folders and protocols:

```
App  ──►  Presentation  ──►  Domain  ◄──  Data
```

| Layer | May import | Must never import |
|---|---|---|
| `Domain` | `Foundation` | AppKit, SwiftUI, `Security`, `os`, any `Data` type |
| `Data` | `Foundation`, `Security`, `AppKit` (pasteboard only), `os`, `NaturalLanguage`, `Domain` | SwiftUI, any `Presentation` type |
| `Presentation` | `SwiftUI`, `Domain`, `os` | Any `Data` type, `URLSession`, any DTO |
| `App` | everything | — |

`Presentation` receives dependencies as `Domain` protocol existentials
only. It must be possible to delete the entire `Data` folder, stub the
protocols, and still build and run the UI.

`Scripts/check-layers.sh` enforces this as a Run Script build phase
(before Compile Sources) and fails the build on violation.

## Where new code goes

- A new business rule, value type, or contract → `Domain/Entities`,
  `Domain/Protocols`, or `Domain/UseCases`.
- A new way to talk to the outside world (network, Keychain, pasteboard,
  disk) → `Data`, behind a `Domain` protocol.
- A new screen, view model, or visual component → `Presentation`.
- Anything that wires concrete types together, owns app lifecycle, or
  touches `NSApplication` → `App`.

## Composition root

`App/AppContainer.swift` is the only place concrete types are named. It
builds every dependency once and exposes them as `Domain` protocol types
to view models. No singletons elsewhere, no service locator, no global
`shared` other than `AppLogger`.

## Adding a layer-crossing dependency

1. Define (or extend) a protocol in `Domain/Protocols`.
2. Implement it in `Data` (or stub it for previews/tests).
3. Wire the concrete type in `AppContainer` only.
4. `Presentation` and other `Domain` consumers depend on the protocol
   type, never the concrete one.
