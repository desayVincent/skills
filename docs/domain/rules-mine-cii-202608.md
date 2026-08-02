---
title: "Rules mine: C Interfaces and Implementations (CII, 2026-08)"
description: >
  Reverse-mine of checkable host C library conventions from David R. Hanson's
  CII book code (github.com/drh/cii), mapped to write-legible-embedded-c Base
  vs Overlay. Research only — no Base semantic edits in this pass.
importance_tier: "normal"
contextType: "research"
---

# Rules mine — CII (Hanson, 2026-08)

## Goal

From **C Interfaces and Implementations** (Addison-Wesley, 1997) and its
**official companion code** ([drh/cii](https://github.com/drh/cii), MIT),
extract **0/1-checkable** legibility / reuse conventions. Score each against:

- already covered by vendored Base (`write-legible-c` §§1–14)
- HOST A/B evidence (model default)
- whether it belongs in Base packaging, Overlay, Super SDK house style, or **drop**

**Non-goals:** rewrite `c-standard.md`; force CII exception macros onto Linux
IRQ; commit the cloned tree (kept under `.scratch/cii` only).

## Corpus

| Item | Detail |
|------|--------|
| Book | David R. Hanson, *C Interfaces and Implementations* |
| Code | `https://github.com/drh/cii` (author distribution) |
| Local clone | `.scratch/cii/` (gitignored workspace scratch) |
| License (code) | MIT (see `LICENSE` in clone) |
| Modules sampled | `except`, `assert`, `mem`/`arena`, `stack`, `table`, `list`, `atom`, opaque-`T` headers |

Book prose is copyrighted; this mine cites **patterns** and **public code
shapes**, not long prose quotes.

## CII shape in one page

Recurring library protocol (seen across headers/impls):

1. **One interface file per ADT** — e.g. `stack.h` / `stack.c`.
2. **Opaque client type via `T` macro** — `#define T Stack_T` then
   `typedef struct T *T;` … `#undef T` so the public name is `Stack_T` but the
   implementation file redefines `T` and completes `struct T`.
3. **Verb + module prefix** — `Stack_new`, `Stack_push`, `Stack_free`.
4. **Lifetime ownership pairs** — `new`/`free` (heap ADT); free often takes
   `T *` so the pointer can be nulled.
5. **Checked alloc layer** — `ALLOC`/`NEW`/`FREE` wrap `malloc` with file/line
   and raise `Mem_Failed` (exceptions), not raw libc in ADTs.
6. **Arena** — bump allocator + dispose whole region (bulk free).
7. **Exceptions** — `Except_T` + `TRY`/`EXCEPT`/`FINALLY`/`RAISE` via `setjmp`
   (structured exceptional control flow, **not** status enums).
8. **Assert → exception** — failed assert raises `Assert_Failed` when not
   `NDEBUG`.
9. **Client callbacks** — `Table_map` / `List_map` with `apply` + closure
   `cl` for iteration without exposing representation.
10. **Representation headers when needed** — e.g. `arrayrep.h` for
    implementation-sharing, not for casual clients.

---

## Candidate rules table

Legend — **model-default (HOST):** `stable` | `partial` | `unstable`  
**layer:** `Base (already)` | `Base packaging` | `SDK house style` | `Overlay` | `drop` | `conflict`

| id | CII pattern | 0/1 check | model-default | vs Base | layer | notes |
|----|-------------|-----------|---------------|---------|-------|-------|
| C01 | One ADT ≈ one `.h` + one `.c` | File ownership audit | partial | Aligns with module focus | **Base packaging** (encourage greenfield skeleton) | Base §1 is file *order*, not ADT packing |
| C02 | Opaque pointer type for library clients (`typedef struct T *T`) | Public header has incomplete struct only | partial | **Tension:** Base §7 prefers exposed layout for *internal* modules | **SDK house style** for true library boundaries; Base wins for in-tree Super SDK modules | Don't force opacity on every host module |
| C03 | Temporary `T` macro in headers for short names | Presence of `#define T` / `#undef T` pattern | **unstable** | Not in Base | **drop** as skill requirement | Distinctive CII idiom; rare in modern code; models won't invent; optional style only |
| C04 | Module-prefixed verbs: `Stack_push` | Prefix + verb audit | stable-ish | Base §3 | **Base (already)** | Both systems agree |
| C05 | Heap ADT: `X_new` + `X_free(T*)` nulls caller pointer | Pair + free signature | partial | Base §3 create/destroy | **Base (already)** + note free-via-pointer | CII `Stack_free(T *stk)` is a concrete pattern worth examples |
| C06 | Checked allocation macros with file/line | Alloc goes through module, not raw malloc in ADT | partial | Base: status vs CII: exception | **SDK house style** if product uses arenas/checked alloc | Do **not** replace Base status model with Except |
| C07 | Arena / region allocator for related lifetimes | Arena type + free-all API | unstable | Not Base core | **SDK house style** / product libs | Useful for Super SDK tools; optional reference |
| C08 | **Exception types** `Except_T` + RAISE | Exception objects as first-class | unstable | **Conflicts** Base §6 status enums + §9 MODULE_TRY | **drop** for default skill path | CII's biggest identity; Base chose status+TRY instead |
| C09 | TRY/EXCEPT/FINALLY macros (setjmp) | Macro control flow | unstable | Base §9 forbids general return macros except MODULE_TRY | **drop** / **conflict** | Importing CII TRY into skill would fight Base |
| C10 | Assert raises exception (not abort-only) | assert policy | partial | Base §8: assert on internal | **partial Base** | Keep Base assert-as-contract; don't require RAISE |
| C11 | `assert(stk)` at public entry of ADT ops | Non-null check on ctx | partial→stable | Base §8 public validate / internal assert | **Base (already)** | CII often assert-only on public ADT (no status); Base prefers status at public boundary |
| C12 | Map/apply with closure `cl` | Iteration without exposing rep | partial | Related to Base §7 dispatch tables | **SDK house style** | Good library pattern; not mandatory Base |
| C13 | Const keys / documented ownership of pointed data | Comment + const | partial | Base §7 const, §11 contracts | **Base (already)** | |
| C14 | Implementation completes `struct T` only in `.c` | Layout not in public `.h` | partial | Same tension as C02 | **SDK house style** for frozen lib ABI | Super SDK ORCH can expose layout for stack embed (Base) |
| C15 | Named exception constants with reason strings | `const Except_T Mem_Failed = { "..." }` | n/a if no Except | — | **drop** under Base | Equivalent under Base is **one producer per status code** (H13 from prior mine) |
| C16 | FREE sets pointer to 0 | Use-after-free hardness | partial | Not explicit Base | **Base packaging** (optional tip) | Small, checkable; models sometimes forget |
| C17 | No kernel/IRQ assumptions — pure host library C | No IRQ APIs | stable for this corpus | HOST branch | **Base HOST** | Confirms CII is Host/Base ore, not Overlay |
| C18 | Literate / full interface-in-chapter presentation | Process | n/a | — | **drop** as runtime skill | Book pedagogy, not agent gate |

---

## Crosswalk: CII vs write-legible-c Base

| Concern | CII | Base (skill) | Skill stance |
|---------|-----|--------------|--------------|
| Error model | Exceptions (`setjmp`) | Status enum + `MODULE_TRY` | **Keep Base**; CII Except is alternate universe |
| Public failures | Often assert / raise | Validate → status | **Keep Base** for Super SDK APIs |
| Opacity | Default for ADTs | Prefer exposed layout in-module | **Context-dependent** (C02) |
| Naming | `Module_verb` | `module_verb` / prefix | **Same idea** (C04) |
| Alloc | NEW/ALLOC + Except | Explicit flags / status | House style if needed (C06–C07) |
| Decomposition | ADT methods, not orch/leaf vocabulary | Orchestrator / leaf / adapter | **Base vocabulary** for HOST |
| Legibility goal | Reuse + clear interfaces | Machine-grep + small functions | Complementary |

**Key distillation result:** CII teaches **library architecture**; Base teaches
**machine-legible control and status**. Distilling CII into the skill must
**not** replace Base §6/§9 with Except/TRY-setjmp.

---

## What is worth doing next (candidates only)

| Priority | Action | Why |
|----------|--------|-----|
| P0 | **No Base text rewrite** from CII Except/T-macro | Conflict + ADR |
| P1 | Optional **HOST/ORCH note** (domain or SKILL one-liner): true library boundaries may use opaque `Module_T` + `Module_new`/`Module_free`; in-tree Super SDK modules may expose layout per Base §7 | Resolves C02 without new protocol |
| P2 | Optional **examples pointer** in domain docs: CII `Stack_*` / `Table_map` as *illustration* of ADT + map (link to github.com/drh/cii), MIT attribution | Teaching, not gate |
| P3 | If Super SDK wants arenas: separate product library guideline, not Overlay | C07 |
| — | Overlay / HOT / Classification | **Out of scope** for CII |

This pass implements **documentation mine only** (this file). P1–P2 skill edits
need a separate LGTM.

## Comparison with prior host mine (`rules-mine-host-202608.md`)

| Prior H-id | CII reinforcement |
|------------|-------------------|
| H03 prefix naming | C04 |
| H04 lifetime pairs | C05 |
| H11–H13 status / producers | CII uses Except instead — **do not merge** |
| H16 MODULE_TRY | CII has different TRY — **do not merge** |
| H15 assert | C10–C11 partial |
| New | C02 opacity tradeoff, C06–C07 alloc/arena, C12 map+closure, C16 FREE null |

## Verification

- [x] Mined from author-published code (MIT), not pirated book dump as primary
- [x] Patterns mapped to 0/1 or explicitly dropped
- [x] Conflicts with Base named (Except, opacity)
- [x] No skill / Base semantic file edits
- [x] Clone kept under `.scratch/` (not skill package)

## Attribution

- Book: David R. Hanson, *C Interfaces and Implementations*, Addison-Wesley, 1997.
- Code: Copyright David R. Hanson; MIT license as in [drh/cii](https://github.com/drh/cii).
- This document is team research for `write-legible-embedded-c`; it does not
  rebrand Hanson or 7etsuo material as original rule text.
