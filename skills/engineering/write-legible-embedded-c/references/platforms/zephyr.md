# L1 appendix: Zephyr kernel and BSP

Load for Nested Kernel/BSP platform **zephyr**. Tree + subsystem docs win.
Cross-context gates: [concurrency-memory.md](../concurrency-memory.md). HOT:
[hot-rules.md](../hot-rules.md). Not a generic ISR tutorial.

## Local contract

Know: `Kconfig` / `CMakeLists.txt` owner, DT/binding boundary, init path,
board/SoC/shield/module/config. Do not invent board, runner, toolchain, or west layout.

## Zephyr-specific ownership (keep)

| Concern | Required decision |
|---|---|
| Style / idiom | Zephyr style, subsystem conventions, generated interfaces, nearby code over Base |
| Device model | API/config/data ownership, device-definition macros, init deps, readiness checks |
| Kconfig / CMake | Symbol deps/defaults, source inclusion, generated config, feature coverage |
| DT / bindings | Compatible, properties, cells, buses, schemas; DTS + YAML + extract macros aligned |
| Lifetime / PM | Static device lifetime, runtime data, init level/priority, PM callbacks |
| Userspace / syscall | BOUND; preserve validation, permissions, generated wrappers |

## Zephyr-specific mechanism pointers

Generic concurrency/HOT elsewhere. Choose **Zephyr** primitives from tree:

| Concern | Point at tree / choose |
|---|---|
| CTX labels | ISR, coop/preempt thread, system/custom workqueue, timer, init, PM |
| Defer | `k_work` / thread / documented deferred API when work may sleep or grow |
| Sync | `k_spinlock`, mutex/sem, atomic, IRQ lock, or documented lock-free; order + timeouts |
| Alloc | Prefer static/slab/pool on bounded paths; prove `k_malloc`/`k_heap`/slab legality + *quiesce* |
| MMIO | `sys_read*`/`sys_write*`, device/bus abstraction, width/endian/order, generated addresses |
| DMA | ownership, align, direction, cache op, completion handoff per SoC/driver |

## Verification matrix

Project west/CMake, known board, config, toolchain, tests.

| Diff includes | Verify when available |
|---|---|
| Driver/kernel/BSP C | Build affected app/sample/test for known board/config |
| Kconfig/CMake | Build with symbol on (and off when meaningful) |
| DT/binding | Board/overlay build + binding/schema checks if provided |
| Shared behavior | Narrowest Twister/ztest/sample/project test |
| Runtime | Board/sim/emulator path; report unavailable runner/hw |

**Done when:** relevant rows passed, deferred with reason, or unavailable.
Host-only compile ≠ Zephyr board proof.
