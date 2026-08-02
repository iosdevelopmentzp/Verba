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
| `⌘E` | result | open the Explain overlay (fixGrammar only, hidden/no-op elsewhere) |
| `⎋` | anywhere | cancel and close |
