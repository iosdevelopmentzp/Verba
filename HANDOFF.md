# Verba — Implementation Handoff Spec

**Audience:** the model implementing this project (Claude Sonnet).
**Status:** approved plan, ready to build. This document is self-contained — everything needed to write the code is here.
**Rule:** implement **stage by stage** in the order given in §14. Do not jump ahead. Do not start a stage before the previous stage's Definition of Done passes.

---

## 1. What Verba is

A macOS menu-bar utility that improves short text via an LLM API. The user is a developer at an English-speaking company, non-native English speaker, who writes a lot of Slack messages in English and also works in Russian. The product value is **speed at the moment before pressing Send**: check grammar, rephrase, change tone, make it sound like a real human at a chosen proficiency level, translate RU⇄EN.

The whole interaction is keyboard-only:

```
⌘C in Slack  →  ⌃⌥Space  →  pick action  →  result  →  ⏎ (copies)  →  ⌘V in Slack
```

### Hard constraints — do not violate

1. **No Accessibility API.** No `AXUIElement`, no `NSEvent.addGlobalMonitorForEvents`, no screen reading. The global hotkey must use Carbon `RegisterEventHotKey` via the `KeyboardShortcuts` package, which needs no TCC permission.
2. **No event synthesis in the MVP.** No `CGEventPost`. The user presses ⌘C themselves. (A gated spike happens in Stage 6 only.)
3. **User text never reaches a log line.** Not in `os.Logger`, not in an error message, not in a crash string, not in a filename.
4. **No API key in the repo, in `UserDefaults`, or in a plist.** Keychain only.
5. **The panel must never activate the app.** If pressing the hotkey makes Slack lose focus, the feature is broken.
6. **No comments that restate the code.** See §12.

---

## 2. Project configuration

| Setting | Value |
|---|---|
| App name | `Verba` |
| Bundle id | `com.dmytrovorko.verba` |
| Deployment target | macOS 26.0 |
| Swift | 6.2, strict concurrency (`SWIFT_STRICT_CONCURRENCY = complete`) |
| Project format | Plain `Verba.xcodeproj`, one app target. **No test target** |
| App Sandbox | **Off** |
| Hardened Runtime | Off |
| Signing | "Sign to Run Locally" initially; README documents upgrading to a self-signed "Local Code Signing" identity from Keychain Access for a stable identity across rebuilds |
| SPM dependencies | **only** `https://github.com/sindresorhus/KeyboardShortcuts` |

`Info.plist` keys required:

- `LSUIElement = true` (no Dock icon, no ⌘-Tab entry)
- `NSServices` — one entry, see §7.3
- `NSHumanReadableCopyright`, standard version keys

Everything else is Foundation / AppKit / SwiftUI / `Security` / `os` / `ServiceManagement` / `NaturalLanguage`.

---

## 3. Architecture

Four layers, implemented as **folders inside one target**, separated by protocols.

```
App  ──►  Presentation  ──►  Domain  ◄──  Data
```

**The dependency rule, verbatim, for every future session:**
`Domain` knows nobody. `Data` and `Presentation` know only `Domain`. `App` knows everybody.

Concretely:

| Layer | May import | Must never import |
|---|---|---|
| `Domain` | `Foundation` | AppKit, SwiftUI, `Security`, `os`, any `Data` type |
| `Data` | `Foundation`, `Security`, `AppKit` (pasteboard only), `os`, `NaturalLanguage`, `Domain` | SwiftUI, any `Presentation` type |
| `Presentation` | `SwiftUI`, `Domain`, `os` | Any `Data` type, `URLSession`, any DTO |
| `App` | everything | — |

`Presentation` receives dependencies as `Domain` protocol existentials. It must be possible to delete the entire `Data` folder, stub the protocols, and still build and run the UI.

### 3.1 Boundary enforcement — `Scripts/check-layers.sh`

Add as a Run Script build phase (before Compile Sources), `set -e`, fails the build on violation.

Checks:
1. Any file under `Verba/Domain/` importing anything other than `Foundation` → fail.
2. Any file under `Verba/Presentation/` containing `URLSession`, `NSPasteboard`, `SecItem`, or importing a `Data`-layer type name → fail.
3. Any file under `Verba/Data/` importing `SwiftUI` → fail.

Keep it to grep + exit codes, ~30 lines. No SwiftLint, no Periphery, no formatter tooling in this project.

---

## 4. File structure

Create exactly this. Do not add folders that are not listed without a reason recorded in `CLAUDE.md`.

