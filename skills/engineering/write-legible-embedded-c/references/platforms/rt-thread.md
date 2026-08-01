# L1 appendix: RT-Thread kernel and BSP

Load for a Nested Kernel/BSP tree with platform **rt-thread** before designing
or reviewing an RT-Thread driver, BSP/board port, SCons/Kconfig, component,
interrupt, IPC, MMIO, DMA, startup, or power-management change. The active
RT-Thread tree, BSP, and vendor HAL remain authoritative.

## Establish the local contract

Read the nearest repository guidance, touched headers and callers, the active
BSP's `Kconfig`, `SConstruct`/`SConscript`, `rtconfig.py`, board startup files,
and a nearby in-tree driver or BSP exemplar. Identify whether `rtconfig.h` or
other files are generated and which toolchain/profile owns them.

**Done when:** the active BSP, build owner, configuration symbol, init path,
vendor/HAL boundary, and documented toolchain are known. Do not infer a board,
compiler prefix, memory map, clock tree, or generated configuration.

## Preserve RT-Thread ownership and interfaces

| Concern | Required decision |
|---|---|
| Style and local idiom | RT-Thread, BSP, component, and vendor HAL conventions win over Base formatting or decomposition rules. |
| Object lifetime | Preserve static `init`/`detach` versus dynamic `create`/`delete` ownership pairs and their failure/unwind paths. |
| Device framework | Keep device registration, operations tables, open flags, callbacks, and component boundaries compatible with existing users. |
| Init ordering | Preserve the tree's board/component initialization phase and export-macro ordering; make dependencies explicit rather than shifting init priority casually. |
| SCons and Kconfig | Keep source groups, include paths, dependency conditions, generated config, packages, and feature selection aligned. |
| Vendor or exported API | Classify HAL, package, component, and frozen application-facing boundaries as BOUND; adapt locally rather than rewriting foreign code for Base aesthetics. |

## Context, concurrency, and I/O

Apply the cross-platform [concurrency and memory contract](../concurrency-memory.md),
then make these RT-Thread-specific decisions:

| Concern | Required decision |
|---|---|
| Execution context | Identify ISR, deferred worker/timer, thread, scheduler-locked critical section, init, and PM paths. Prove API legality and wait behavior from that context. |
| Interrupt entry/exit | Preserve architecture/BSP-required interrupt enter/leave and nesting semantics. Apply [HOT H1–H6](../hot-rules.md) to the hard path. |
| Locking, scheduling, and IPC | Select the interrupt lock, critical section, spinlock/SMP primitive, atomic, semaphore/event/mailbox/queue, or ownership rule from the actual sharing contexts. Treat scheduler locking as scheduling control; add the ISR/SMP protection required by the active port. Preserve timeout and lock-order semantics. |
| Allocation and release | Preserve static `init/detach` and dynamic `create/delete` ownership. Prefer static objects or fixed pools for ISR and bounded paths. Prove `rt_malloc/rt_free`, object creation/deletion, and pool API legality from the active RT-Thread version, configuration, and port. Quiesce interrupts, timers, threads, IPC waiters, DMA, callbacks, and device users before detach, delete, or free. |
| MMIO and registers | Reuse the BSP/HAL register abstraction and preserve access width, ordering, volatile hardware semantics, clocks, resets, and pinmux ownership. |
| DMA and cache visibility | Name buffer ownership, alignment, direction, cache clean/invalidate operation, and completion handoff required by the BSP/HAL contract. |

## Verification matrix

Use the active BSP's documented SCons/IDE generation command, configuration,
toolchain, linker script, and runtime path.

| Diff includes | Verify when available |
|---|---|
| Kernel, driver, component, or BSP C | Build the active BSP/configuration and confirm the changed object is selected and linked. |
| Kconfig, SConscript, or package metadata | Regenerate configuration where the project requires it, then build with the changed feature enabled and inspect dependency/source-selection failures. |
| Startup, linker, clock, pin, or memory map | Inspect the generated map/image and run the board's documented bring-up check. |
| Shared component behavior | Run the narrowest relevant utest, sample, shell command, simulator, or project-specific test. |
| Runtime or hardware behavior | Exercise the documented board path and capture the relevant console or trace evidence. Report unavailable hardware/toolchain/configuration and the remaining risk. |

**Done when:** every relevant row is passed, deliberately deferred with a
reason, or reported unavailable. A generic host build does not prove an
RT-Thread BSP image.
