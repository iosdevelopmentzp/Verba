# Stage 5 — manual verification checklist

There are no automated tests in this project. This is the safety net a
human runs by hand after any change touching error handling, retries,
cost, or the cache. It covers the twelve `AppError` rows from
HANDOFF.md §10 and the Stage 5 features from §14.

## Setup

- Build and run: `xcodebuild -project Verba.xcodeproj -scheme Verba -configuration Debug build`,
  then run the `Verba` scheme from Xcode (no Dock icon — look for the
  menu bar item).
- Watch logs in a second terminal for every check below:
  `log stream --predicate 'subsystem == "com.dmytrovorko.verba"'`
- Reset preferences between scenarios if needed: `defaults delete com.dmytrovorko.verba`
- Delete the stored key: Keychain Access → search `com.dmytrovorko.verba.apikey` → delete.
- A real OpenAI API key is required for rows 4–9, 11 (run-phase), and
  features 17–19. Enter it in Settings → Provider.

---

## Part A — the twelve `AppError` rows

| # | Case | Steps to trigger | Expected on-screen result |
|---|---|---|---|
| 1 | `missingAPIKey` | Settings → Provider → clear the API key field, select all, delete, press Return (commits the empty key, which deletes the Keychain item). Close Settings. Press the hotkey, capture any text, press `1`. | Panel flashes Running then shows **"Add your OpenAI API key to get started."** with an **Open Settings** button. Clicking it opens the Settings window. |
| 2 | `emptyInput` | **Not reachable through the panel UI.** `CaptureTextUseCase.make` (used by both pasteboard capture and manual-entry accept) already rejects trimmed-empty content before a `SourceText` can exist, so `ProcessTextUseCase` never receives empty text from the shipped UI — this is by design per this stage's instruction to keep genuinely-empty input going to manual entry, not to an error state. Verified by reading `ProcessTextUseCase.swift` (the `emptyInput` guard) and `ErrorView.swift` (the message/no-button rendering) directly; there is no key sequence that reaches it today. | N/A — code-reviewed only. |
| 3 | `inputTooLong` | Put a >8000-character string on the clipboard, e.g. `python3 -c "print('a ' * 4500)" \| pbcopy`. Press the hotkey. Preview shows a red "exceeds 8,000 character limit" label. Press `1`. | No `llm`-category log line appears (confirm in `log stream`). Panel shows **"Text too long — 9,000 characters, limit is 8,000."** (exact counts vary), no recovery button. |
| 4 | `offline` | With a valid key set, turn on Airplane Mode (or disable Wi-Fi). Capture text, run any action. | **"No internet connection."** with a **Retry** button. Reconnect, press Retry (or `⌘R`) — it reuses the same captured text, no reprompt. |
| 5 | `timedOut` | Hard to trigger organically. Temporarily set `OpenAIClient.requestTimeout` to `0.001` in code, rebuild, run an action, then revert and rebuild. | **"The request timed out."** with a **Retry** button. |
| 6 | `rateLimited` | Hard to trigger on demand without abusing a real account. Point `OpenAIClient.endpoint` at a mock/local server returning HTTP 429 with a `Retry-After` header, rebuild, run an action, then revert. | One silent automatic retry happens first (honoring `Retry-After`); if it also comes back 429, the panel shows **"Still rate limited."** with a **Retry** button. |
| 7 | `unauthorized` | Settings → Provider → enter an obviously invalid key (e.g. `sk-invalid`) → Test key, or just run an action with it set. | **"The API key was rejected."** with an **Open Settings** button. `ProviderSettingsSection`'s inline "Test key" status shows the same failure independently. |
| 8 | `providerUnavailable` | Point `OpenAIClient.endpoint` at a URL that returns 5xx (e.g. `https://httpstat.us/500`), rebuild, run an action, then revert. | **"OpenAI is having trouble (500)."** (status reflects whatever code the server returned) with a **Retry** button. |
| 9 | `malformedResponse` | Point `OpenAIClient.endpoint` at a URL returning HTTP 200 with a non-JSON or schema-mismatched body (e.g. `https://httpstat.us/200`), rebuild, run an action, then revert. | **"Couldn't read the model's response."** with a **Retry** button. `log stream` shows two `llm` request attempts for the one user action (the automatic stricter-instruction re-ask). |
| 10 | `pasteboardAccessDenied` | Run the app once normally so macOS shows its one-time pasteboard-access prompt; accept it. Then System Settings → Privacy & Security → **Pasteboard** (may be listed as "Paste from Other Apps") → find Verba → set to **Deny**. Press the hotkey to force a fresh capture. | Panel opens straight to **"Verba needs clipboard access. Allow it in System Settings → Privacy & Security → Pasteboard."** with an **Open System Settings** button. Clicking it opens that exact pane (`x-apple.systempreferences:com.apple.preference.security?Privacy_Pasteboard`). Set the permission back to Allow/Ask, reopen the panel — capture works again. |
| 11 | `cancelled` | Capture-phase (no key needed): press the hotkey then Esc as fast as possible before the picker appears. Run-phase (needs a key + a real in-flight request): capture text, press a number key, then press Esc while "⎋ to cancel" is visible, before the result returns. | Panel simply closes — **no error UI, no HUD**. `log stream` shows no new `usage recorded` or `cache` entry for that attempt (nothing was billed or cached). |
| 12 | `unknown` | Hard to force deliberately (it's the catch-all). Options: point the endpoint at a URL returning an unmapped status (e.g. 304), or temporarily corrupt the raw bytes behind the Keychain item so UTF-8 decoding fails in `KeychainSecretStore.apiKey`. Revert after. | **"Something went wrong."** with a **Retry** button. |

---

## Part B — Stage 5 features

| # | Feature | Steps to trigger | Expected on-screen result |
|---|---|---|---|
| 13 | Soft-warn cost hint | Put a 3000-character string (between 2000 and 8000) on the clipboard, press the hotkey. | `SourcePreviewView` shows the character count plus an orange **"long input, higher cost"** label; no red "exceeds" label. |
| 14 | Hard-limit preview warning | Put a 9000-character string on the clipboard, press the hotkey (do not run an action yet). | `SourcePreviewView` shows a red **"exceeds 8,000 character limit"** label instead of the cost hint, before any action is picked. |
| 15 | Budget banner (panel) | Settings → Provider → set **Monthly budget** to `$0.01`. Run one real action (any successful request costs more than one cent's worth of a penny in practice, or run two or three to accumulate past the threshold). | A small orange banner — **"Monthly budget exceeded — $X.XX of $0.01"** — appears pinned to the top of the panel in every subsequent state (picking, running, result, failed). Actions still run normally; nothing is blocked. |
| 16 | Budget indication (menu bar) | After triggering #15, click the menu bar item. | The menu bar icon itself switches from the checkmark glyph to a triangle-exclamation glyph, and the dropdown shows a **"Monthly budget exceeded"** row above Settings/About/Quit. Reset **Monthly budget** back to `$5` afterward (or `defaults delete com.dmytrovorko.verba`) to clear the warning. |
| 17 | Economy mode forces the economy tier | Settings → Provider → turn **Economy mode** ON. Run **Rephrase** (`2`), whose default tier is `standard`. | The result header shows an **"economy"** badge, not "standard" — confirming the toggle overrode the action's default tier. Turn Economy mode OFF, press `⌘R` — the badge switches to **"standard"**. |
| 18 | Cache-hit indicator, no network call | Run any action once to completion. Reopen the panel with the same clipboard content unchanged (shows the "reused" marker) and run the exact same action again. | Second run shows a **"cached"** badge and returns effectively instantly. `log stream` shows no new `request succeeded` / `request failed` `llm`-category line for the second run — confirming no network call was made. |
| 19 | Retry policy correctness | Combine with rows 6 and 8 above (`rateLimited`, `providerUnavailable`): watch `log stream` during each. For rows 4, 7, 3, 11: confirm no second attempt appears. | Exactly one retry attempt appears in the log for `rateLimited`/`providerUnavailable` scenarios (two `llm` log lines total: the failure, then the retry's outcome), honoring any `Retry-After` delay before the retry fires. For `offline`, `unauthorized`, `inputTooLong`, and `cancelled`, only one attempt (or zero, for `inputTooLong`) ever appears — no retry. |
| 20 | Log audit | Run a full working session (several captures, several actions, a bad key, airplane mode, a long paste) with `log stream --predicate 'subsystem == "com.dmytrovorko.verba"'` capturing to a file. | Search the captured output for any fragment of the text you typed or copied — there should be none. Every `capture`/`llm`/`usage`/`keychain` line should contain only counts, ids, statuses, and enum case names, never prose. |

---

## Notes on environment limitations

Rows 5, 6, 8, 9, and 12 require either a live OpenAI account being
throttled/erroring, or a temporary code change to point `OpenAIClient`
at a stand-in endpoint. Do not fake a key or synthesize events to force
these — use the temporary-endpoint technique described above, confirm
the UI, then revert the temporary change before committing anything.