```
Verba/
├── .gitignore
├── README.md
├── CLAUDE.md
├── HANDOFF.md                        # this file
├── .claude/
│   ├── rules/
│   │   ├── architecture.md
│   │   ├── swift-style.md
│   │   ├── concurrency.md
│   │   ├── errors-and-logging.md
│   │   ├── llm-layer.md
│   │   └── ui-panel.md
│   └── skills/
│       ├── add-text-action/SKILL.md
│       ├── add-llm-provider/SKILL.md
│       ├── run-and-debug/SKILL.md
│       └── commit/SKILL.md
├── Scripts/check-layers.sh
├── Verba.xcodeproj
├── Verba/
│   ├── App/
│   │   ├── VerbaApp.swift
│   │   ├── AppDelegate.swift
│   │   ├── AppContainer.swift
│   │   ├── HotkeyController.swift
│   │   ├── PanelWindowController.swift
│   │   ├── FloatingPanel.swift
│   │   ├── ServicesProvider.swift
│   │   ├── LoginItemController.swift
│   │   └── AppLogger.swift
│   ├── Presentation/
│   │   ├── Panel/
│   │   │   ├── PanelViewModel.swift
│   │   │   ├── PanelRootView.swift
│   │   │   ├── SourcePreviewView.swift
│   │   │   ├── ActionPickerView.swift
│   │   │   ├── ResultView.swift
│   │   │   ├── RunningView.swift
│   │   │   └── ErrorView.swift
│   │   ├── MenuBar/
│   │   │   ├── MenuBarViewModel.swift
│   │   │   └── MenuBarView.swift
│   │   ├── Settings/
│   │   │   ├── SettingsViewModel.swift
│   │   │   ├── SettingsView.swift
│   │   │   ├── GeneralSettingsSection.swift
│   │   │   └── ProviderSettingsSection.swift
│   │   ├── Onboarding/
│   │   │   ├── OnboardingViewModel.swift
│   │   │   └── OnboardingView.swift
│   │   └── Components/
│   │       ├── HUD.swift
│   │       └── KeyCapsuleView.swift
│   ├── Domain/
│   │   ├── Entities/
│   │   │   ├── SourceText.swift
│   │   │   ├── TextAction.swift
│   │   │   ├── ActionResult.swift
│   │   │   ├── LanguageLevel.swift
│   │   │   ├── Tone.swift
│   │   │   ├── TextLanguage.swift
│   │   │   ├── ModelTier.swift
│   │   │   ├── UsageSnapshot.swift
│   │   │   └── AppError.swift
│   │   ├── Protocols/
│   │   │   ├── TextProcessing.swift
│   │   │   ├── TextCapturing.swift
│   │   │   ├── ResultDelivering.swift
│   │   │   ├── SecretStoring.swift
│   │   │   ├── PreferenceStoring.swift
│   │   │   ├── UsageMetering.swift
│   │   │   ├── ResultCaching.swift
│   │   │   └── LanguageDetecting.swift
│   │   ├── UseCases/
│   │   │   ├── CaptureTextUseCase.swift
│   │   │   ├── ProcessTextUseCase.swift
│   │   │   └── DeliverResultUseCase.swift
│   │   ├── ActionRegistry.swift
│   │   └── InputLimits.swift
│   ├── Data/
│   │   ├── LLM/
│   │   │   ├── LLMClient.swift
│   │   │   ├── LLMRequest.swift
│   │   │   ├── LLMResponse.swift
│   │   │   ├── ProviderID.swift
│   │   │   ├── ProviderRegistry.swift
│   │   │   ├── ModelCatalog.swift
│   │   │   ├── RetryPolicy.swift
│   │   │   ├── LLMTextProcessor.swift
│   │   │   └── OpenAI/
│   │   │       ├── OpenAIClient.swift
│   │   │       ├── OpenAIDTO.swift
│   │   │       └── OpenAIErrorMapper.swift
│   │   ├── Prompt/
│   │   │   ├── PromptTemplate.swift
│   │   │   ├── PromptBuilder.swift
│   │   │   └── Templates.swift
│   │   ├── Keychain/KeychainSecretStore.swift
│   │   ├── Preferences/UserDefaultsPreferenceStore.swift
│   │   ├── Pasteboard/PasteboardTextSource.swift
│   │   ├── Pasteboard/PasteboardResultSink.swift
│   │   ├── Cache/ResultCache.swift
│   │   ├── Usage/UsageMeter.swift
│   │   └── Language/NLLanguageDetector.swift
│   └── Resources/
│       ├── Assets.xcassets
│       └── Info.plist
```

---

## 5. Domain layer — exact definitions

Write these as specified. Everything is `Sendable`.

