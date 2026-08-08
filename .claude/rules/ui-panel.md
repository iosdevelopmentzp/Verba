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
isMovableByWindowBackground = true
override var canBecomeKey: Bool { true }
override var canBecomeMain: Bool { false }
```

- Show with `orderFrontRegardless()` then `makeKey()`. **Never** call
  `NSApp.activate(...)` — the panel must not steal focus from the
  source app (Slack).
- Position: the panel is draggable by its background and remembers where the
  user left it (`PreferenceStoring.panelOriginX`/`panelOriginY`, written from
  `PanelWindowController.windowDidMove`). With no saved origin it falls back to
  horizontally centered on the screen containing the mouse, vertically ~28%
  from the top. Every programmatic `setFrame` goes through
  `setFrameProgrammatically`, which raises a flag so `windowDidMove` cannot
  overwrite the saved origin with a move the user did not make. A restored
  frame is clamped inside `visibleFrame`, so an unplugged monitor or a grown
  result cannot leave the panel off-screen. Settings has "Reset panel
  position". Width `PanelTheme.width`, height fits
  content up to the mouse screen's available height (28% top inset,
  24pt bottom margin) via `PanelViewModel.maxContentHeight`, beyond
  which `PanelRootView`'s root `ScrollView` takes over — content never
  pushes the window off-screen. 0.12s fade (skip the animation when
  Reduce Motion is on).
- Every metric, font, and color comes from `PanelTheme`. Colors are still
  explicit values, never `.primary` / `.secondary` / `.regularMaterial`, which
  resolve against the system appearance and wash out under vibrancy — but each
  one is now a two-branch dynamic `NSColor`, so the panel follows
  `PreferenceStoring.panelAppearance` (Auto / Light / Dark, chosen from the
  sidebar). `FloatingPanel.apply(_:)` sets the window's `NSAppearance` and
  AppKit resolves every colour from there; no SwiftUI state is involved and no
  call site changed. `.aqua` remains the default.
- **The interface is always English.** `TextAction` carries a single
  `titleEnglish`; the old `titleRussian` and the four
  `language == .russian ? … : …` switches are gone. `TextLanguage.displayName`
  is a UI string and reads in English too — the detected language of the user's
  text must never change the language of Verba's own chrome.
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
  source vs. *whichever suggestion is currently highlighted*, rendered
  directly under that suggestion — inside the primary card's block
  when `primary` is selected, inside that specific alternative's row
  when an alternative is selected — so it moves with the `↑`/`↓`
  highlight instead of sitting in one fixed spot. `ResultView.diffToggle(isHighlighted:)`
  takes a highlight flag because the alternative case renders on top
  of that row's `PanelTheme.selection` background (same reason
  `KeyCapsuleView.isHighlighted` exists) while the primary case sits
  on the plain panel background below `primaryCard`'s own card.
  `TextDiff.wordDiff` renders removed words struck through in
  `PanelTheme.diffRemoved`, added words bold in `PanelTheme.diffAdded`.
  Hidden for `translate` (`supportsDiff: false` — source and result
  are different languages, a word diff is meaningless there). The
  shown/hidden choice persists across restarts via
  `PreferenceStoring.isDiffVisible` (default `true`) — `PanelViewModel`
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
| `1`–`7` | picking, result, failed | run that action directly; `3` / `5` (change tone / humanize) always open the parameter picker instead, preselected to the last tone/level chosen |
| `↑` `↓` | result | move the highlight across `primary`, its alternatives, and the extra-instruction row |
| `⏎` | result | copy the highlighted option, show HUD — or open the extra-instruction editor when that row is highlighted |
| `⌘⏎` | result | copy the highlighted option, then go back to `picking` with *that highlighted option* (not the original capture) as the new source, origin `.chained` |
| `⌘1` `⌘2` `⌘3` | result | copy alternative 1/2/3 directly, show HUD |
| `⇥` | manualEntry | accept typed/edited text, go to `picking` |
| `⏎` | manualEntry | insert a newline (self-managed via `updateManualDraft`, not native `TextField` passthrough) |
| `⌘R` | result, failed | re-run the same action, bypassing the cache |
| `⌘←` | parameterPicking, result, failed | back to `picking` with the same source, reselecting the action just being configured/run |
| `⌘E` | result | open the Explain overlay (fixGrammar only, hidden/no-op elsewhere) |
| `⌘D` | result | toggle the word-level diff for the highlighted suggestion (actions with `supportsDiff` only), persisted via `PreferenceStoring.isDiffVisible` |
| `⇥` | result, failed | edit the source, then re-run the same action on it |
| `⌘T` `⌘⇧T` | result (translate) | cycle target / source language |
| `⌘J` | result | cycle creativity (precise / balanced / creative) |
| `⌘I` | result | open the extra-instruction editor |
| `⌘P` | result | open the prompt viewer/editor overlay |
| `⌘C` | anywhere a source exists | copy the original source text, show HUD (handled via `FloatingPanel.copy(_:)`, not `onKeyPress`) |
| `⎋` | anywhere | cancel and close |

## Options sidebar

`PanelSidebarView` is a permanent right-hand rail on `PanelRootView`, present in
every state. Collapsed it is a `PanelTheme.sidebarRailWidth` strip with a
vertical "OPTIONS" label; tapping anywhere on it expands to
`PanelTheme.sidebarWidth`. The choice persists via
`PreferenceStoring.isSidebarExpanded`. It holds Style (creativity), the
model tier, the diff toggle and the theme — groups appear only when they apply
to the current action, and the column scrolls so a new group can never overflow
it.

The translate language pair deliberately does **not** live here.
`TranslationBarView` sits directly above the suggestions on the result screen
whenever the action is `translate`: it is contextual to one action, it is the
thing the user is looking at when they want to change it, and it states the
resolved pair in words. A generic options drawer is the wrong home for a control
that only ever applies to one sixth of the actions. Changing any of them re-runs the
current action.

Because the sidebar changes the window's **width**, `PanelWindowController`
derives its width from `PanelTheme.panelWidth(isSidebarExpanded:)` rather than a
constant, and `resizeToFitContent()` compares width as well as height.

## Chips and key capsules must never wrap

`ChipView` and `KeyCapsuleView` carry `lineLimit(1)` + `fixedSize()`. Without
them a crowded `HStack` compresses its children instead of overflowing, and a
short label breaks mid-word — "Auto" rendered as "Aut/o" inside a circle, and
"⌘⇧T" split across two lines, once the translate bar put nine chips, two
capsules and a summary on one 620pt row.

`fixedSize()` is the guard, not the fix: a row still has to actually fit.
`TranslationBarView` therefore puts From and Into on separate rows with the
resolved direction on a third, rather than competing for one line.

## Result-screen controls

`ResultControlsView` owns what sits below `ResultView`: the extra-instruction
row and the "view and edit prompt" control. Everything else moved to the
sidebar. The extra instruction is stored **per action**
(`PanelViewModel.extraInstructions`, keyed by `TextAction.Kind`), so translate
and rephrase keep separate one-off instructions; all of them clear when the
panel closes.

The extra instruction is a **selectable row, not an inline text field** — it is
the last index in the result screen's `↑`/`↓` ring
(`PanelViewModel.instructionRowIndex(for:)`), and `⏎` or a click on it opens
`InstructionOverlayView`. Editing in an overlay rather than inline is what keeps
the result screen's keyboard map alive: a focused inline field swallows `↑`/`↓`,
`⏎` and the bare digits, and there was no affordance telling the user which mode
they were in. The overlay owns focus for as long as it is up, `⏎` applies and
closes, `Esc` cancels — and `PanelViewModel.handle(_:)` swallows every other key
while it is open, the same contract as the explanation and prompt overlays. It takes the view model
directly (the `ManualEntryView` precedent) so `ResultView`'s parameter list
does not keep growing. Each control is both clickable and keyboard-reachable.

`ResultView` renders the primary and its alternatives as **one uniform list**
of suggestion rows, not a hero card plus a separate section — they are the same
kind of thing and the keyboard already treats them as one wrapping selection.

Selection is a soft accent tint plus a 3pt accent bar on the leading edge, never
a solid accent fill — applied through the shared `.selectableRow(isSelected:)`
modifier, used by the action picker, the parameter picker, the sidebar, the
suggestion rows and the extra-instruction row alike. A filled row forces white
foreground text, which makes the word-level diff rendered inside it unreadable
and inverts the intended hierarchy — the same failure the visual pass hit with
`.regularMaterial`.

Nothing in the panel may paint white-on-accent any more. `KeyCapsuleView`'s
highlighted style is accent text on `PanelTheme.selectionKeyCap`; when it was
white-on-`white.opacity(0.22)` it was designed for a solid accent row and
vanished the moment the row went light.

Clicking a suggestion that is **not** highlighted moves the highlight to it;
clicking the already-highlighted one copies it. Each row states which it will
do. That is also the only way a mouse can reach an alternative's diff, which
renders under the highlighted item only.

`PanelWindowController.observeContentChanges()` tracks
`PanelViewModel.trackLayoutInputs()`, not `state` alone — every observable
property that can change the panel's height must be read there or the window
will not resize when it changes.

`PromptOverlayView` follows the `ExplanationOverlayView` contract (root
`.overlay`, `Esc` dismisses the overlay before the panel, all other keys
swallowed) but scrolls, because a system prompt does not fit. Only the
action-specific instruction is editable — `Templates.preamble` carries the JSON
contract the strict schema depends on and is shown read-only.
