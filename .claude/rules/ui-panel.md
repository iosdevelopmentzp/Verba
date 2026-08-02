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
  content, 0.12s fade (skip the animation when Reduce Motion is on).
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

## Keyboard map

| Key | Where | Effect |
|---|---|---|
| `⌃⌥Space` | global | toggle panel |
| `↑` `↓` | picking | move selection |
| `⏎` | picking | run the selected action |
| `1`–`6` | picking, result, failed | run that action directly |
| `⇧3` / `⇧5` | picking, result | open the tone / level picker |
| `⏎` | result | copy `primary`, show HUD |
| `⌘1` `⌘2` `⌘3` | result | copy alternative 1/2/3, show HUD |
| `⌘⏎` | manualEntry | accept typed text, go to `picking` |
| `⌘R` | result, failed | re-run the same action |
| `⎋` | anywhere | cancel and close |