```swift
enum TextLanguage: String, Sendable, Codable { case english, russian, other }

enum LanguageLevel: String, Sendable, Codable, CaseIterable { case b1, b2, c1 }

enum Tone: String, Sendable, Codable, CaseIterable { case formal, casual, direct, friendly }

enum ModelTier: String, Sendable, Codable { case standard, economy }

struct SourceText: Sendable, Equatable {
    enum Origin: Sendable, Equatable { case pasteboard(isReused: Bool), service, manual }
    let content: String
    let language: TextLanguage
    let origin: Origin
}

struct ActionParameters: Sendable, Equatable {
    var tone: Tone?
    var level: LanguageLevel?
    var targetLanguage: TextLanguage?
}

struct TextAction: Sendable, Identifiable, Equatable {
    enum Kind: String, Sendable { case fixGrammar, rephrase, changeTone, translate, humanize }
    let id: Kind
    let titleEnglish: String
    let titleRussian: String
    let numberKey: Int          // 1...5, drives the number shortcut
    let templateID: String
    let tier: ModelTier
    let needsParameters: Bool   // true for changeTone and humanize
}

struct ActionResult: Sendable, Equatable {
    let primary: String
    let alternatives: [String]  // max 3
    let notes: [String]         // max 4, short, "what changed"
    let cameFromCache: Bool
}

struct UsageSnapshot: Sendable, Equatable {
    let inputTokensToday: Int
    let outputTokensToday: Int
    let costTodayUSD: Decimal
    let costMonthUSD: Decimal
    let budgetMonthUSD: Decimal
}
```

### 5.1 `AppError` — the only error type crossing a boundary

```swift
enum AppError: Error, Equatable, Sendable {
    case missingAPIKey
    case emptyInput
    case inputTooLong(actual: Int, limit: Int)
    case offline
    case timedOut
    case rateLimited(retryAfter: TimeInterval?)
    case unauthorized
    case providerUnavailable(status: Int)
    case malformedResponse
    case pasteboardAccessDenied
    case cancelled
    case unknown
}
```

Every `throw` that can reach `Presentation` must be an `AppError`. `Data` maps `URLError`, HTTP status codes, and decoding failures into it — see §8.4. No `NSError`, no raw `URLError`, no string errors above the `Data` layer.

### 5.2 Protocols

```swift
protocol TextCapturing: Sendable {
    func capture() async throws -> SourceText?   // nil = nothing usable, open manual mode
}

protocol TextProcessing: Sendable {
    func process(_ text: SourceText, action: TextAction,
                 parameters: ActionParameters, tier: ModelTier) async throws -> ActionResult
}

protocol ResultDelivering: Sendable {
    func deliver(_ text: String) async
}

protocol SecretStoring: Sendable {
    func apiKey(for providerID: String) throws -> String?
    func setAPIKey(_ key: String?, for providerID: String) throws
}

protocol PreferenceStoring: AnyObject, Sendable {
    var providerID: String { get set }
    var modelID: String { get set }
    var economyMode: Bool { get set }
    var defaultLevel: LanguageLevel { get set }
    var monthlyBudgetUSD: Decimal { get set }
    var launchAtLogin: Bool { get set }
    var hasCompletedOnboarding: Bool { get set }
}

protocol UsageMetering: Sendable {
    func record(inputTokens: Int, outputTokens: Int, modelID: String) async
    func snapshot() async -> UsageSnapshot
}

protocol ResultCaching: Sendable {
    func value(for key: String) async -> ActionResult?
    func store(_ result: ActionResult, for key: String) async
}

protocol LanguageDetecting: Sendable {
    func detect(_ text: String) -> TextLanguage
}
```

### 5.3 `ProcessTextUseCase` — the orchestration contract

Order of operations, exactly:

1. Trim the input. Empty → `throw AppError.emptyInput`.
2. `count > InputLimits.hardMax` (8000 characters) → `throw AppError.inputTooLong`.
3. Build the cache key: `SHA256(actionID | modelID | promptVersion | parameters | text)`, hex, truncated to 32 chars.
4. Cache hit → return it with `cameFromCache = true`. **No network call.**
5. Call `TextProcessing`.
6. On success: `UsageMetering.record(...)`, then `ResultCaching.store(...)`, then return.
7. Cancellation must propagate as `AppError.cancelled` and must not write to the cache or the meter.

`InputLimits`: `hardMax = 8000`, `softWarn = 2000`.

### 5.4 `ActionRegistry`

A `static let all: [TextAction]` in this order and with these number keys:

| # | id | Title (EN) | Title (RU) | tier | params |
|---|---|---|---|---|---|
| 1 | `fixGrammar` | Fix grammar | Исправить грамматику | economy | no |
| 2 | `rephrase` | Rephrase | Перефразировать | standard | no |
| 3 | `changeTone` | Change tone | Изменить тон | standard | yes (tone) |
| 4 | `translate` | Translate RU⇄EN | Перевести RU⇄EN | economy | no (direction auto) |
| 5 | `humanize` | Humanize | Сделать человечнее | standard | yes (level) |

Adding an action = one entry here + one template in `Templates.swift`. Nothing else.

---

## 6. Data layer

### 6.1 `LLMClient` and the provider-neutral request

```swift
struct LLMRequest: Sendable {
    let modelID: String
    let systemPrompt: String
    let userContent: String
    let jsonSchema: [String: Any]     // provider-neutral JSON Schema for the response
    let maxOutputTokens: Int
    let temperature: Double
    let lowReasoningEffort: Bool
}

struct LLMResponse: Sendable {
    let rawJSON: Data
    let inputTokens: Int
    let outputTokens: Int
}

protocol LLMClient: Sendable {
    var providerID: String { get }
    func complete(_ request: LLMRequest, apiKey: String) async throws -> LLMResponse
}
```

