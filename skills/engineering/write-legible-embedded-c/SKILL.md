---
name: write-legible-embedded-c
description: >
  Legible, context-correct C writing and review. Use for host userspace C or
  embedded, Linux-kernel, Zephyr, RT-Thread, BSP, and bare-metal C, especially
  drivers, ISR/deferred paths, shared state, MMIO/DMA, board bring-up, and
  platform boundaries.
metadata:
  short-description: "Legible, context-correct host and embedded C"
---

# Write Legible Embedded C

**Correctness before shape; classify before styling.** Preserve behavior,
representation, ownership, and target constraints before applying legibility
preferences. Base is vendored under [references/base/](references/base/); no
second skill install.

| Layer | Where | When |
|-------|--------|------|
| **Quality floor** | [c-quality.md](references/c-quality.md) | Every branch, before Base or platform styling |
| **Base** | [references/base/](references/base/) (vendored [write-legible-c](https://github.com/7etsuo/write-legible-c), MIT / 7etsuo) | HOST and compatible ORCH legibility |
| **Platform overlay** | This file + other [references/](references/) | Embedded context, DRIVER, HOT/ISR, platform decisions |

**Constraint priority:** user intent, live tree, language dialect, tests,
ABI/wire/hardware contracts, execution context, safety, latency, and size ≥
Quality floor + Platform overlay ≥ Base legibility preferences. Base rules
are not evidence that a C operation is defined or target-correct. Mechanisms
come from the live tree and selected platform appendix. In particular, Base
“no `goto`” is house style only: Linux/BSP forward cleanup `goto` follows the
tree and [c-quality.md](references/c-quality.md) / L1, not Base §5 dogma.

---

## Quality floor — all branches

1. Read [c-quality.md](references/c-quality.md) before designing or reviewing C.
2. Record the local dialect/toolchain, external representations, ownership and
   cleanup, execution context, mutable sharing, and verification surface that
   the changed region actually depends on.
3. Resolve every Base or platform recommendation through those contracts.

**Done when:** every changed boundary and risky operation is covered by the
quality checklist, and no style rule changes behavior, ABI, representation,
resource lifetime, or target legality.

---

## Step 0 — Pick the branch

**Done when:** exactly one of **HOST** or **EMBEDDED**.

| Branch | Choose when |
|--------|-------------|
| **HOST** | Pure host userspace C; or Super SDK with no nested-kernel Active Git Root and no ISR/driver/HOT intent |
| **EMBEDDED** | Nested Kernel/BSP Active Git Root; Linux/Zephyr/RT-Thread/BSP drivers; ISR/Deferred; Path Class HOT/DRIVER; or user says embedded/kernel/RTOS |

Unclear ⇒ [classify-repo.md](references/classify-repo.md) defaults.

---

## Branch HOST — apply Base through the quality floor

1. Read [references/base/write-legible-c-SKILL.md](references/base/write-legible-c-SKILL.md) and [references/base/c-standard.md](references/base/c-standard.md) **§§1–14**.
2. Load disclosed Base files only when their branch fires (greenfield → [skeleton.md](references/base/skeleton.md); short/flat → [near-miss-map-eat.md](references/base/near-miss-map-eat.md); repo guidance → [repository-level.md](references/base/repository-level.md)).
3. Follow Base order and §14 end-to-end, treating incompatible Base rules as
   explicit deviations under the constraint priority above.

**Done when:** the quality checklist and Base §14 are applied to the final
diff, and each forced deviation is precise and locally visible where needed.

If mid-task you hit nested-kernel files, switch remaining work to **EMBEDDED**.

---

## Branch EMBEDDED — Hard Order

Do **not** apply Base **15/40** until Path Class is known.

### 1. Classify Active Git Root

Follow [classify-repo.md](references/classify-repo.md).

**Done when:** each touched file has Active Git Root, Repo Kind, platform if
known, and governing local rules/build files. Root beats keywords.

### 2. Assign Path Class and CTX

Follow [path-class.md](references/path-class.md).

**Done when:** each region has Path Class ∈ {ORCH, HOT, BOUND, DRIVER} and
CTX ∈ {ISR, Deferred, Thread, Init, N/A}. Defaults: Nested Kernel/BSP → DRIVER
(ISR/fast → HOT); Super SDK → ORCH. Mixed Path/CTX ⇒ **multiple** Classification
blocks (see Deliver).

### 3. Load rules

| Path Class | Load |
|------------|------|
| ORCH | Quality floor → Base [c-standard.md](references/base/c-standard.md) §4–8, §14 where compatible; near-miss file when code already short/flat |
| HOT | Quality floor → [hot-rules.md](references/hot-rules.md) → selected L1/concurrency refs when triggered; Base only where HOT does not override |
| BOUND | Quality floor → thin foreign adapter; Base adapter altitude only where compatible |
| DRIVER | Quality floor → host tree + **required** L1 when known: [linux](references/platforms/linux.md) / [zephyr](references/platforms/zephyr.md) / [rt-thread](references/platforms/rt-thread.md); Base supplement only |

For **HOT**, always read `c-quality.md` before `hot-rules.md`; then load the
selected L1 and `concurrency-memory.md` when their triggers fire.

Linux L1 is the deep profile; Zephyr/RT-Thread are thinner. Bare-metal /
unlisted RTOS: Path Class + HOT + the BSP’s own rules.

Cross-context, lock/mask, or alloc/release ⇒ read
[concurrency-memory.md](references/concurrency-memory.md) before editing.

**Done when:** the quality floor is loaded for every Path Class, the HOT order
is preserved, and needed L1 + concurrency refs are loaded.

### 4. Design then edit

**Draft Classification first** (short OK): template
[classify-repo.md](references/classify-repo.md). Then edit.

Point APIs and sync at **tree + L1**. Concurrency work ⇒ ban list + checklist
in concurrency-memory. Apply the quality floor to integer operations,
representation, ownership, cleanup, and public boundaries before reshaping code.

| Class | Edit rule |
|-------|-----------|
| ORCH | Base orchestrator/leaf/adapter + §14 |
| HOT | hot-rules H1–H6; split only concept / data / deferral boundary |
| BOUND | Thin foreign wrap only |
| DRIVER | Host style; Base supplements; L1 verification only |

Source comments: non-obvious hardware/context only, host style.

**Done when:** code matches each region’s class; draft record still matches code.

### 5. Verify

- **Classification gate:** complete per Deliver; incomplete ⇒ do not ship code-only.
- **Quality gate:** [c-quality.md](references/c-quality.md) checklist passes for
  every changed boundary and risky operation.
- HOT ⇒ H1–H6; missing H2/H6 record fields ⇒ those checks **fail**.
- Shared state / lock / alloc ⇒ concurrency ban list + checklist (all pass).
- ORCH/BOUND ⇒ Base §14 on those hunks.
- Platform ⇒ selected L1 verification section only.
- Build/tests when available; mark passed / failed / not run + reason.

**Done when:** Deliver gate passes; checklists answered against final diff;
named mechanisms cite tree (or *none — asked/blocked*).

---

## Deliver

### EMBEDDED — Classification record is mandatory

Ship the exact, minimal Classification record defined in
[classify-repo.md](references/classify-repo.md). One block covers each distinct
edited Path Class × CTX; HOT blocks satisfy the record's call-note contract.
An absent, blanket, or bloated record, or an unchecked/failed C quality
checklist, makes EMBEDDED delivery incomplete.

Also report behavior change, structure, quality/platform deviations, and
verification (checklists + build/tests status).

### HOST — Quality checklist and Base §14 are fail-closed

HOST delivery is **incomplete** unless both the
[C quality checklist](references/c-quality.md#pre-delivery-checklist) and Base
[§14](references/base/c-standard.md#14-pre-delivery-checklist) are applied
item-by-item to the final diff. Report each item as pass or a precise deviation;
a code-only or vague verification note fails this gate. Apply Base §9
`MODULE_TRY` only under its stated non-acquiring-orchestrator conditions. Also
report behavior change, material structure, tests/builds, and deviations.
Entering nested-kernel files switches delivery to EMBEDDED.

## Attribution

Base under `references/base/` is **write-legible-c** by **7etsuo**, **MIT**.
See [references/base/LICENSE](references/base/LICENSE), `NOTICE`, and `README.md`.
Overlay outside `base/` is team work.
