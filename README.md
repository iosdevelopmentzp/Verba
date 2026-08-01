# Verba

A macOS menu-bar utility that improves short text via an LLM API before you
send it. Copy a Slack message, press a hotkey, pick an action (fix grammar,
rephrase, change tone, translate RU⇄EN, humanize), and paste the result back.
Keyboard-only, no Accessibility API, no event synthesis.

## Requirements

- macOS 26
- Xcode 26

## Getting started

```
git clone <repo-url> Verba
open Verba/Verba.xcodeproj
```

Build and run the `Verba` scheme. The app has no Dock icon or ⌘-Tab entry —
look for the menu bar icon.

### Stable local signing (recommended)

The project ships configured for "Sign to Run Locally", which re-derives a
new identity on every rebuild. That churn resets the app's Keychain ACL and
its TCC (privacy permission) grants each time, so the clipboard-access
prompt and any stored API key can reappear after a clean rebuild.

To avoid that, create a self-signed code-signing identity once:

1. Open **Keychain Access** → menu **Keychain Access → Certificate
   Assistant → Create a Certificate…**
2. Name it (e.g. `Verba Local`), set **Identity Type** to
   **Self Signed Root**, **Certificate Type** to **Code Signing**, and
   create it.
3. In Xcode, set the target's **Signing Certificate** to this identity
   instead of "Sign to Run Locally".

Rebuilds now keep a stable identity, so Keychain and TCC state persist
across builds.

### OpenAI API key

Verba calls the OpenAI API. Create a key at
[platform.openai.com/api-keys](https://platform.openai.com/api-keys) and
enter it in Verba's Settings → Provider tab. The key is stored in the
Keychain only — never in `UserDefaults`, a plist, or the repository.

### Default hotkey

`⌃⌥Space` toggles the panel. Change it any time from Settings → General;
the new shortcut takes effect immediately.

### Clipboard permission

The first time Verba reads the clipboard, macOS shows a one-time
permission alert. Choose **Always Allow** — declining or choosing "Allow
Once" means Verba has to ask again on every capture.

### Services menu (optional)

Verba also registers a "Improve with Verba" entry in the system Services
menu, so you can select text in any app and invoke Verba without copying
first. Assign it a shortcut in **System Settings → Keyboard → Keyboard
Shortcuts → Services**. This path is unreliable in Electron apps such as
Slack — treat it as a secondary convenience, not the main workflow.

### Verification

This project has **no tests** — no unit tests, no UI tests, no test
target. Everything is verified manually against the stage criteria in
`HANDOFF.md` §11 and §14. Because there is no automated safety net,
changes must be precise and side-effect-free.

```
xcodebuild -project Verba.xcodeproj -scheme Verba -configuration Debug build
```

## Architecture

```
App  ──►  Presentation  ──►  Domain  ◄──  Data
```

`Domain` knows nobody. `Data` and `Presentation` know only `Domain`. `App`
knows everybody. See `CLAUDE.md` and `.claude/rules/architecture.md` for
the full dependency rule and enforcement details.
