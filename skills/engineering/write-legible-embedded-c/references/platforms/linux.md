# L1 appendix: Linux kernel and BSP

Load for a Nested Kernel/BSP tree with platform **linux** before designing or
reviewing a Linux driver, BSP, Kconfig/Kbuild, Device Tree, MMIO, DMA, or
power-management change. This is a decision checklist, not a replacement for
the active tree's subsystem documentation.

## Establish the local contract

Read the nearest applicable repository guidance, the touched public headers,
direct callers, and the Kconfig/Kbuild/Makefile that owns the code. For a board
or Device Tree change, also read the matching binding and nearby board example.
Use an in-tree subsystem exemplar when choosing an API or cleanup shape.

**Done when:** the active configuration symbol, build owner, public or binding
boundary, and a nearby in-tree precedent are known. Do not infer an `ARCH`,
cross-toolchain, kernel configuration, or supported kernel-version range when
the tree does not state one.

## Preserve Linux ownership and interfaces

| Concern | Required decision |
|---|---|
| Style and local idiom | Linux coding style, subsystem rules, and nearby code win over Base formatting or decomposition rules. |
| Language, types, and annotations | Use the Kbuild-selected language mode and preserve kernel types and annotations such as `u32`, `__iomem`, and `__user`. Keep existing kernel wrappers and headers at their boundary rather than forcing Base C11 or userspace conventions. |
| Resource lifetime | Pair each acquired resource with its owner and release path. Use existing `devm_*` or manual ownership patterns only when their lifetime matches the device and error/unbind paths. |
| Error unwind | A single forward cleanup `goto` is appropriate when it keeps multi-resource unwind local and visible. Prefer the subsystem's established label names and ordering. |
| Kconfig/Kbuild | Preserve symbol dependencies, `select`/`depends on` intent, object linkage, and build coverage for the changed feature. |
| Device Tree and bindings | Treat compatible strings, property names, required properties, and schemas as interfaces. Update bindings and validation when a DT-facing contract changes. |
| uAPI and exported interfaces | Classify as BOUND. Preserve layout, numbering, compatibility, and userspace behavior unless an explicit ABI change is approved. |

## Context, concurrency, and I/O

Apply the cross-platform [concurrency and memory contract](../concurrency-memory.md),
then make these Linux-specific decisions:

| Concern | Required decision |
|---|---|
| Execution context | Identify hard IRQ, threaded IRQ, softirq/deferred, workqueue, process, probe/remove, and PM paths. Prove sleepability and lock legality from that context. |
| Locking and shared state | Select mutex, spinlock, raw spinlock, IRQ/BH variant, atomic, `READ_ONCE`/`WRITE_ONCE`, and barriers from the actual sharing contexts and subsystem pattern. Preserve lock ordering. Keep may-sleep operations outside spinlocked, IRQ-disabled, preemption-disabled, and other atomic regions. |
| Allocation and release | Use kernel allocation and size helpers rather than libc `malloc/free`. Match allocation flags to the current context: use sleepable allocation in sleepable context and atomic allocation only when the atomic path cannot be redesigned or preallocated. Use overflow-safe array/structure sizing. Quiesce IRQ, work, timers, DMA, callbacks, and references before backing memory disappears; `devm_*` ownership does not itself quiesce asynchronous users. |
| MMIO and register access | Preserve `__iomem` types, access width, endianness, ordering, and the existing `read*`/`write*`, `ioread*`/`iowrite*`, or `regmap` abstraction. |
| DMA and cache visibility | Name buffer ownership, DMA direction, mapping lifetime, and the barrier or sync operation required by the device contract. Reuse established subsystem helpers. |
| HOT/IRQ work | Apply [HOT H1–H6](../hot-rules.md). Keep the hard path to acknowledgement, bounded state capture, and justified deferral. |

## Verification matrix

Run the narrowest existing command that proves the changed contract; use the
tree's documented `ARCH`, output directory, toolchain, and configuration.

| Diff includes | Verify when available |
|---|---|
| C driver or core code | Build the changed object, module, or configured kernel target; include the tree's warnings/modpost path when that target normally runs it. |
| Kconfig/Kbuild/Makefile | Build a configuration that enables the changed symbol and inspect dependency or linkage failures. |
| Device Tree or binding | Run the tree's applicable `dt_binding_check` and/or `dtbs_check` target for the affected architecture and board. |
| Source formatting or API use | Run `scripts/checkpatch.pl` against the actual diff when it is present in the tree; distinguish style findings from subsystem-required deviations. |
| Runtime or hardware behavior | Exercise the documented board or emulator path. If hardware, firmware, or configuration is unavailable, state the missing evidence and the remaining risk. |

**Done when:** every row relevant to the final diff is passed, deliberately
deferred with a reason, or reported as unavailable. Never report a generic
host build as proof of a target-kernel or board configuration.
