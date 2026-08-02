---
title: "Rules mine: Host / Base legibility (2026-08)"
description: >
  First-pass reverse-mine of checkable host C legibility conventions from
  vendored write-legible-c Base + skeleton, scored against session A/B
  evidence. No skill code changes in this pass.
importance_tier: "normal"
contextType: "research"
---

# Rules mine — Host / Base (2026-08)

## Goal of this pass

Turn **high-signal host C shape** into a **candidate rules table**: what is
already Base, what strong models already do without skill, what skill still
buys, and what **must not** be pushed into Overlay/IRQ.

**Non-goals (this pass):** edit `SKILL.md` / `c-standard.md` semantics; invent
a second TRY protocol; mine Linux drivers into Base; track A/B harnesses.

## Corpus

| # | Source | License | Role |
|---|--------|---------|------|
| 1 | `skills/engineering/write-legible-embedded-c/references/base/c-standard.md` §§1–14 | MIT (7etsuo / write-legible-c) | Normative rule text |
| 2 | `.../references/base/skeleton.md` (`sensor_*` greenfield) | MIT (same) | Executable shape of those rules |
| 3 | *(deferred)* external host library | — | Optional second mine; not required for table v1 |

**Why no second GitHub module this pass:** Base + skeleton already concentrate
the distinctive protocol (`MODULE_TRY`, altitude, §14, file vocabulary). Adding
a random “popular C repo” without a quality bar risks mining style noise.
Second corpus = follow-up when a Super SDK host module is named.

## Method

1. Extract patterns that appear **both** as written rules and in `skeleton.md`.
2. Mark each as **0/1 checkable** or drop (aesthetics).
3. Score **model-default** from session evidence:
   - HOST Super SDK session SM A/B (`.scratch/ab-e2e-host/`, not in skill tree)
   - EMBEDDED foo IRQ A/B (prior session; code-tie, Classification gap)
4. Assign layer: `Base (already)` | `Base packaging only` | `Overlay` | `drop`.

## Evidence snapshot (model-default)

| Scenario | With skill | Without skill | Delta |
|----------|------------|---------------|-------|
| HOST session SM | Base §14 table, `SESS_TRY`, orch/leaf, status enum | orch/leaf, status enum, asserts, small funcs; informal checklist | **Small:** formal §14 + TRY macro brand |
| EMBEDDED IRQ ring | Classification + HOT notes + PC | Same driver shape | **Large on delivery fields; code tie** |

Implication: reverse-mine should prioritize **protocol gates models skip**, not
re-teach “split a state machine.”

---

## Candidate rules table

Legend — **model-default:** `stable` (no skill usually hits) | `partial` | `unstable` (skill strongly needed) | `n/a` (embedded-only)

| id | pattern (one line) | 0/1 check | model-default (HOST) | already in skill? | layer | evidence |
|----|--------------------|-----------|----------------------|-------------------|-------|----------|
| H01 | File-top vocabulary order: comment → includes → constants → types → static protos+contracts → public defs → static defs | Protos before bodies; section order audit | partial | Base §1 | **Base (already)** | skeleton; A HOST closer than B |
| H02 | No magic numbers except obvious 0/1; units in names | Grep literals in logic | partial | Base §2 | **Base (already)** | skeleton enums |
| H03 | Module prefix on external + static symbols; verb_object; `is_`/`has_` predicates | Naming audit | stable-ish | Base §3 | **Base (already)** | both arms used `sess_*` |
| H04 | Lifetime pairs exact: create/destroy, init/deinit, open/close | Pair audit | partial | Base §3 | **Base (already)** | sess_init/deinit both arms |
| H05 | One job/function; contract “and” ⇒ split | Contract text + size | partial | Base §4 | **Base (already)** | |
| H06 | Target 15 / hard 40 lines; nest ≤2; guards then happy path | Line/nest count | **stable** on clean greenfield | Base §4 | **Base (already)** | HOST A/B both &lt;40 |
| H07 | Every function exactly one altitude: orchestrator \| leaf \| adapter | Manual altitude tag | **partial→stable** on SM tasks | Base §4 | **Base (already)** | B used leaf split without skill |
| H08 | Name test: paraphrase-only helper ⇒ inline | Review | partial | Base §4 | **Base (already)** | |
| H09 | Param order: ctx → outs → ins; max 4; buf+len adjacent | Signature audit | partial | Base §4 | **Base (already)** | |
| H10 | Early return; no cleanup-only goto; switch default; bounded loops; no recursion | Grep/structure | partial | Base §5 | **Base (already)** | |
| H11 | Module status enum; success named 0; one enum per module; prefixed errors | Type audit | **stable** | Base §6 | **Base (already)** | both HOST arms |
| H12 | Every fallible call checked; status propagates; log only at top | Call audit | partial | Base §6 | **Base (already)** | |
| H13 | Minimize producers per error code (grep lands near one site) | Grep producers | **unstable** | Base §6 | **Base (already)** — worth **HOST deliverable emphasis** | models invent many ERR_* sites |
| H14 | Fixed-width types; const correctness; init-at-decl; one deref level | Review | partial | Base §7 | **Base (already)** | |
| H15 | Public validates; static helpers assert; mutating leaf ≥1 assert | Assert density | partial→stable | Base §8 | **Base (already)** | both HOST arms asserted |
| H16 | **`MODULE_TRY` / `FOO_TRY`**: sole return macro; only in non-acquiring orchestrators | Macro presence + acquire audit | **unstable** | Base §9 | **Base (already)** — **highest HOST skill delta** | A: `SESS_TRY`; B: plain `if` |
| H17 | No other control-flow macros (return/goto/break hidden) | Macro audit | partial | Base §9 | **Base (already)** | |
| H18 | Prototype contract comments (ownership, null, failures); body comments = why | Comment audit | partial | Base §11 | **Base (already)** | A denser static protos |
| H19 | §14 pre-delivery checklist applied end-to-end (or deviation @ site) | Deliverable / review | **unstable** as *full table* | Base §14 + skill HOST deliver | **Base (already)** + **packaging: keep HOST deliver pointing at §14** | A full 17-row; B informal list |
| H20 | Greenfield: load skeleton branch of Base skill | Process | n/a without skill | write-legible-c-SKILL disclosed | **Base packaging (already)** | |
| H21 | Near-miss short/flat existing code: map_eat before accept | Process | unstable | near-miss-map-eat.md | **Base packaging (already)** | not exercised in A/B |
| E01 | Classification multi-region + HOT notes | Record fields | n/a HOST | Overlay | **Overlay (already)** — do not mine into Base | EMBEDDED A/B |
| E02 | PC1–PC8 prior-contamination ban | Checklist | n/a HOST | Overlay concurrency | **Overlay (already)** | |
| E03 | H1: Base 15/40 does not force HOT splits | Path Class HOT | n/a HOST | Overlay hot-rules | **Overlay (already)** — **blocks wrong reverse** of H06 onto IRQ | |
| X01 | “Elegant” brace/style without check | none | — | — | **drop** | aesthetics |
| X02 | Userspace `TRY` required inside ISR/HOT | conflicts E03/tree | — | — | **drop** | contamination |
| X03 | New second status-propagation protocol beyond Base §9 | duplicate | — | — | **drop** | ADR: Base semantics upstream |

