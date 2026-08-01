# LLM layer

## Prompt templates are data

`PromptTemplate` = `id`, `version` (integer, bump whenever the prompt
text changes — it is part of the cache key), `systemPrompt(parameters:
language:) -> String`. Templates live in `Data/Prompt/Templates.swift`.
The user's text goes in `userContent` only; it is never interpolated
into the system prompt string.

## Cache key

`SHA256(actionID | modelID | promptVersion | parameters | text)`, hex,
truncated to 32 chars. Changing a template's `version`, the action id,
the model id, or any parameter must change the key — that is the whole
point of the version field. A cache hit skips the network call entirely.

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
Never retry `.unauthorized`, `.malformedResponse`, `.inputTooLong`,
`.offline`, or `.cancelled`. A `.malformedResponse` gets one extra
allowance at the `LLMTextProcessor` level: re-ask once with a stricter
instruction appended, then surface the error if it fails again.
