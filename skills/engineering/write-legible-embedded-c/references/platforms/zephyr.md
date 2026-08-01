# L1 appendix: Zephyr kernel and BSP

Load for a Nested Kernel/BSP tree with platform **zephyr** before designing or
reviewing a Zephyr driver, board/SoC port, Kconfig/CMake, devicetree binding,
ISR/workqueue, MMIO, DMA, or power-management change. The active Zephyr tree
and subsystem documentation remain authoritative.

## Establish the local contract

Read the nearest repository guidance, touched public headers and callers,
owning `Kconfig` and `CMakeLists.txt`, matching devicetree binding, and a nearby
in-tree driver or board exemplar. Resolve the actual board, SoC, shield, module,
and configuration used by the project.

**Done when:** the build owner, Kconfig symbol, devicetree/binding boundary,
device initialization path, and known board/configuration are identified. Do
not invent a board, runner, toolchain, or west workspace layout.

## Preserve Zephyr ownership and interfaces

| Concern | Required decision |
|---|---|
| Style and local idiom | Zephyr coding style, subsystem conventions, generated interfaces, and nearby code win over Base formatting or decomposition rules. |
| Device model | Preserve the driver's API/config/data ownership, device-definition macro pattern, initialization dependencies, and readiness checks used by the subsystem. |
| Kconfig and CMake | Keep symbol dependencies/defaults, source inclusion, generated configuration, and feature coverage consistent. |
| Devicetree and bindings | Treat compatible strings, properties, cells, bus relationships, and binding schemas as interfaces. Keep DTS, YAML bindings, and driver extraction macros aligned. |
| Resource lifetime and PM | Match the subsystem's static device lifetime, runtime data ownership, init level/priority, and device power-management callbacks. |
| Userspace or syscall API | Classify generated or userspace-visible boundaries as BOUND; preserve validation, permissions, and generated wrapper conventions. |

## Context, concurrency, and I/O

Apply the cross-platform [concurrency and memory contract](../concurrency-memory.md),
then make these Zephyr-specific decisions:

| Concern | Required decision |
|---|---|
| Execution context | Identify ISR, cooperative/preemptible thread, system/custom workqueue, timer callback, init, and PM paths. Prove sleepability and API legality from that context. |
| ISR and deferred work | Apply [HOT H1–H6](../hot-rules.md). Keep ISR work bounded and use the tree's documented `k_work`, thread, or other deferred mechanism when work may sleep or grow. |
| Locking and shared state | Select `k_spinlock`, mutex/semaphore, atomic, IRQ lock, or a documented lock-free rule from the actual ISR/thread/SMP sharing pattern. Preserve lock ordering and timeout semantics; keep blocking APIs outside spinlocked and interrupt-locked regions. |
| Allocation and release | Prefer static objects, slabs, or fixed pools for ISR and bounded paths. Prove `k_malloc`, `k_heap`, slab, and release API legality from the active Zephyr version and configuration; `K_NO_WAIT` expresses timeout behavior rather than blanket ISR safety or bounded allocator latency. Quiesce ISR, work, timers, DMA, callbacks, and device users before storage is released. |
| MMIO and registers | Preserve the tree's `sys_read*`/`sys_write*`, device MMIO, bus, or subsystem abstraction, including width, endianness, ordering, and generated addresses. |
| DMA and cache visibility | Name buffer ownership, alignment, direction, mapping/cache operation, and completion handoff required by the SoC and driver contract. |

## Verification matrix

Use the project's existing west/CMake invocation, known board, configuration,
toolchain, and test selection.

| Diff includes | Verify when available |
|---|---|
| Driver, kernel, or BSP C | Build the affected application/sample/test for the known board and configuration. |
| Kconfig or CMake | Build with the changed symbol both enabled and, when meaningful, disabled; inspect source-selection and dependency failures. |
| Devicetree or binding | Build the affected board/overlay and inspect generated devicetree diagnostics; run the tree's binding/schema checks when provided. |
| Shared subsystem behavior | Run the narrowest relevant Twister test, ztest suite, sample, or project test target. |
| Runtime or hardware behavior | Exercise the documented board, simulator, or emulator path. Report unavailable runner/hardware/configuration and the remaining risk. |

**Done when:** every relevant row is passed, deliberately deferred with a
reason, or reported unavailable. A host-only compile does not prove a Zephyr
board configuration.
