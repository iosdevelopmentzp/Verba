---
name: add-text-action
description: Add a new action (like "Fix grammar" or "Humanize") to Verba's panel action list.
---

# Add a text action

1. **Registry entry.** Add a `TextAction` to `ActionRegistry.all` in
   `Verba/Domain/ActionRegistry.swift`: pick the next free `numberKey`
   (1–5 are taken; extending past 5 needs a keyboard-map decision, see
   `.claude/rules/ui-panel.md`), a `templateID`, a `tier`, and whether it
   `needsParameters`.
2. **Template + version.** Add a matching entry to
   `Verba/Data/Prompt/Templates.swift` with `id`, a fresh `version`
   starting at `1`, and a `systemPrompt(parameters:language:)` under
   ~120 words, in the spirit of the existing templates (see HANDOFF.md
   §8). The user's text never goes in the system prompt.
3. **Number key.** Confirm the `numberKey` matches the row order you
   want in the picker — `ActionRegistry.all`'s order is the picker's
   order.
4. **Picker row.** `ActionPickerView` renders every entry in
   `ActionRegistry.all` automatically; if the new action
   `needsParameters`, make sure its parameter picker (tone or level) is
   wired the same way as `changeTone` / `humanize`.
5. **Run it.** Build, invoke the action on an English and a Russian
   string, and confirm the system prompt is non-empty and the user's
   text never appears in it (check the request in the debugger, never
   in a log line).
6. **Verify the cache key changes.** Since the cache key includes
   `actionID` and `promptVersion`, a brand-new action naturally gets a
   fresh key. If you're editing an *existing* template's wording, bump
   its `version` — otherwise stale cached results keep coming back.

Nothing outside `ActionRegistry.swift`, `Templates.swift`, and the
picker view needs to change.
