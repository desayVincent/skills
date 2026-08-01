---
name: write-legible-embedded-c
description: >
  Write and review legible C for host userspace and embedded: Super SDK trees,
  nested Linux/Zephyr/RT-Thread BSP git repos, BSP, ISR, drivers, threads, and
  portable C APIs. Use for .c/.h, kernel or RTOS drivers, interrupt or hot-path
  code, team C SDKs, and general C11 legibility. Also /write-legible-embedded-c.
  Applies bundled Base Standard (write-legible-c) for ORCH/host code and Overlay
  Path Class rules for embedded/HOT. Do not use for C++ or non-C tasks.
metadata:
  short-description: "Legible C (host + embedded/ISR)"
---

# Write Legible Embedded C

**One skill** for the team. It always owns the session; it **never** requires a second skill install.

Internally it uses two layers:

| Layer | Where | When |
|-------|--------|------|
| **Base** | [references/base/](references/base/) (vendored [write-legible-c](https://github.com/7etsuo/write-legible-c), MIT / 7etsuo) | Host userspace, Super SDK ORCH, any Path Class that does not override |
| **Overlay** | This file + [references/](references/) (except `base/`) | Nested kernel/BSP, DRIVER, HOT/ISR, platform appendices |

**Constraint Priority:** platform / latency / size / frozen API ≥ Overlay ≥ Base.

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

**Done when:** each touched file has Active Git Root, Repo Kind (Super SDK vs Nested Kernel/BSP), and platform if known. Root beats keywords; on conflict ask or take Root.

### 2. Assign Path Class and Execution Context

Follow [references/path-class.md](references/path-class.md).

**Done when:** each region has Path Class ∈ {ORCH, HOT, BOUND, DRIVER} and CTX ∈ {ISR, Deferred, Thread, Init} (or N/A). Defaults: Nested Kernel/BSP → DRIVER (ISR/fast → HOT); Super SDK → ORCH.

### 3. Load rules

| Path Class | Load |
|------------|------|
| ORCH | Base ([c-standard.md](references/base/c-standard.md) §4–8, §14–16) |
| HOT | [hot-rules.md](references/hot-rules.md) **first**; Base only where HOT does not override |
| BOUND | Base adapter altitude; thin foreign wrap only |
| DRIVER | Host style first; Base supplement; [platforms/](references/platforms/) if known |

**Done when:** override set is explicit (HOT ⇒ H1–H6).

### 4. Design then edit

Mark HOT/ISR: `/* PATH: HOT; CTX: ISR */`.  
ORCH regions: full Base orchestrator/leaf/adapter + name test.  
HOT: **do not** split only to satisfy Base 15/40.

**Done when:** every touched function matches the active class.

### 5. Verify

- Classification recorded (Root, Kind, Path, CTX).
- HOT ⇒ H1–H6 checklist in [hot-rules.md](references/hot-rules.md).
- ORCH/BOUND ⇒ Base §14 on those hunks.
- Build/tests if available; no false compliance claims.

**Done when:** all applicable checklist items answered.

---

## Deliver

Report: branch (HOST|EMBEDDED); if EMBEDDED, Repo Kind + Path Class + CTX; behavior change; structure; deviations; verification.

## Attribution

Base text under `references/base/` is **write-legible-c** by **7etsuo**, **MIT**. See [references/base/LICENSE](references/base/LICENSE) and `NOTICE` and `README.md` in this skill folder. Overlay rules outside `base/` are team work.
