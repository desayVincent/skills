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

**Classify before styling.** One skill covers host userspace and embedded trees.
Base is vendored under [references/base/](references/base/); no second skill install.

Internally it uses two layers:

| Layer | Where | When |
|-------|--------|------|
| **Base** | [references/base/](references/base/) (vendored [write-legible-c](https://github.com/7etsuo/write-legible-c), MIT / 7etsuo) | Host userspace, Super SDK ORCH, any Path Class that does not override |
| **Overlay** | This file + [references/](references/) (except `base/`) | Nested kernel/BSP, DRIVER, HOT/ISR, platform appendices |

**Constraint priority:** governing tree and subsystem rules, ABI/binding or
generated-source requirements, execution-context/latency/safety/size limits ≥
Overlay ≥ Base.

**Classify before styling.** The active tree and execution context decide which
rules apply. Base rules improve legibility only where they do not conflict with
the code's real kernel, BSP, RTOS, or interface constraints. The live tree is the
external single source of truth; this skill points at it and requires the agent
to consult it — never invent a “common” locking, allocator, or ISR pattern in
place of the tree’s actual contract (**prior contamination** defence).

---

## Step 0 — Pick the branch

**Done when:** you have chosen exactly one branch: **HOST** or **EMBEDDED**.

| Branch | Choose when |
|--------|-------------|
| **HOST** | Pure host userspace C; or Super SDK code with no nested-kernel Active Git Root and no ISR/driver/HOT intent |
| **EMBEDDED** | Nested Kernel/BSP Active Git Root; Linux/Zephyr/RT-Thread/BSP drivers; ISR/Deferred; Path Class HOT/DRIVER; or user says embedded/kernel/RTOS |

If the branch is unclear, open [classify-repo.md](references/classify-repo.md) and use its defaults.

---

## Branch HOST — call Base only

Run the Base procedure as if `write-legible-c` were invoked, using **this skill’s copies** (do not depend on a separate installed skill):

1. Read [references/base/write-legible-c-SKILL.md](references/base/write-legible-c-SKILL.md) and [references/base/c-standard.md](references/base/c-standard.md) (normative checklist).
2. Follow Base “Work in this order” and Base §14 pre-delivery checklist end-to-end.
3. Deliver as Base specifies.

**Done when:** Base §14 is fully applied to the final diff (or deviations commented at site).

No Path Class / HOT rules on this branch unless mid-task you discover nested-kernel files—then switch the remaining files to **EMBEDDED**.

---

## Branch EMBEDDED — Hard Order (then Base where allowed)

Do not apply Base **15/40 line budgets** until Path Class is known.

### 1. Classify Active Git Root

Follow [references/classify-repo.md](references/classify-repo.md).

**Done when:** each touched file has Active Git Root, Repo Kind (Super SDK vs
Nested Kernel/BSP), platform if known, and the local rules/build files that
govern it. Root beats keywords; on conflict ask or take Root.

### 2. Assign Path Class and Execution Context

Follow [references/path-class.md](references/path-class.md).

**Done when:** each region has Path Class ∈ {ORCH, HOT, BOUND, DRIVER} and
CTX ∈ {ISR, Deferred, Thread, Init} (or N/A), with its entry path, ownership,
and synchronization or MMIO mechanism **named** and tied to a header or nearby
in-tree precedent that establishes the required pattern. Defaults: Nested
Kernel/BSP → DRIVER (ISR/fast → HOT); Super SDK → ORCH. “I judged it appropriate”
is not enough; cite the local source of the mechanism.

### 3. Load rules

| Path Class | Load |
|------------|------|
| ORCH | Base ([c-standard.md](references/base/c-standard.md) §4–8, §14–16) |
| HOT | [hot-rules.md](references/hot-rules.md) **first**; Base only where HOT does not override |
| BOUND | Base adapter altitude; thin foreign wrap only |
| DRIVER | Host style first; Base supplement; **required** platform appendix when known: [platforms/linux.md](references/platforms/linux.md), [platforms/zephyr.md](references/platforms/zephyr.md), or [platforms/rt-thread.md](references/platforms/rt-thread.md) |

Linux is the deep L1 profile; Zephyr and RT-Thread appendices are thinner
conflict/decision tables unless expanded later. Bare-metal or unlisted RTOS:
Path Class + HOT, plus the active BSP's own build/HAL/startup rules.

When code crosses contexts, shares mutable state, holds a lock or
interrupt/scheduler mask, or allocates/releases memory, read
[concurrency-memory.md](references/concurrency-memory.md) before editing.

**Done when:** the override set is explicit (HOT ⇒ H1–H6), and any applicable
platform and concurrency/memory reference has been read.

### 4. Design then edit

Map the touched code before reshaping it: owner, entry path, execution context,
state or resource lifetime, lock/atomic/MMIO boundary, held-lock calls,
allocation and teardown path, and externally visible ABI or binding. Keep that
map consistent with the active tree's nearby code. Prefer *context-legal*,
*bounded*, and *quiesce* decisions taken from the tree over pretrained “common”
patterns.

ORCH regions use the full Base orchestrator/leaf/adapter + name test. HOT code
keeps a tight critical path; split only at a real concept, data boundary, or
deferral boundary, rather than to satisfy Base 15/40 targets. Add a source
comment only where a non-obvious hardware or context constraint needs to stay
visible to the next editor.

**Done when:** every touched function matches the active class.

### 5. Verify

- Fill the **Classification record** in
  [classify-repo.md](references/classify-repo.md) (single home for Root, Kind,
  Platform, Path Class, CTX, governing rules).
- HOT ⇒ H1–H6 checklist in [hot-rules.md](references/hot-rules.md).
- Shared state, lock, or allocation work ⇒ checklist in
  [concurrency-memory.md](references/concurrency-memory.md).
- ORCH/BOUND ⇒ Base §14 on those hunks.
- Platform work ⇒ **only** the selected L1 appendix's verification section
  (do not restate those rows here).
- Run project build/tests when available; mark each check passed / failed /
  not run with reason.

**Done when:** the Classification record is complete for every touched region,
every applicable checklist item is answered against the final diff, and every
named lock/atomic/allocator/MMIO mechanism cites the header or nearby precedent
that establishes it.

---

## Deliver

Include the filled Classification record from
[classify-repo.md](references/classify-repo.md). Then: behavior change;
structure; deviations; verification.

## Attribution

Base text under `references/base/` is **write-legible-c** by **7etsuo**, **MIT**. See [references/base/LICENSE](references/base/LICENSE) and `NOTICE` and `README.md` in this skill folder. Overlay rules outside `base/` are team work.
