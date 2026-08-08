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
4. No API key in the repo, `UserDefaults`, or a plist — Keychain only in
   Release builds. See the Deviations entry on `UserDefaultsSecretStore`
   for the `DEBUG`-only exception.
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
- **Stage 5 — `ActionResult` gained a `tier: ModelTier` field beyond
  the exact §5 definition.** Deliverable 4 requires the active model
  tier to be "visible somewhere... so the user can tell which tier
  ran." `ModelTier` is a plain Domain enum with no platform
  dependency, so carrying it alongside the existing `cameFromCache`
  flag keeps the tier available wherever a result is (cache hit or
  fresh), without adding a second round-trip or a new protocol just to
  ask "what tier was this?" after the fact. `ResultView` renders it as
  a small badge next to the `cached` marker.
- **Stage 5 — `PasteboardTextSource`/`PanelViewModel` fix: capture
  errors other than a genuinely-empty clipboard now reach
  `.failed`.** `PanelViewModel.performCapture()` previously funneled
  every thrown `AppError` from capture into manual-entry mode,
  silently discarding `.pasteboardAccessDenied`. It now distinguishes
  "nothing on the clipboard" (`nil`, still → manual entry) from an
  actual thrown error (→ `.failed(source: nil, action: nil, error:)`),
  matching this stage's explicit instruction.
- **Stage 5 — "Open System Settings" opens
  `x-apple.systempreferences:com.apple.preference.security?Privacy_Pasteboard`.**
  HANDOFF.md doesn't name a URL for this pane (pasteboard privacy is a
  macOS 15.4+ feature, newer than the handoff draft). Confirmed via
  Apple's own May 2025 pasteboard-privacy preview coverage that this is
  the pane identifier System Settings itself registers for "Paste from
  Other Apps." Wired in `PanelWindowController.start()` via
  `NSWorkspace.shared.open(_:)`, keeping the AppKit call in `App`; the
  Keychain-item deny/allow toggle itself cannot be scripted from inside
  the app (`NSPasteboard.accessBehavior` is read-only, per the Stage 2
  deviation above), so this could not be exercised end-to-end without a
  human flipping the System Settings toggle by hand — traced by reading
  `PasteboardTextSource.capture()` and `PanelViewModel.performCapture()`
  instead.
- **Stage 5 — `.emptyInput` is unreachable through the shipped panel
  UI, by design.** `CaptureTextUseCase.make(content:origin:)` — the
  single choke point behind both pasteboard capture and manual-entry
  accept — already trims and rejects empty content before a
  `SourceText` can exist, and this stage's own instructions say
  genuinely-empty input must keep going to manual entry, not to an
  error state. `ProcessTextUseCase`'s `emptyInput` guard is therefore a
  defensive check with no live call path today (verified by reading
  both call sites), not a bug; `ErrorView` still renders its §10
  message correctly for the case it were ever reached from a future
  caller.
- **Stage 5 — added a "Monthly budget" field to Settings → Provider.**
  HANDOFF.md §9.3 already specifies this field ("Provider (API key
  secure field with Test key, model picker, economy toggle, monthly
  budget)"), but no earlier stage wired it — `PreferenceStoring.monthlyBudgetUSD`
  existed with no UI, so it could never be changed from its $5 default
  except by writing an `NSDecimalNumber` directly into `UserDefaults`
  from code. This stage's budget-warning banner and menu-bar
  indication are untestable without a way to lower the threshold, so a
  `TextField` bound through a new `SettingsViewModel.monthlyBudgetUSD`
  was added — a functional gap-fill already promised by the handoff,
  not new scope.
- **Stage 5 — the menu bar's budget indication refreshes on demand,
  not on a live timer.** `MenuBarViewModel.refresh()` re-reads
  `UsageMetering.snapshot()` when the label icon first mounts (app
  launch) and whenever the dropdown content is opened, via SwiftUI's
  own `.task` view lifecycle — not a recurring poll loop. This avoids
  adding a new always-on background `Task` for a soft, non-blocking
  indicator; the in-panel budget banner (which does update live, right
  after every successful request) is the authoritative, real-time
  surface for this warning, and Stage 6 owns the full "menu bar
  dropdown with usage" this can grow into if a live-updating icon is
  wanted later.
