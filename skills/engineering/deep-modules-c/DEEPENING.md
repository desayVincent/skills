# Deepening (C/C++)

How to deepen a shallow cluster given its dependencies. Vocabulary and **seam
rule**: [SKILL.md](SKILL.md).

Load when a candidate will be merged or re-seamed and you must choose how to
test it.

## Dependency categories

Classify each candidate. Category fixes the test strategy across the seam.

### 1. In-process

Pure compute / memory, no I/O, no hardware. Merge and test through the public
interface. No adapter.

Examples: pure codecs, protocol state machines, CRC, packing.

### 2. Local-substitutable

Has a cheap local stand-in. Deepen with the stand-in; seam may stay internal.

Examples: temp/mem filesystem, fake clock, arena with fail injection.

### 3. Owned-platform

Your HAL, driver, or IPC that you control. Port = ops table (or C++ abstract
interface). Deep module owns policy; adapter owns device/transport. Tests use
loopback/fake when possible; production uses real adapter.

### 4. True-external

Closed blobs or hardware you do not control. Inject a mock adapter with fixed
responses.

## Seam discipline

Apply the **seam rule** in [SKILL.md](SKILL.md) — known boundary first; adapter
count is evidence. Do not invent a second adapter only to satisfy a count.

- **Internal vs external seams.** Keep test-only seams off the public header.
- **Globals.** Prefer explicit `ctx` / ops. A `static` singleton is a seam only
  if replaceable without editing callers, or documented as a board singleton.

## Testing: replace, don’t layer

- Prefer **contract tests** at the public interface for behaviour the module
  promises.
- Drop private tests only when the same behaviour is covered at the public
  surface; keep white-box tests for fault injection, safety, and hardware paths
  the public surface cannot exercise.
- Assert outcomes (return codes, out-params, callbacks), not private fields,
  in contract tests.
- Contract tests survive internal refactors; if layout-only edits break them,
  they test past the interface.

**Done when:** candidate has one category, each seam names its known boundary
(or is cut), a stated public test surface, and any remaining private tests are
justified.
