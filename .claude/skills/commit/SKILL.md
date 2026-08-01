---
name: commit
description: Write a Conventional Commit for Verba and check for leftover debug markers first.
---

# Commit

1. **Search for debug markers** before staging anything:

   ```
   grep -rn "DEBUG::::" Verba Scripts
   ```

   Remove any temporary debug prints/comments entirely, or strip the
   `DEBUG::::` prefix if the underlying comment is genuinely worth
   keeping (rare — see `.claude/rules/swift-style.md`).

2. **Stage deliberately** — add specific files, not `git add -A`, so an
   accidental `.env`, credential, or build artifact never gets swept in.

3. **Write the message as Conventional Commits:**
   `feat:`, `fix:`, `refactor:`, `chore:`, `docs:`, followed by
   a short imperative summary. One stage may span several commits;
   never mix work from two different stages (see HANDOFF.md §14) in one
   commit.

4. **Commit.** Do not use `--no-verify` or skip hooks. If a pre-commit
   hook fails, fix the underlying issue and commit again rather than
   bypassing it.