- **Stage 6 — the ⌘C synthesis spike was not shipped; auto-capture stays
  out.** `CGPreflightPostEventAccess()` returns `true` when called from a
  binary launched by Terminal, but that is inherited TCC attribution from
  the parent process, not evidence about `Verba.app`. The app bundle is
  ad-hoc signed (`CODE_SIGN_IDENTITY = "-"`, no paid Apple Developer
  account), and on macOS 26 WindowServer's `CGXSenderCanSynthesizeEvents()`
  gate filters synthesized events from binaries without a real signing
  identity. Rather than ship a toggle that silently does nothing, no
  synthesis code exists in the tree. Revisit only with a Developer ID
  certificate; the clipboard path (⌘C by hand) remains the primary capture.
- **The panel's theme is user-selectable (Auto/Light/Dark), which supersedes
  the "always light" rule below.** The ban on semantic colors and materials
  still stands and is the reason this works: because every `PanelTheme` colour
  is an explicit value, adding a second explicit value per token turns each one
  into a two-branch dynamic `NSColor` that AppKit resolves against the window's
  `NSAppearance`. `FloatingPanel.apply(_:)` sets that appearance from
  `PreferenceStoring.panelAppearance`. No call site changed, no SwiftUI state
  drives it, and `.regularMaterial`/`.primary`/`.secondary` remain banned —
  a dynamic colour with two hand-picked values is not vibrancy.
  `PanelTheme` importing `AppKit` for `NSColor` is a knowing exception to the
  `architecture.md` import table; it is rendering vocabulary, not a `Data` type,
  and `Scripts/check-layers.sh` does not flag it.
- **Visual pass — the panel is always light, and never uses semantic
  colors or materials.** The panel shipped rendering in the system dark
  appearance at 10–13pt with `.regularMaterial` behind it, which the user
  reported as unreadably low contrast. `FloatingPanel` now forces
  `NSAppearance(named: .aqua)` and every panel color is an explicit value
  in `PanelTheme` — `Color.primary`/`.secondary` and `.regularMaterial`
  are banned inside the panel because vibrancy blends foreground text
  toward the background and inverts the intended hierarchy (verified: a
  `.secondary` label rendered darker than a `.primary` one over material).
  Settings, onboarding, and the menu bar are ordinary windows and still
  follow the system appearance.
- **Visual pass — result text was truncated to one line because the
  panel measured its height before the width was known.**
  `contentHeight()` reads `contentView.fittingSize`, whose layout pass
  proposes an unconstrained width, so a `Text` reported its single-line
  ideal height and was then clipped to it. `PanelRootView` now carries
  `.frame(width: PanelTheme.width)`, so measurement wraps exactly as the
  final render does; multi-line `Text`s also carry
  `.fixedSize(horizontal: false, vertical: true)`.
- **Constraint #4 — `DEBUG` builds store the API key in `UserDefaults`,
  not Keychain.** Every debug run re-signs the app ad-hoc with a fresh
  identity, so macOS treats it as a new requester and re-prompts for
  Keychain access on every launch. `UserDefaultsSecretStore` (`Data/Keychain`)
  is a second `SecretStoring` conformance, plaintext, no `kSecAttrAccessible`
  protection; `AppContainer.init()` picks it under `#if DEBUG` only —
  `KeychainSecretStore` is still the sole path in Release. Never let this
  branch widen to cover anything other than local dev convenience.
- **Stage 6 — no raster app icon.** The build has no icon generation
  tooling and a hand-rolled placeholder would look worse than the system
  default. `MenuBarExtra` uses the `text.badge.checkmark` SF Symbol, which
  renders correctly as a template image at menu bar sizes. Add a real
  `AppIcon` asset set when there is artwork.
- **The panel is draggable and remembers its position, overriding the
  `isMovableByWindowBackground = false` invariant.** `.claude/rules/ui-panel.md`
  pinned the panel to "centered on the mouse screen, 28% from the top" and
  HANDOFF.md §15 listed that under "do not re-litigate". The user asked for a
  movable panel that reopens where it was left, which is a direct product
  decision that outranks the earlier default. `windowDidMove` persists the
  origin, but only when `isPositioningProgrammatically` is false — `reveal()`
  and `resizeToFitContent()` both move the window themselves, and without that
  flag the height-fitting pass would silently rewrite the user's saved origin on
  every state change. Restored frames are clamped to `visibleFrame` (the
  original code used `frame`, ignoring menu bar and Dock), so an unplugged
  display or a tall result cannot strand the panel off-screen.
