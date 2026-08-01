---
name: run-and-debug
description: Build and run Verba locally, reset local state, and exercise each error path.
---

# Run and debug

## Build and run

Open `Verba.xcodeproj` in Xcode and run the `Verba` scheme, or:

```
xcodebuild -project Verba.xcodeproj -scheme Verba -configuration Debug build
```

The app has no Dock icon; look for the menu bar item.

## Reset local state

- **Onboarding + preferences:**
  `defaults delete com.dmytrovorko.verba`
- **Keychain item:** Keychain Access → search `com.dmytrovorko.verba.apikey`
  → delete the entry (one per provider id).

## Watch logs (never contains user text — verify this)

```
log stream --predicate 'subsystem == "com.dmytrovorko.verba"'
```

## Confirm the panel isn't stealing focus

With Slack (or any app) focused and its text caret active, press the
hotkey. The source app's title bar must stay in its active (non-dimmed)
appearance, and after Esc the caret position/selection in the source
app must be unchanged. If the source app visibly loses key/main status,
the panel is calling `NSApp.activate` somewhere — it must not.

## Check each error path

There are no automated tests in this project — these checks are the
safety net.

- **Bad key:** enter a garbage string in Settings → Provider → expect
  `.unauthorized` → "The API key was rejected."
- **Airplane mode:** enable it, run any action → expect `.offline`.
- **8001-character input:** paste a string just over the hard limit →
  expect `.inputTooLong` with no network call at all (check the log
  stream for the absence of an `llm` category entry).
- **Rate limiting / provider outage:** hard to trigger on demand. Point
  `OpenAIClient`'s base URL at an unreachable host, or temporarily
  return a fixed 429/503 from the mapper's caller, verify the UI, then
  revert.
