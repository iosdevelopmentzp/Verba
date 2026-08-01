# Swift style

- camelCase for values and functions; `UpperCamelCase` for types.
- `guard` for early exit, not nested `if`.
- Use `== false` instead of `!` when negating a `Bool`.
- `init` assigns properties only — no network, no timers, no
  subscriptions. Startup work goes in `start()`.
- Closures: `[weak self]` then `guard let self else { return }` as the
  first line; omit `self.` after rebinding.
- Omit `self.` unless the compiler requires it.
- One protocol conformance per `extension`; private helpers live in a
  `private extension`.
- `public private(set)` where outside writes are not part of the design.
- No default parameter values except for DI factory defaults in `init`.
- Multi-line calls use block indentation: first argument on a new line,
  one level in, closing paren on its own line. Never align to the
  opening paren.
- Member order in new types: nested types → dependencies → public
  properties → private properties → static → `init` → lifecycle →
  public methods → private methods.
- MARKs: `// MARK: Dependencies`, `// MARK: - Private`.

## Comments

Default to none. Clear names, small functions, and early exits carry the
meaning. Add a comment only for a non-obvious fact the code cannot
express — a subtle ordering dependency, a workaround for an OS bug, a
non-local invariant. One line. Never restate what the line below does,
never write "call this from X" usage notes, never justify why a helper
exists. Rationale belongs in the commit message.

## Debug markers

Temporary debug prints or comments are prefixed `DEBUG::::` and must
never be committed. Search for the marker before staging.

## Commits

Conventional Commits (`feat:`, `fix:`, `refactor:`, `chore:`, `docs:`).
One stage may span several commits; never mix stages in one commit.
