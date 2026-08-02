# UI panel

## `FloatingPanel` invariants

An `NSPanel` subclass:

```swift
styleMask = [.nonactivatingPanel, .borderless, .fullSizeContentView]
level = .floating
collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
isFloatingPanel = true
hidesOnDeactivate = false
becomesKeyOnlyIfNeeded = false
isMovableByWindowBackground = false
override var canBecomeKey: Bool { true }
override var canBecomeMain: Bool { false }
```

- Show with `orderFrontRegardless()` then `makeKey()`. **Never** call
  `NSApp.activate(...)` — the panel must not steal focus from the
  source app (Slack).
- Position: horizontally centered on the screen containing the mouse,
  vertically ~28% from the top. Width `PanelTheme.width`, height fits
  content up to the mouse screen's available height (28% top inset,
  24pt bottom margin) via `PanelViewModel.maxContentHeight`, beyond
  which `PanelRootView`'s root `ScrollView` takes over — content never
  pushes the window off-screen. 0.12s fade (skip the animation when
  Reduce Motion is on).
- Every metric, font, and color comes from `PanelTheme`. The panel is
  always light: colors are explicit values, never `.primary` /
  `.secondary` / `.regularMaterial`, which resolve against the system
  appearance and wash out under vibrancy.
- Dismiss on: Esc or a second hotkey press. Losing key status
  (`resignKey`) and a completed copy do **not** dismiss the panel — it
  must stay up until the user explicitly closes it. Dismissal cancels
  any in-flight `Task` (see `concurrency.md`).
- Re-showing reuses the same panel instance — no window leaks. Verify
  by toggling 20 times and checking `NSApp.windows.count` stays flat.
- `SourcePreviewView`'s source-text line is tap-to-expand/collapse
  (2 lines collapsed, unbounded expanded) — local `@State`, no
  view-model plumbing.
- Fix grammar's result screen has an "Explain" button
  (`TextAction.supportsExplanation`, only `fixGrammar` for now, hidden
  when `result.notes` is empty) that fires a second, uncached,
  `.economy`-tier request via `ExplainFixesUseCase` and shows the
  answer in `ExplanationOverlayView`, an `.overlay` on `PanelRootView`
  driven by `PanelViewModel.explanation` — same "state living outside
  `PanelState`" pattern as `isHUDVisible`/`usageSnapshot`. While
  `explanation != nil`, `Esc` dismisses the overlay instead of closing
  the panel, and every other key is swallowed (`.handled`, no-op) so
  input can't leak through to the result screen underneath.
- Actions with `supportsDiff` show a word-level diff (`⌘D` toggle) of
  source vs. *whichever suggestion is currently highlighted* on the
  result screen — `ResultView.selectedText` tracks `selectedIndex`
  across `primary` and the alternatives, so moving the `↑`/`↓`
  highlight recomputes the diff against that option, not always
  `primary`. `TextDiff.wordDiff` renders removed words struck through
  in `PanelTheme.diffRemoved`, added words bold in
  `PanelTheme.diffAdded`. Hidden for `translate` (`supportsDiff: false`
  — source and result are different languages, a word diff is
  meaningless there). The shown/hidden choice persists across restarts
  via `PreferenceStoring.isDiffVisible` (default `true`) — `PanelViewModel`
  seeds `isDiffShown` from it at init and writes back on every
  `toggleDiff()`, the same "remember the last choice" pattern as
  `lastTone`/`lastLevel`.
- `SourcePreviewView` carries a "copy" button (⌘C hint + tap) next to
  the character count, wired to `PanelViewModel.copyOriginal()` — a
  single control shared by every state that has a source (`picking`,
  `parameterPicking`, `running`, `result`, `failed`), rather than one
  copied into each screen's own footer.
- `⌘C` copies the original captured/edited source text untouched.
  **Must be handled as an `NSResponder` action override, not a
  SwiftUI `onKeyPress` case:** AppKit resolves Command-key events
  against the app's default Edit-menu key equivalents (Copy/Cut/Paste/
  etc.) *before* the key ever reaches a window's `onKeyPress` handler,
  so an `isC`-style branch in `PanelViewModel.handle(_:)` is silently
  unreachable — the keystroke is consumed by the menu, finds no
  responder implementing `copy(_:)`, and NSBeeps. `FloatingPanel`
  declares `@objc func copy(_ sender: Any?)` (no `override` — this
  selector isn't declared on `NSResponder` to override, it's a plain
  Objective-C action the responder chain looks up by name) forwarding
  to `PanelViewModel.copyOriginal()`. Every successful copy (`⏎`,
  `⌘1`-`⌘3`, `⌘C`) plays a short system sound (`NSSound(named:
  "Tink")`) via `PanelViewModel.onCopyCompleted`, alongside the
  existing "Copied" HUD.
- `changeTone`/`humanize`'s parameter picker preselects whichever tone/
  level was chosen last time (`PreferenceStoring.lastTone`/`lastLevel`,
  persisted across restarts), falling back to `.formal`/
  `preferences.defaultLevel` the first time there is no prior choice.

## Keyboard map

| Key | Where | Effect |
|---|---|---|
| `⌃⌥Space` | global | toggle panel |
| `↑` `↓` | picking | move selection |
| `⏎` | picking | run the selected action |
| `⇥` | picking | edit the captured text — goes to `manualEntry` prefilled with it, origin becomes `.manual` on accept |
| `1`–`6` | picking, result, failed | run that action directly; `3` / `5` (change tone / humanize) always open the parameter picker instead, preselected to the last tone/level chosen |
| `↑` `↓` | result | move the highlight across `primary` and its alternatives |
| `⏎` | result | copy the highlighted option, show HUD |
| `⇧⏎` | result | copy the highlighted option, then go back to `picking` with *that highlighted option* (not the original capture) as the new source, origin `.chained` |
| `⌘1` `⌘2` `⌘3` | result | copy alternative 1/2/3 directly, show HUD |
| `⇥` | manualEntry | accept typed/edited text, go to `picking` |
| `⏎` | manualEntry | insert a newline (self-managed via `updateManualDraft`, not native `TextField` passthrough) |
| `⌘R` | result, failed | re-run the same action, bypassing the cache |
| `⌘←` | parameterPicking, result, failed | back to `picking` with the same source, reselecting the action just being configured/run |
| `⌘E` | result | open the Explain overlay (fixGrammar only, hidden/no-op elsewhere) |
| `⌘D` | result | toggle the word-level diff for the highlighted suggestion (actions with `supportsDiff` only), persisted via `PreferenceStoring.isDiffVisible` |
| `⌘C` | anywhere a source exists | copy the original source text, show HUD (handled via `FloatingPanel.copy(_:)`, not `onKeyPress`) |
| `⎋` | anywhere | cancel and close |