---

## Patterns illustrated by skeleton (reverse map)

`skeleton.md` `sensor_*` is the **executable proof** of H01–H16:

| Skeleton feature | Rule ids |
|------------------|----------|
| File comment + includes + enums + protos + public + static | H01 |
| `SENSOR_POLL_INTERVAL_MS`, `SENSOR_RAW_MAX`, … | H02 |
| `sensor_*` prefix | H03 |
| `SENSOR_TRY` in `sensor_poll` only | H16, H17 |
| `sensor_poll` = validate → adapter → validate → leaf record | H07, H12 |
| `sensor_read_raw` = single foreign call + status map | H07 adapter |
| One producer per `SENSOR_ERR_*` | H13 |
| Public validate vs leaf purity | H15 |

**Takeaway:** “Elegant” here = **greppable status + single-altitude functions + TRY in pure orchestrators**, not prettier algorithms.

---

## What skill still buys on HOST (after mine)

Ranked by A/B + table:

1. **H16 `MODULE_TRY`** — distinctive; models default to `if (st) return st`.
2. **H19 full §14** — models approximate structure, skip systematic gate.
3. **H13 single error producer** — easy to violate while “looking clean.”
4. **H01 + H18** denser file vocabulary / contracts — partial without skill.
5. **H06/H07** — weak skill moat on clean greenfield (models already split).

**Do not grow Base text** for (5). Prefer fail-closed **HOST deliverable** language (already: Base §14) over new paragraphs.

## What not to do next

| Temptation | Why not |
|------------|---------|
| Rewrite Base §§ to be “stronger” | ADR 0001: semantics stay upstream; refresh vendor instead |
| Copy H16 into Overlay / Linux appendix | IRQ/acquire paths forbid TRY-as-return ceremony; tree wins |
| Mine random GitHub drivers for Base | Wrong altitude; prior contamination |
| Treat A/B harness as skill content | User: track skill content only |

## Recommended second cut (needs separate approval)

Only if product wants skill **edits** after this table:

| Priority | Change | Touch |
|----------|--------|--------|
| P0 | HOST Deliver: one line that **§14 is fail-closed** and **`MODULE_TRY` expected when module has status enum + non-acquiring orchestrators** (pointer to Base §9/§14, no new protocol) | `SKILL.md` HOST Deliver only |
| P1 | Optional one-row “model-default trap” note in domain CONTEXT (TRY + §14 + single error producer) | `docs/domain/...CONTEXT.md` |
| P2 | Second corpus mine on a **named Super SDK host module** | new rules-mine doc |
| P3 | Overlay mine on real Nested Kernel tree | separate rules-mine-embedded-*.md |

**Research pass** shipped this file only. **P0 skill edit (approved):** HOST Deliver
in `SKILL.md` — §14 fail-closed + `MODULE_TRY` pointer (Base §9/skeleton; no new
protocol). README + domain CONTEXT synced. P1–P3 still optional/future.

## Verification of this deliverable

- [x] Corpus listed with license
- [x] Rules 0/1-checkable or dropped
- [x] Layer + already-covered marked
- [x] HOST/EMBEDDED A/B evidence referenced
- [x] No `c-standard.md` / Overlay semantics edited
- [x] No ab-e2e harness added to skill package

## Attribution

Base rule text and skeleton are **write-legible-c** by **7etsuo**, **MIT**, vendored under `references/base/`. This mine document is team research; it does not rebrand Base as original.
