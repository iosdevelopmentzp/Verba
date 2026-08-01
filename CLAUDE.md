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
