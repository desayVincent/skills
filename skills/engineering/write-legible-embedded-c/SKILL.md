---
name: write-legible-embedded-c
description: >
  Embedded and kernel C for Linux/BSP, Zephyr, RT-Thread, and bare-metal
  firmware. Use when creating, modifying, reviewing, or debugging C drivers,
  ISR or deferred paths, multithreaded shared state, lock-held code, malloc/free
  ownership, MMIO/DMA, board bring-up, or SDK boundaries; also when the user
  invokes /write-legible-embedded-c.
metadata:
  short-description: "Linux, Zephyr, RT-Thread + BSP C"
---

# Write Legible Embedded C

**One skill** for the team. It owns the C-legibility rules for the session and
ships the Base Standard, so a second skill install is unnecessary.

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
the code's real kernel, BSP, RTOS, or interface constraints.

---

## Step 0 — Pick the branch

**Done when:** you have chosen exactly one branch: **HOST** or **EMBEDDED**.

| Branch | Choose when |
|--------|-------------|
| **HOST** | Pure host userspace C; or Super SDK code with no nested-kernel Active Git Root and no ISR/driver/HOT intent |
| **EMBEDDED** | Nested Kernel/BSP Active Git Root; Linux/Zephyr/RT-Thread/BSP drivers; ISR/Deferred; Path Class HOT/DRIVER; or user says embedded/kernel/RTOS |

If unsure: resolve Active Git Root ([classify-repo.md](references/classify-repo.md)). Nested Kernel/BSP → **EMBEDDED**. Otherwise default **HOST**, unless the user asked for interrupt/driver work.

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
and synchronization or MMIO mechanism identified. Defaults: Nested Kernel/BSP
→ DRIVER (ISR/fast → HOT); Super SDK → ORCH.

### 3. Load rules

| Path Class | Load |
|------------|------|
| ORCH | Base ([c-standard.md](references/base/c-standard.md) §4–8, §14–16) |
| HOT | [hot-rules.md](references/hot-rules.md) **first**; Base only where HOT does not override |
| BOUND | Base adapter altitude; thin foreign wrap only |
| DRIVER | Host style first; Base supplement; [platforms/](references/platforms/) if known |

Load exactly the applicable platform appendix before designing the change:

| Platform | Appendix | Required for |
|---|---|---|
| Linux | [platforms/linux.md](references/platforms/linux.md) | Kernel/BSP drivers, Kconfig/Kbuild, Device Tree, MMIO/DMA, lifecycle, verification |
| Zephyr | [platforms/zephyr.md](references/platforms/zephyr.md) | Drivers, Kconfig/CMake, devicetree/bindings, device model, ISR/work, verification |
| RT-Thread | [platforms/rt-thread.md](references/platforms/rt-thread.md) | BSP/drivers, SCons/Kconfig, device/component lifecycle, ISR/IPC, verification |

When touched code crosses execution contexts, shares mutable state, holds a
lock or interrupt/scheduler mask, or allocates/releases memory, read
[concurrency-memory.md](references/concurrency-memory.md) before editing.

For bare-metal or an unlisted RTOS, apply Path Class + HOT rules and load the
active BSP's own build, HAL, startup, linker, interrupt, and memory-map rules.

**Done when:** the override set is explicit (HOT ⇒ H1–H6), and any applicable
platform and concurrency/memory reference has been read.

### 4. Design then edit

Map the touched code before reshaping it: owner, entry path, execution context,
state or resource lifetime, lock/atomic/MMIO boundary, held-lock calls,
allocation and teardown path, and externally visible ABI or binding. Keep that
map consistent with the active tree's nearby code.

ORCH regions use the full Base orchestrator/leaf/adapter + name test. HOT code
keeps a tight critical path; split only at a real concept, data boundary, or
deferral boundary, rather than to satisfy Base 15/40 targets. Add a source
comment only where a non-obvious hardware or context constraint needs to stay
visible to the next editor.

**Done when:** every touched function matches the active class.

### 5. Verify

- Classification recorded (Root, Kind, Path, CTX, and governing tree rules).
- HOT ⇒ H1–H6 checklist in [hot-rules.md](references/hot-rules.md).
- Shared state, lock, or allocation work ⇒ the completion checklist in
  [concurrency-memory.md](references/concurrency-memory.md).
- ORCH/BOUND ⇒ Base §14 on those hunks.
- Platform work ⇒ the selected appendix's verification rows relevant to the
  diff; an unlisted platform ⇒ the active BSP's documented equivalent checks.
- Run the project-provided build/tests when available. Report every applicable
  check as passed, failed, or not run with the precise reason.

**Done when:** all applicable checklist items are answered against the final
diff; unverified hardware, configuration, or command paths are named rather
than assumed.

---

## Deliver

Report: branch (HOST|EMBEDDED); if EMBEDDED, Active Git Root, Repo Kind, Path
Class, CTX, and governing constraints; behavior change; structure; deviations;
verification.

## Attribution

Base text under `references/base/` is **write-legible-c** by **7etsuo**, **MIT**. See [references/base/LICENSE](references/base/LICENSE) and `NOTICE` and `README.md` in this skill folder. Overlay rules outside `base/` are team work.
