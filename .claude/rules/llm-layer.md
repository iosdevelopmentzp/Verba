# LLM layer

## Prompt templates are data

`PromptTemplate` = `id`, `version` (integer, bump whenever the prompt
text changes — it is part of the cache key), `systemPrompt(parameters:
language:) -> String`. Templates live in `Data/Prompt/Templates.swift`.
The text being edited goes in `userContent` only; it is never
interpolated into the system prompt string. An explicit user
*instruction* is the one exception — see "Extra instruction" below.

## Extra instruction and prompt overrides

`ActionParameters.extraInstruction` is a one-off instruction the user types on
the result screen. `PromptBuilder` appends it to the **system** prompt in a
fenced block that outranks the template body, because an instruction placed
next to the subject text gets edited rather than obeyed.
`ActionParameters.systemPromptOverride` replaces the template body only; the
preamble is always kept. Both are free text, so both are appended to the cache
key as their own `|`-separated fields rather than inside the comma-joined
parameter group.

## Creativity

The Responses API takes no `temperature` for GPT-5-family reasoning models.
`Creativity` maps to `reasoning.effort` plus `text.verbosity` plus a prompt
clause. There is **no single effort value every model accepts**: `gpt-5.6-*`
rejects `"minimal"`, and `gpt-5-nano`/`gpt-5-mini` reject `"none"`. Each
`ModelCatalogEntry` therefore declares its own `lowestReasoningEffort`, which
`OpenAIRequestBuilder` uses for `precise` and `balanced`; `creative` raises it
to `"low"` and verbosity to `"medium"`. An unknown model id falls back to
`ModelCatalog.universalReasoningEffort` (`"low"`), which every model accepts.

## Cache key

`SHA256(actionID | modelID | promptVersion | parameters | extraInstruction |
systemPromptOverride | text)`, where `parameters` is
`tone,level,sourceLanguage,targetLanguage,creativity`, hex,
truncated to 32 chars. Changing a template's `version`, the action id,
the model id, or any parameter must change the key — that is the whole
point of the version field. A cache hit skips the network call entirely.

`ProcessTextUseCase.execute` takes a `bypassCache: Bool`. Rerun
(`PanelViewModel.rerun()`, `⌘R`) always passes `true` — otherwise
rerunning the exact same action on the exact same text is guaranteed
to hit its own just-written cache entry and silently return the
identical result, which defeats the entire point of "try again."
Bypassing only skips the *read*; the fresh result still overwrites the
cache entry afterward, so a later genuine cache hit gets the newest
result, not the stale one.

## Alternatives budget

A translation is roughly as long as its input, so alternatives double the billed
output for something the user rarely reads on a long message.
`OutputBudget.allowsAlternatives(action:characterCount:)` (Domain) returns false
for `translate` above `InputLimits.softWarn`, which both appends
`Templates.singleOptionSection` and drops the response schema's
`alternatives.maxItems` to `0` — verified accepted under `strict: true`. The
decision derives from the action and the text, both already in the cache key, so
it needs no key field of its own.

## Cost caps

- `ModelCatalog` is the single source of truth for model ids and
  per-token prices. Never hardcode a model id anywhere else — not in
  `OpenAIClient`, not in Settings, not in a test fixture default.
  `PreferenceStoring.modelID` and `ActionRegistry` refer to catalog
  entries by id.
- `maxOutputTokens` per request = `min(1200, inputTokenEstimate * 2 +
  200)`, where `inputTokenEstimate = characterCount / 3`.
- `UsageMeter` accumulates cost from the catalog's prices and the
  actual token counts returned by the provider — never estimate cost
  client-side beyond that.
- The monthly budget is a warning only; it never blocks a request.

## Retries

Retry only `.rateLimited` and `.providerUnavailable`, exactly once.
Never retry `.unauthorized`, `.malformedRequest`, `.malformedResponse`, `.inputTooLong`,
`.offline`, or `.cancelled`. A `.malformedResponse` gets one extra
allowance at the `LLMTextProcessor` level: re-ask once with a stricter
instruction appended, then surface the error if it fails again.