- **`ActionParameters.extraInstruction` is interpolated into the *system*
  prompt, against `.claude/rules/llm-layer.md`'s "user text goes in
  `userContent` only".** That rule exists to stop the text being edited from
  being read as instructions. An extra instruction is the opposite case: put in
  `userContent` next to the subject text, the model rewrites the instruction
  instead of obeying it. It goes into the system prompt inside a fenced
  `USER INSTRUCTION` block that explicitly outranks the template body but not
  the JSON contract. The rule has been amended to scope it to the subject text.
- **"More creative" is not a temperature.** The Responses API rejects
  `temperature` for GPT-5-family reasoning models, so `Creativity` drives
  `reasoning.effort` and `text.verbosity` (previously a hardcoded `"low"` in
  `OpenAIDTO`) plus an appended prompt clause. `balanced` reproduces the
  pre-Creativity request byte for byte, so existing behaviour is unchanged
  unless the user opts out of it. `LLMRequest.minimalReasoningEffort: Bool` was
  replaced by explicit `reasoningEffort`/`verbosity` strings rather than growing
  a second boolean.
- **`gpt-5-mini` was dropped from `ModelCatalog` in favour of `gpt-5.6-luna`.**
  Luna is both newer and cheaper ($0.20/$1.20 per 1M versus $0.25/$2.00), so
  there is no tier where mini still wins. `gpt-5.6-terra` is listed as a
  non-default standard-tier option. No migration code is needed:
  `UserDefaultsPreferenceStore.modelID` already falls back to
  `ModelCatalog.defaultModel(...)` when the stored id is not a catalog entry.
- **`reasoning.effort` has no value that every model accepts.** Shipping
  `"minimal"` for the whole catalog produced a hard HTTP 400 on every
  standard-tier request (`gpt-5.6-luna`: *"'minimal' is not supported with the
  'gpt-5.6-luna' model. Supported values are: 'none', 'low', 'medium', 'high',
  'xhigh', and 'max'"*), while economy-tier `gpt-5-nano` kept working because
  it accepts `"minimal"` and rejects `"none"`. `ModelCatalogEntry` now carries
  `lowestReasoningEffort` per model. Verified against the live Responses API,
  not inferred. Any new catalog entry must have this value confirmed by an
  actual request before it ships.
- **HTTP 400/404/422 map to `.malformedRequest(status:)`, not `.unknown`.** The
  effort bug above was invisible for a full debugging session because
  `OpenAIErrorMapper` funnelled 400 into `default: .unknown`, so a
  parameter the API explicitly named in its response body surfaced to the user
  as "something went wrong". `malformedRequest` is never retried and offers
  "Open Settings" as its recovery.
- **`TextLanguage` doubles as detected-source and chosen-target, and now has
  five cases.** Widening it to `english/russian/ukrainian/spanish/other` was
  cheaper than introducing a parallel "target language" enum, because
  `PromptBuilder`, `ExplainFixesPrompt`, and `SourceText` all already speak
  `TextLanguage`. `selectable` deliberately excludes `.other` — it is a
  detection outcome, never something a user picks. The four
  `language == .russian ? titleRussian : titleEnglish` sites are ternaries, so
  Ukrainian and Spanish fall through to the English titles rather than needing
  new translations.
- **`PanelWindowController` tracks `PanelViewModel.trackLayoutInputs()`, not
  `state`.** `withObservationTracking` only re-fires for properties actually
  read inside the closure. Every result-screen control added here lives in a
  sibling observable property, not in a `PanelState` payload, so reading only
  `state` would have left the window at its old height whenever a chip, the
  extra-instruction field, or the diff toggle changed the content. The list of
  height-affecting properties now lives in one place, in the view model.
- **`manualEntry`'s plain Return is self-managed, not native `TextField`
  passthrough.** `TextField(_:text:axis: .vertical)` is documented to
  insert a newline on Return rather than submitting, but in this app's
  manually-hosted `NSHostingView`-inside-a-borderless-`NSPanel` setup
  (see the Stage 4 `openSettings` deviation above for the same root
  cause), a plain Return pressed while the field is focused never
  reached that native behavior — confirmed empirically, not just
  theorized. `PanelViewModel.handleManualEntry` now intercepts plain
  Return itself and appends `"\n"` to `manualDraft` via
  `updateManualDraft(_:)` directly, rather than returning `.ignored` and
  trusting the field to handle it. Known limitation: this always
  appends at the end of the string, not at the cursor position, since a
  plain `Binding<String>` exposes no cursor-position API. Do not revert
  this to relying on native passthrough without re-verifying in the
  running app first.
