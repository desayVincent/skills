---
name: write-legible-embedded-c
description: >
  Legible C for host userspace and for Linux/BSP, Zephyr, RT-Thread, or
  bare-metal work. Use when writing or reviewing host C, Super-SDK middleware,
  drivers, ISR or deferred paths, shared state under locks, MMIO/DMA, board
  bring-up, or SDK boundaries; also /write-legible-embedded-c.
metadata:
  short-description: "Host + Linux/Zephyr/RTT C legibility"
---

# Write Legible Embedded C

**Classify before styling.** One skill for host userspace and embedded trees.
Base is vendored under [references/base/](references/base/); no second skill install.

| Layer | Where | When |
|-------|--------|------|
| **Base** | [references/base/](references/base/) (vendored [write-legible-c](https://github.com/7etsuo/write-legible-c), MIT / 7etsuo) | HOST; Super SDK ORCH; Path Class that does not override |
| **Overlay** | This file + [references/](references/) (except `base/`) | Nested kernel/BSP, DRIVER, HOT/ISR, platform appendices |

**Constraint priority:** tree / subsystem / ABI / latency / safety / size ≥
Overlay ≥ Base. Mechanisms come from the **live tree** (and L1 appendix when
known), not from pretrained “common” patterns — see
[concurrency-memory.md](references/concurrency-memory.md) ban list (PC1–PC8).

---

## Step 0 — Pick the branch

**Done when:** exactly one of **HOST** or **EMBEDDED**.

| Branch | Choose when |
|--------|-------------|
| **HOST** | Pure host userspace C; or Super SDK with no nested-kernel Active Git Root and no ISR/driver/HOT intent |
| **EMBEDDED** | Nested Kernel/BSP Active Git Root; Linux/Zephyr/RT-Thread/BSP drivers; ISR/Deferred; Path Class HOT/DRIVER; or user says embedded/kernel/RTOS |

Unclear ⇒ [classify-repo.md](references/classify-repo.md) defaults.

---

## Branch HOST — call Base only

1. Read [references/base/write-legible-c-SKILL.md](references/base/write-legible-c-SKILL.md) and [references/base/c-standard.md](references/base/c-standard.md) **§§1–14**.
2. Load disclosed Base files only when their branch fires (greenfield → [skeleton.md](references/base/skeleton.md); short/flat → [near-miss-map-eat.md](references/base/near-miss-map-eat.md); repo guidance → [repository-level.md](references/base/repository-level.md)).
3. Follow Base order and §14 end-to-end; deliver per **Deliver → HOST** below.

**Done when:** Base §14 is applied to the final diff (or each forced deviation has a source-site comment), and HOST Deliver gates pass.

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
| ORCH | Base [c-standard.md](references/base/c-standard.md) §4–8, §14; near-miss file when code already short/flat |
| HOT | [hot-rules.md](references/hot-rules.md) **first**; Base only where HOT does not override |
| BOUND | Base adapter altitude; thin foreign wrap only |
| DRIVER | Host tree style first; Base supplement; **required** L1 when known: [linux](references/platforms/linux.md) / [zephyr](references/platforms/zephyr.md) / [rt-thread](references/platforms/rt-thread.md) |

Linux L1 is the deep profile; Zephyr/RT-Thread are thinner. Bare-metal /
unlisted RTOS: Path Class + HOT + the BSP’s own rules.

Cross-context, lock/mask, or alloc/release ⇒ read
[concurrency-memory.md](references/concurrency-memory.md) before editing.

**Done when:** override set explicit (HOT ⇒ H1–H6); needed L1 + concurrency
refs loaded.

### 4. Design then edit

**Draft Classification first** (short OK): template
[classify-repo.md](references/classify-repo.md). Then edit.

Point APIs and sync at **tree + L1**; do not invent. Concurrency work ⇒ ban
list + checklist in concurrency-memory.

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

No complete Classification record ⇒ EMBEDDED delivery **incomplete**, even if
the diff looks correct. Same message as the code is fine; omission is not.

Template: [classify-repo.md](references/classify-repo.md).

**Required fields every region block:** Branch, Active Git Root, Repo Kind,
Platform, Path Class, CTX, Governing rules. Keyword notes optional.

**Region scope (minimal):** only **edited** entry paths / coherent hunks. One
block per distinct **Path Class × CTX** in the diff — not per function, and
**not** for unchanged helpers you only call. Typical ISR + deferred + thread
edit ⇒ about **three** blocks. Extra pure-noise blocks (same Path×CTX, or
untouched callees) should be **trimmed**. Details:
[classify-repo.md](references/classify-repo.md).

**Multi-region gate:** more than one Path Class or CTX among edited regions ⇒
**separate blocks**. One blanket `DRIVER`/`Thread` for mixed IRQ and process
code **fails**.

**HOT notes:** Path Class **HOT** ⇒ `HOT call notes` is either `none` or
`call site → why not deferred / latency bound source` lines. Omitted ⇒ gate
and H2/H6 **fail**. Non-HOT blocks: **omit** the field (no `n/a` filler).

**Order:** draft record → edit → re-check record → ship record + code together.

Also: behavior change; structure; deviations; verification (checklists +
build/tests status).

### HOST — Base §14 is fail-closed

HOST delivery is **incomplete** unless [c-standard.md](references/base/c-standard.md)
**§14** is applied to the final diff item-by-item (pass / deviation with
**source-site** comment). A code-only reply or a vague “looks clean” note
**fails** this gate. Prefer an explicit §14 checklist in the delivery message
(same pattern as Base skill deliver).

**`MODULE_TRY` (Base §9):** when the module defines a status enum (success = 0)
and you add or edit a **non-acquiring** orchestrator (no `_create` / `_init` /
`_open` / `alloc` / other acquire in that function body), define a module
`FOO_TRY` (or `MODULE_TRY`) beside the status enum and use it for fallible
propagation in that orchestrator — see Base §9 and
[skeleton.md](references/base/skeleton.md). Do **not** invent a second
status-propagation protocol. Do **not** require TRY on acquiring functions
(explicit check + release) or on EMBEDDED HOT/IRQ paths (Overlay / tree win).

Also report: behavior change; structure (orchestrator / leaf / adapter); §14
verification; deviations. Classification optional unless you entered
nested-kernel files (then finish under EMBEDDED).

## Attribution

Base under `references/base/` is **write-legible-c** by **7etsuo**, **MIT**.
See [references/base/LICENSE](references/base/LICENSE), `NOTICE`, and `README.md`.
Overlay outside `base/` is team work.
