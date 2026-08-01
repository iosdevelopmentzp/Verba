# Verba

Verba is a macOS menu-bar utility that improves short text via an LLM API
at the moment before sending it — grammar fixes, rephrasing, tone changes,
humanizing, and RU⇄EN translation — driven entirely by keyboard: ⌘C in the
source app, a global hotkey opens the panel, pick an action, ⏎ copies the
result, ⌘V back in the source app.

**The dependency rule:** `Domain` knows nobody; `Data` and `Presentation`
know only `Domain`; `App` knows everybody.

## Key directories

| Path | Layer |
|---|---|
| `Verba/App/` | Composition root: app entry, delegate, panel/hotkey wiring |
| `Verba/Presentation/` | SwiftUI views and view models |
| `Verba/Domain/` | Entities, protocols, use cases — pure Foundation |
| `Verba/Data/` | LLM client, Keychain, pasteboard, cache, prompts |
| `Verba/Resources/` | Info.plist, asset catalog |
| `Scripts/check-layers.sh` | Build-phase script enforcing the dependency rule |

## Hard constraints

1. No Accessibility API — no `AXUIElement`, no global event monitors, no
   screen reading. The hotkey uses Carbon `RegisterEventHotKey` via
   `KeyboardShortcuts`.
2. No event synthesis (`CGEventPost`) in the MVP.
3. User text never reaches a log line, an error message, a crash string,
   or a filename.
4. No API key in the repo, `UserDefaults`, or a plist — Keychain only.
5. The panel must never activate the app or steal focus from the source
   app.
6. No comments that restate the code.
7. **No tests.** No unit tests, no UI tests, no test target, no testing
   framework. Verification is manual — see HANDOFF.md §11. Because there
   is no safety net, changes must be precise and side-effect-free.

## Rules

@.claude/rules/architecture.md
@.claude/rules/swift-style.md
@.claude/rules/concurrency.md
@.claude/rules/errors-and-logging.md
@.claude/rules/llm-layer.md
@.claude/rules/ui-panel.md

## Skills

| Skill | Use it to |
|---|---|
| `add-text-action` | Add a new action to the panel's action list |
| `add-llm-provider` | Add a new LLM provider alongside OpenAI |
| `run-and-debug` | Build, run, reset local state, and test error paths |
| `commit` | Write a Conventional Commit and check for debug markers |

## Deviations

- **Stage 1 — `Presentation/Settings` imports `KeyboardShortcuts`.** The
  architecture table says `Presentation` may import only `SwiftUI`,
  `Domain`, and `os`, but HANDOFF.md §14 Stage 1 explicitly places the
  `KeyboardShortcuts.Recorder` control in `SettingsView.swift`, which
  requires importing that package there. `KeyboardShortcuts` is a UI-only,
  no-TCC-permission package (not networking, not persistence, not
  pasteboard), so `Scripts/check-layers.sh` does not flag it and the spirit
  of the dependency rule (no `Data`-layer leakage into `Presentation`)
  still holds. The `KeyboardShortcuts.Name` extension itself lives in
  `App/HotkeyController.swift`, the single source of truth for the
  `togglePanel` shortcut name.
- **Stage 1 — panel appearance animates fade only, not fade+scale.**
  Scaling the hosting view's layer scales about its bottom-left corner,
  because AppKit pins a layer-backed `NSView`'s `anchorPoint` to
  `(0, 0)`. Correcting it fights autoresizing every time the panel's
  height changes with state. Stage 6 owns the visual pass and can
  reintroduce a centred scale by animating the window frame instead.
- **Stage 2 — `NSPasteboard.accessBehavior` is read-only.** HANDOFF.md
  §6.6 says to "set `NSPasteboard.accessBehavior` appropriately." The
  macOS 26.5 SDK header (`NSPasteboard.h`) declares it
  `@property (readonly, assign) NSPasteboardAccessBehavior accessBehavior`
  — the user sets it per-app in System Settings; the app can only read
  it. `PasteboardTextSource` reads it once to short-circuit to
  `.pasteboardAccessDenied` when the value is `.alwaysDeny`, without
  attempting a content read.
- **Stage 2 — no generic "string present" `detect*` API exists.**
  HANDOFF.md §6.6 says to "use the non-prompting `detect*` API to check
  a string type is present before reading." The actual macOS 15.4+
  non-prompting surface (`NSPasteboard.detectedPatterns(for:)`,
  `detectedValues(for:)`, `detectedMetadata(for:)`, confirmed from
  `AppKit.swiftinterface`) only covers specific Data Detector patterns
  (web URL, web search, number, links, phone numbers, email/postal
  addresses, calendar events, tracking numbers, flight numbers, money
  amounts) — there is no pattern for "a plain string is present."
  `PasteboardTextSource` instead calls the older, still-current
  `canReadItem(withDataConformingToTypes:)` (macOS 10.6), which checks
  type presence without reading the item's data payload and so does not
  trigger the privacy prompt — the same non-prompting property the spec
  asked for, under a different, real name.
- **Stage 3 — output-token budget raised, reasoning effort set to
  `minimal`.** HANDOFF.md §6.2 specifies
  `min(1200, inputTokenEstimate * 2 + 200)`. On the GPT-5 family
  reasoning tokens are billed against `max_output_tokens` and the
  budget can be exhausted *before any visible output token is
  produced* — the response comes back `status: "incomplete"` with
  `incomplete_details.reason == "max_output_tokens"`. A typical Slack
  message would have been given ~250 tokens, so the common case was at
  risk. The formula now floors at 700 and ceilings at 2000, effort is
  `minimal` rather than `low`, and a truncated response is retried once
  with double the budget before surfacing `.malformedResponse`.
- **Stage 4 — the panel's "Open Settings" recovery button uses
  `NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from:
  nil)` instead of `@Environment(\.openSettings)`.** `VerbaApp`'s own
  menu bar button already used the SwiftUI `openSettings` environment
  action successfully, but that button lives inside `MenuBarExtra`'s
  content, which SwiftUI renders as part of the app's real `Scene`
  graph. `PanelRootView` is hosted through a manually-created
  `NSHostingView` assigned to `FloatingPanel.contentView` — it is never
  part of that `Scene` graph — so there is no guarantee the environment
  action resolves to a working handler there, and this could not be
  interactively verified. `PanelViewModel.onOpenSettingsRequested` is a
  plain closure wired in `PanelWindowController.start()`, keeping the
  AppKit call in the `App` layer where it belongs; `ErrorView` only
  calls the closure, never AppKit directly.
- **Stage 4 — `ErrorView`'s `.rateLimited` message is a single string,
  not the two-phase "Retrying in ⁠…s… then Still rate limited." from
  §10.** The one automatic retry already happens inside
  `LLMTextProcessor`/`RetryPolicy` before `ProcessTextUseCase` ever
  throws; by the time `AppError.rateLimited` reaches `PanelViewModel`,
  that retry has already been attempted and failed, so a live countdown
  would be fiction. `ErrorView` shows "Still rate limited." Stage 5, which
  owns the full error matrix, can plumb a genuine retry-in-progress
  signal from `Data` to `Presentation` if a live countdown is wanted.
