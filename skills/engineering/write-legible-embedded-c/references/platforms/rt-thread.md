# L1 appendix: RT-Thread kernel and BSP

Load for Nested Kernel/BSP platform **rt-thread**. Tree, BSP, and vendor HAL win.
Cross-context gates: [concurrency-memory.md](../concurrency-memory.md). HOT:
[hot-rules.md](../hot-rules.md). Not a generic ISR tutorial.

## Local contract

Know: active BSP, SCons/Kconfig/`rtconfig.py` owner, init path, vendor/HAL
boundary, toolchain. Do not invent board, compiler prefix, memory map, clocks,
or generated config.

## RT-Thread-specific ownership (keep)

| Concern | Required decision |
|---|---|
| Style / idiom | RT-Thread, BSP, component, vendor HAL conventions over Base |
| Object lifetime | Static `init`/`detach` vs dynamic `create`/`delete` pairs + failure unwind |
| Device framework | Registration, ops tables, open flags, callbacks, component boundaries |
| Init ordering | Board/component init phase and export-macro order; explicit deps |
| SCons / Kconfig | Source groups, includes, deps, generated config, packages, features |
| Vendor / exported API | BOUND; adapt locally, do not rewrite HAL for Base aesthetics |

## RT-Thread-specific mechanism pointers

Generic concurrency/HOT elsewhere. Choose **RTT/BSP** primitives from tree:

| Concern | Point at tree / choose |
|---|---|
| CTX labels | ISR, deferred worker/timer, thread, scheduler-locked section, init, PM |
| IRQ enter/leave | Arch/BSP required enter/leave and nesting; HOT on hard path |
| Sync / IPC | Interrupt lock, critical section, spinlock/SMP, atomic, sem/event/mbox/queue as shared CTXs require |
| Alloc | Static/pool on bounded paths; prove `rt_malloc`/object/pool legality + *quiesce* before detach/delete/free |
| MMIO | BSP/HAL register abstraction; width, order, clocks, resets, pinmux ownership |
| DMA | ownership, align, direction, cache clean/invalidate, completion handoff |

## Verification matrix

BSP SCons/IDE, config, toolchain, linker, runtime path.

| Diff includes | Verify when available |
|---|---|
| Kernel/driver/component/BSP C | Build active BSP/config; object selected and linked |
| Kconfig/SConscript/package | Regenerate config if required; build with feature on |
| Startup/linker/clock/pin/map | Map/image + board bring-up check |
| Shared behavior | Narrowest utest/sample/shell/sim/project test |
| Runtime | Documented board path; report unavailable hw/toolchain |

**Done when:** relevant rows passed, deferred with reason, or unavailable.
Generic host build ≠ RT-Thread BSP image proof.