`ProviderRegistry` maps a provider id string to an `LLMClient` factory. MVP registers one: `"openai"`.

### 6.2 `ModelCatalog`

Static data. Each entry: `id`, `displayName`, `providerID`, `inputPricePerMillionUSD`, `outputPricePerMillionUSD`, `tier`.

| id | tier | in $/1M | out $/1M |
|---|---|---|---|
| `gpt-5-mini` | standard (default) | 0.25 | 2.00 |
| `gpt-5-nano` | economy | 0.05 | 0.40 |

Prices drive the cost meter only. **Before implementing, verify both the model ids and the prices against `https://developers.openai.com/api/docs/pricing` and update the table if they have moved.** If a listed model no longer exists, pick the closest current small/mini and nano-tier models and record the substitution in `CLAUDE.md`.

`maxOutputTokens` per request = `min(1200, inputTokenEstimate * 2 + 200)`, where `inputTokenEstimate = characterCount / 3`.

### 6.3 `OpenAIClient`

- Endpoint: `POST https://api.openai.com/v1/responses`
- Headers: `Authorization: Bearer <key>`, `Content-Type: application/json`
- Request body carries: model, input (system + user), structured JSON output schema with `strict: true`, `max_output_tokens`, low reasoning effort, low verbosity.
- `URLSession` with `timeoutIntervalForRequest = 20`, a dedicated ephemeral configuration, `waitsForConnectivity = false`.
- Fully `async`, honors `Task` cancellation.
- **Verify the exact parameter names for the Responses API and the reasoning/verbosity fields against the current OpenAI docs before writing the DTOs.** The shapes below are the intent, not a guarantee of field names:

```jsonc
{
  "model": "gpt-5-mini",
  "input": [
    { "role": "system", "content": "<system prompt>" },
    { "role": "user",   "content": "<user text>" }
  ],
  "text": {
    "verbosity": "low",
    "format": { "type": "json_schema", "name": "verba_result", "strict": true, "schema": { ... } }
  },
  "reasoning": { "effort": "low" },
  "max_output_tokens": 600
}
```

Response schema (the same for every action):

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": ["primary", "alternatives", "notes"],
  "properties": {
    "primary":      { "type": "string" },
    "alternatives": { "type": "array", "maxItems": 3, "items": { "type": "string" } },
    "notes":        { "type": "array", "maxItems": 4, "items": { "type": "string" } }
  }
}
```

Token usage is read from the response's usage object and passed back in `LLMResponse`.

### 6.4 `OpenAIErrorMapper`

| Condition | `AppError` |
|---|---|
| `URLError.notConnectedToInternet`, `.networkConnectionLost`, `.cannotFindHost`, `.dataNotAllowed` | `.offline` |
| `URLError.timedOut` or the 20s deadline | `.timedOut` |
| `CancellationError`, `URLError.cancelled` | `.cancelled` |
| HTTP 401, 403 | `.unauthorized` |
| HTTP 429 | `.rateLimited(retryAfter:)` parsed from the `Retry-After` header |
| HTTP 500–599 | `.providerUnavailable(status:)` |
| JSON decode failure, missing fields, non-JSON content | `.malformedResponse` |
| anything else | `.unknown` |

Never put the response body into the error. Log the status code and the byte count only.

### 6.5 `RetryPolicy`

- Retry only `.rateLimited` and `.providerUnavailable`.
- **Exactly one** retry. Delay = `Retry-After` if present, else 1.5s + jitter up to 0.5s.
- Never retry `.unauthorized`, `.malformedResponse`, `.inputTooLong`, `.offline`, `.cancelled`.
- One extra allowance: on `.malformedResponse`, `LLMTextProcessor` may re-ask **once** with an appended stricter instruction (`Return ONLY valid JSON matching the schema.`). If that also fails, surface `.malformedResponse`.

### 6.6 `PasteboardTextSource`

- Reads `NSPasteboard.general` on demand only. **No polling, no timers, no `changeCount` observation loop.**
- Keeps the last seen `changeCount` in memory; if unchanged since the previous capture, the returned `SourceText.origin` is `.pasteboard(isReused: true)`.
- On macOS 26, cooperate with pasteboard privacy: use the non-prompting `detect*` API to check for a string type before reading; set `NSPasteboard.accessBehavior` appropriately; if access is denied, throw `AppError.pasteboardAccessDenied`.
- Trims whitespace. Returns `nil` when the result is empty.

### 6.7 `KeychainSecretStore`

`SecItem` generic password. Service `com.dmytrovorko.verba.apikey`, account = provider id. `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`, `kSecAttrSynchronizable = false`. `setAPIKey(nil,...)` deletes the item. Read on each request; never cache the key in a stored property.

### 6.8 `ResultCache` and `UsageMeter`

Both are `actor`s.

- `ResultCache`: LRU, capacity 50, **in memory only**. Nothing about user text is ever written to disk.
- `UsageMeter`: rolling counters persisted in `UserDefaults` as **aggregates only** (date bucket, token counts, cost). Never store text or hashes of text. Resets the day bucket on date change; the month bucket on month change.

---

## 7. App layer

### 7.1 `FloatingPanel` — the single most failure-prone piece

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

Presentation rules:

- Show with `orderFrontRegardless()` then `makeKey()`. **Never** call `NSApp.activate(...)`.
- Position: horizontally centered on the screen containing the mouse, vertically at ~28% from the top (Spotlight placement).
- Width 560pt, height fits content, animated with a short (0.12s) fade+scale.
- Dismiss on: Esc, `resignKey`, a second hotkey press, or a completed copy.
- Dismissal must cancel any in-flight `Task`.
- Re-showing reuses the same panel instance. No window leaks — verify by toggling 20 times and checking `NSApp.windows.count` stays flat.

### 7.2 `HotkeyController`

`KeyboardShortcuts.Name("togglePanel")`, default `⌃⌥Space`. Registered once at launch. Handler hops to `@MainActor` and calls `PanelWindowController.toggle()`. The recorder UI lives in Settings; changes take effect immediately with no restart.

### 7.3 `ServicesProvider`

`Info.plist`:

```xml
<key>NSServices</key>
<array><dict>
  <key>NSMenuItem</key><dict><key>default</key><string>Improve with Verba</string></dict>
  <key>NSMessage</key><string>improveText</string>
  <key>NSPortName</key><string>Verba</string>
  <key>NSSendTypes</key><array><string>NSStringPboardType</string></array>
