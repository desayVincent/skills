# ADR 0002: Fork selected Matt Pocock skills for C/C++ under new names

## Status

Accepted

## Context

Matt Pocock’s engineering skills (`codebase-design`, `domain-modeling`,
`improve-codebase-architecture`) provide strong vocabulary and process for deep
modules, but examples and scan lenses are TypeScript-oriented. We need the same
discipline for C/C++ SDK and platform work without colliding with upstream skill
names when both are installed, and without depending on re-running his installer
over team edits.

## Decision

1. Copy (not symlink) three skills into this monorepo under `skills/engineering/`.
2. Rename to avoid name collision:
   - `codebase-design` → **`deep-modules-c`**
   - `domain-modeling` → **`domain-model-c`**
   - `improve-codebase-architecture` → **`improve-architecture-c`**
3. Keep MIT license and `NOTICE` with upstream pin (v1.2.2 / commit
   `8b36d4fb…`).
4. Adapt content for C/C++ / SDK: opaque types, ops seams, include fan-out,
   session/stream/message domain language, architecture friction list.
5. Do **not** vendor `setup-ts-deep-modules` or `ponytail-review` here;
   ponytail remains usable from Matt/other installs as a complementary review.
6. **Self-contained skills:** each skill folder must run after a single
   `cp -a` of that folder. `improve-architecture-c` inlines vocabulary, grill,
   and write-gate; peer skills are optional, not required.

## Consequences

- Teammates install this monorepo path once; C-adapted skills do not overwrite
  Matt’s originals.
- Upstream Matt updates must be merged deliberately (diff NOTICE pin, pull
  useful process fixes).
- Cross-skill links are optional peers only; no hard install graph between the
  three architecture skills.
