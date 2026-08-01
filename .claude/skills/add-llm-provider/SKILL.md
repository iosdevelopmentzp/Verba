---
name: add-llm-provider
description: Add a new LLM provider (alongside OpenAI) without touching Domain or Presentation.
---

# Add an LLM provider

1. **Client.** Create `Verba/Data/LLM/<Provider>/<Provider>Client.swift`
   conforming to `LLMClient` (`providerID`, `complete(_:apiKey:)`). Follow
   `OpenAIClient`'s shape: dedicated ephemeral `URLSession`,
   `timeoutIntervalForRequest = 20`, cancellation-aware.
2. **DTOs and error mapper.** Add
   `<Provider>DTO.swift` and `<Provider>ErrorMapper.swift` in the same
   folder. The mapper's only output type is `AppError` — see
   `.claude/rules/errors-and-logging.md` for the mapping table shape to
   replicate for the new provider's error codes.
3. **`ProviderRegistry` entry.** Register the new provider id and its
   client factory in `Verba/Data/LLM/ProviderRegistry.swift`.
4. **`ModelCatalog` entries.** Add the provider's models to
   `Verba/Data/LLM/ModelCatalog.swift` with verified ids and current
   per-token prices — never hardcode a model id anywhere else.
5. **Settings picker.** Extend `ProviderSettingsSection` so the new
   provider's models are selectable and its API key field is wired to
   `SecretStoring` by provider id.
6. **Walk the mapping table by hand.** Trigger a bad key, airplane
   mode, and an oversized input against the new provider and confirm
   each surfaces the right `AppError`. There are no tests in this
   project — every row you cannot trigger, re-read instead.

**Explicitly out of scope:** nothing in `Domain` or `Presentation` may
change. If it seems like it must, the new provider doesn't fit the
`LLMClient` protocol yet — fix the protocol, not the layers around it.