</dict></array>
```

`@objc func improveText(_ pboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString>)` reads the string, builds a `SourceText` with `origin: .service`, and opens the panel with it. Registered via `NSApp.servicesProvider` at launch. Do not block the main thread inside the handler.

Note in the README: the user assigns a shortcut in System Settings → Keyboard → Keyboard Shortcuts → Services, and this path is unreliable in Electron apps such as Slack — it is a secondary convenience, not the main path.

### 7.4 `AppContainer`

The only place concrete types are named. Builds every dependency once, exposes them as `Domain` protocol types, and hands them to the view models. No singletons anywhere else, no service locator, no global `shared` other than `AppLogger`.

### 7.5 `LoginItemController`

`SMAppService.mainApp` register/unregister, mirrored into `PreferenceStoring.launchAtLogin`. Default off. Reflect the real `status` in the UI rather than the stored flag when they disagree.

### 7.6 `AppLogger`

Thin wrapper over `os.Logger`, subsystem `com.dmytrovorko.verba`, categories: `app`, `hotkey`, `panel`, `capture`, `llm`, `keychain`, `usage`.

Allowed fields: action id, model id, provider id, character count, latency in ms, token counts, HTTP status, `AppError` case name, cache hit/miss.
**Forbidden fields:** the text, any substring of it, the clipboard contents, the API key, the response body, the prompt with the text interpolated.

Provide `logger.logRequest(action:model:charCount:)` style helpers so a caller cannot accidentally pass raw text — take `charCount: Int`, never `text: String`.

---

## 8. Prompts

`PromptTemplate` = `id`, `version` (integer, bump when the text changes — it is part of the cache key), `systemPrompt(parameters:language:) -> String`.

Shared preamble prepended to every template:

> You edit short workplace messages. Return only JSON matching the provided schema. `primary` is the improved text and nothing else — no preamble, no quotes, no markdown. `alternatives` holds up to 3 genuinely different phrasings, or an empty array. `notes` holds up to 4 very short bullets naming what changed, in the language of the input text. Preserve the author's meaning, names, links, code, and formatting. Never add greetings, sign-offs, or emoji that were not in the input.

Per-action system prompts (write them in this spirit; keep them under ~120 words each — they are billed on every request):

- **fixGrammar** — Correct grammar, spelling, punctuation, and article/preposition use. Keep the author's wording and register wherever it is already correct; do not upgrade the vocabulary. Notes name each concrete fix, e.g. `"can not to" → "can't"`.
- **rephrase** — Keep the meaning and the register, change the wording. `primary` is the best option; `alternatives` are two or three meaningfully different ones. Notes are empty or a one-line description of what shifted.
- **changeTone** — Rewrite in the requested tone (`formal` / `casual` / `direct` / `friendly`) without changing the facts. `direct` means shorter and unhedged, not blunt or rude.
- **translate** — Translate between Russian and English, direction auto-detected from the input. Preserve technical terms, product names, and code as-is. Notes may flag terms that had no clean equivalent.
- **humanize** — Rewrite so it reads as written by a real person at the given CEFR level (`b1` / `b2` / `c1`) whose first language is not English. Use contractions and everyday vocabulary; keep sentences ordinary in length; allow slight imperfection in rhythm. Explicitly avoid: em dashes, "delve", "moreover", "it's worth noting", tricolons, and other polished-AI tells. Never make it wrong on purpose.

`PromptBuilder` assembles preamble + action prompt + parameters and returns `(systemPrompt, userContent)`. The user text goes in `userContent` only, never interpolated into the system prompt.

---

## 9. Presentation layer

### 9.1 `PanelViewModel` state machine

```swift
enum PanelState: Equatable {
    case capturing
    case manualEntry(draft: String)
    case picking(source: SourceText, selectedIndex: Int)
    case parameterPicking(source: SourceText, action: TextAction, selectedIndex: Int)
    case running(source: SourceText, action: TextAction)
    case result(source: SourceText, action: TextAction, result: ActionResult)
    case failed(source: SourceText?, action: TextAction?, error: AppError)
}
```

`@MainActor @Observable`. Transitions:

- open → `capturing` → `picking` (text found) or `manualEntry` (nothing usable)
- `picking` + action without parameters → `running`; with parameters → `parameterPicking` → `running`
- `running` → `result` or `failed`
- `result`/`failed` + a number key → back to `running` with the new action, **reusing the same `SourceText`** (no recapture)
- any state + Esc → close (cancelling in-flight work)

### 9.2 Keyboard map — implement exactly

| Key | Where | Effect |
|---|---|---|
| `⌃⌥Space` | global | toggle panel |
| `↑` `↓` | picking | move selection |
| `⏎` | picking | run the selected action |
| `1`–`5` | picking, result, failed | run that action directly |
| `⇧3` / `⇧5` | picking, result | open the tone / level picker instead of using the default |
| `⏎` | result | copy `primary`, show HUD, close |
| `⌘1` `⌘2` `⌘3` | result | copy alternative 1/2/3, show HUD, close |
| `⌘⏎` | manualEntry | accept the typed text and go to `picking` |
| `⌘R` | result, failed | re-run the same action |
| `⎋` | anywhere | cancel and close |

### 9.3 View requirements

- **SourcePreviewView** — 3-line truncated, dimmed, monospaced digits for the character count. Shows a subtle `reused` marker when `origin == .pasteboard(isReused: true)`, and a cost hint when the character count exceeds `InputLimits.softWarn`.
- **ActionPickerView** — 5 rows, each with a number capsule, the title in the detected language, and the parameter hint for rows 3 and 5. Selection is keyboard-driven; the mouse works but is never required.
- **RunningView** — action name, indeterminate progress, "⎋ to cancel". Must appear within one frame of the key press — never wait for the network to render it.
- **ResultView** — `primary` in a selectable text block; alternatives below, numbered, each with its `⌘n` hint; notes as small bullets. `⏎ copy` and `⌘R rerun` hints in the footer. Cache hits show a small `cached` marker.
- **ErrorView** — the message from §10, plus the recovery button named there. Never a modal, never an `NSAlert`.
- **MenuBarView** — status dot, today and month usage in dollars, "Open Verba (⌃⌥Space)", Settings…, Quit.
- **SettingsView** — sections: General (hotkey recorder, launch at login, default level), Provider (API key secure field with Test key, model picker, economy toggle, monthly budget).

Styling: system materials, no custom color literals, respects light/dark and Reduce Motion (skip the panel animation when it is on).

---

## 10. Error presentation — exact strings and recovery

| `AppError` | Message | Recovery button |
|---|---|---|
| `missingAPIKey` | "Add your OpenAI API key to get started." | Open Settings |
| `emptyInput` | "Nothing to work with — copy some text first." | — |
| `inputTooLong(a, l)` | "Text too long — \(a) characters, limit is \(l)." | — |
| `offline` | "No internet connection." | Retry |
| `timedOut` | "The request timed out." | Retry |
| `rateLimited(t)` | "Rate limited. Retrying in \(t)s…" then "Still rate limited." | Retry |
| `unauthorized` | "The API key was rejected." | Open Settings |
| `providerUnavailable(s)` | "OpenAI is having trouble (\(s))." | Retry |
| `malformedResponse` | "Couldn't read the model's response." | Retry |
| `pasteboardAccessDenied` | "Verba needs clipboard access. Allow it in System Settings → Privacy & Security → Pasteboard." | Open System Settings |
| `cancelled` | *no UI — just close* | — |
| `unknown` | "Something went wrong." | Retry |

Retry always reuses the captured `SourceText` — the user never has to go back and copy again.

---

## 11. Verification — manual only

**This project has no tests.** No unit tests, no UI tests, no test target, no test fixtures. Do not create any, and do not add a testing framework. Verification is manual, driven by each stage's Definition of Done in §14.

Behaviours that would otherwise be unit-tested are verified by hand through a temporary debug menu item (removed before the stage is committed) or by running the app:

- validation limits — paste a 9000-character string and confirm no network call happens
- error mapping — bad key, airplane mode, an unreachable host
- cache — run the same action twice on the same text and confirm the second run is instant and shows the `cached` marker
- usage meter — check the menu bar figure moves and survives a relaunch
- language detection — run each action on a Russian and an English string

Because there is no automated safety net, implementations must be precise and side-effect-free. When unsure of an API or a signature, verify it against the SDK rather than guessing.

---

## 12. Code standards

**Comments.** Default to none. Clear names, small functions, early exits. Add a comment only for a non-obvious fact the code cannot express — a subtle ordering dependency, a workaround for an OS bug, a non-local invariant. One line. Never restate what the line below does. Never write "call this from X" usage notes, never justify why a helper exists. Rationale goes in the commit message.

**Swift style.**
- camelCase; types UpperCamelCase.
- `guard` for early exit, not nested `if`.
- Use `== false` instead of `!` when negating a `Bool`.
- `init` assigns properties only — no network, no timers, no subscriptions. Startup work goes in `start()`.
- Closures: `[weak self]` then `guard let self else { return }` as the first line; omit `self.` after rebinding.
- Omit `self.` unless the compiler requires it.
- One protocol conformance per extension; private helpers in a `private extension`.
- `public private(set)` where outside writes are not part of the design.
- No default parameter values except for DI factory defaults in `init`.
- Multi-line calls use block indentation (first argument on a new line, one level in, closing paren on its own line). Never align to the opening paren.
- Member order in new types: nested types → dependencies → public properties → private properties → static → init → lifecycle → public methods → private methods.
- MARKs: `// MARK: Dependencies`, `// MARK: - Private`.

**Concurrency.**
- `@MainActor` on view models and anything touching AppKit; nothing else.
- Long-lived mutable state that is not UI lives in an `actor` (`ResultCache`, `UsageMeter`).
- Every `Task` started from the panel is stored and cancelled on dismiss. No fire-and-forget `Task {}` in view models.
- No `DispatchQueue`, no `@unchecked Sendable`, no `nonisolated(unsafe)` — if the compiler complains, fix the design.

**Debug markers.** Temporary debug prints or comments are prefixed `DEBUG::::` and must never be committed.

**Commits.** Conventional Commits (`feat:`, `fix:`, `refactor:`, `chore:`, `docs:`). One stage may span several commits; never mix stages in one commit.

---

## 13. Repository files to author

**`.gitignore`** — Xcode template plus `.DS_Store`, `xcuserdata/`, `*.xcuserstate`, `.build/`, `DerivedData/`, `.claude/settings.local.json`.

**`README.md`** — what Verba is; requirements (macOS 26, Xcode 26); clone and open; the self-signed "Local Code Signing" certificate steps and why (stable Keychain ACL and TCC state across rebuilds); where to get an OpenAI key and how to enter it; the default hotkey; the one-time clipboard permission alert and why Always Allow is required; the optional Services shortcut setup; the layer diagram in three lines. State that the project has no tests and is verified manually.

**`CLAUDE.md`** — thin index for future AI sessions: one-paragraph product summary, the dependency rule sentence, the key-directories table, the hard constraints from §1, and `@`-imports of the six rule files, plus a table of the four skills.

**`.claude/rules/*.md`** — one concern each, 1–2 KB, no duplication with `CLAUDE.md`:

| File | Contents |
|---|---|
| `architecture.md` | The dependency table from §3, where each kind of new code goes, the composition-root rule, how to add a layer-crossing dependency |
| `swift-style.md` | The style list from §12 |
| `concurrency.md` | The concurrency list from §12 plus the cancellation-on-dismiss rule |
| `errors-and-logging.md` | The `AppError` catalog, the mapping table, the allowed/forbidden log fields |
| `llm-layer.md` | Prompt templates are data and versioned; cost caps; how the cache key is built; never hardcode a model id outside `ModelCatalog` |
| `ui-panel.md` | The `FloatingPanel` invariants from §7.1 and the keyboard map from §9.2 |

**`.claude/skills/*/SKILL.md`** — step-by-step procedures:

- `add-text-action` — registry entry → template + version → number key → picker row → manual check that the cache key changes.
- `add-llm-provider` — new client conforming to `LLMClient` → DTOs and error mapper → `ProviderRegistry` entry → `ModelCatalog` entries → settings picker. Explicitly: nothing in `Domain` or `Presentation` may change.
- `run-and-debug` — build and run from Xcode, reset onboarding and prefs, delete the Keychain item, `log stream --predicate 'subsystem == "com.dmytrovorko.verba"'`, how to confirm the panel is not stealing focus, how to test each error path (bad key, airplane mode, 8001 characters).
- `commit` — Conventional Commits, check for `DEBUG::::` before staging.

---

## 14. Stages

Implement in order. Each stage ends with a commit and a check against its Definition of Done. Do not implement anything listed under "not yet" for that stage.

### Stage 0 — Repository and scaffolding
Create the repo, `.gitignore`, `README.md`, `CLAUDE.md`, the six rule files, the four skill files, `Scripts/check-layers.sh`, and the Xcode project with the four empty layer folders, `LSUIElement`, accessory activation policy, and a `MenuBarExtra` with a single About item.
**Done:** initial commit exists; running from Xcode shows a menu bar icon and no Dock icon; `check-layers.sh` runs clean as a build phase.
**Not yet:** hotkey, panel, any networking.

### Stage 1 — Skeleton: hotkey and panel
`KeyboardShortcuts` dependency, `HotkeyController`, `FloatingPanel`, `PanelWindowController`, SwiftUI hosting with a placeholder view, Esc and resign-key dismissal, `AppContainer`, `AppLogger`, Settings window shell containing the hotkey recorder.
**Done:** with Slack fullscreen and focused, `⌃⌥Space` shows the panel over it; Slack's title bar stays active; typing goes to the panel; Esc closes it and the Slack caret is unchanged; toggling 20 times leaves `NSApp.windows.count` flat.
**Not yet:** clipboard, actions, network.

### Stage 2 — Text capture
`PasteboardTextSource`, `NLLanguageDetector`, `CaptureTextUseCase`, `SourcePreviewView`, manual-entry mode, the reused marker, `ServicesProvider` and the `NSServices` plist entry.
**Done:** copy in Slack → hotkey → the text appears in the panel; hotkey again with no new copy → shown as reused; empty clipboard → manual entry with focus in the field; the Service entry appears in TextEdit's Services menu and delivers the selection; the macOS clipboard alert appears once and never again after Always Allow.
**Not yet:** any LLM call.

### Stage 3 — LLM layer (no UI work)
All `Domain` entities, protocols, and use cases; `ActionRegistry`; `PromptTemplate`, `PromptBuilder`, `Templates`; `LLMClient`, `LLMRequest`, `LLMResponse`, `ProviderRegistry`, `ModelCatalog`, `RetryPolicy`, `LLMTextProcessor`; `OpenAIClient` + DTOs + error mapper; `KeychainSecretStore`; `ResultCache`; `UsageMeter`; the Provider settings section with the API key field and Test key.
**Done:** with a real key, a temporary debug menu command runs Fix grammar on a hardcoded string and logs the character count, latency, and token counts (never the text); a wrong key yields `.unauthorized`; airplane mode yields `.offline`; a 9000-character string yields `.inputTooLong` with no network call; the usage meter increments and survives a relaunch.
**Not yet:** panel UI for actions or results.

### Stage 4 — Results UI
`PanelViewModel` state machine, `ActionPickerView`, parameter pickers for tone and level, `RunningView`, `ResultView`, the HUD, the full keyboard map, re-run without recapture, cancellation on dismiss.
**Done:** the core loop (⌘C in Slack → hotkey → ⏎ → ⏎ → ⌘V) works end to end in under 6 seconds including the model call; every shortcut in §9.2 behaves as specified; running a second action on the same text performs no second capture; closing the panel mid-request cancels the URL task.
**Not yet:** onboarding, login item, polish.

### Stage 5 — Robustness and cost
An `ErrorView` state for every `AppError` with the §10 strings and recovery buttons; the retry policy wired end to end; the soft-warn cost hint; the economy-mode toggle; the monthly budget warning banner; the cache-hit marker; a log audit.
**Done:** a written checklist in the commit message lists all 12 error rows, each reproduced manually and each rendering correctly; `log stream` output captured across a full working session contains no fragment of any processed text.
**Not yet:** the event-synthesis spike.

### Stage 6 — Polish and the gated spike
Onboarding flow (key → hotkey → clipboard-permission explanation → launch at login), `LoginItemController`, the menu bar dropdown with usage, the app icon, the visual pass, Reduce Motion support.
Then, timeboxed: call `CGPreflightPostEventAccess()` and attempt to post ⌘C from this locally-signed build. If it works, ship "Auto-capture selection" as a settings toggle, **off by default**, that falls back to Path A on any failure. If it does not work, delete the spike code entirely and record the negative result in `CLAUDE.md`.
**Done:** a fresh-user run (prefs deleted, Keychain item deleted) completes onboarding and reaches a first successful result; the login item survives a reboot; the spike has a written yes/no verdict in `CLAUDE.md`.

---

## 15. Defaults already decided — do not re-litigate

| Question | Decision |
|---|---|
| App name / bundle id | Verba / `com.dmytrovorko.verba` |
| Hotkey | `⌃⌥Space`, user-configurable from Stage 1 |
| Panel position | Screen-centered, 28% from the top |
| UI language | English; action titles follow the detected text language |
| Monthly budget default | $5, warning only, never blocking |
| History | Not persisted at all in the MVP |
| Streaming responses | Not in the MVP |
| Paste-back into the source app | Not in the MVP |

If something in this spec turns out to be impossible or wrong on the current SDK, do not silently redesign around it: implement the rest of the stage, and record the conflict and the chosen alternative in `CLAUDE.md` under a "Deviations" heading.
