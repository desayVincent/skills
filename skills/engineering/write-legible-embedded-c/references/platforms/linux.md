# L1 appendix: Linux kernel and BSP

Load for Nested Kernel/BSP platform **linux**. Decision checklist only — not a
driver tutorial and not a replacement for subsystem docs. Cross-context /
lock / alloc gates: [concurrency-memory.md](../concurrency-memory.md). HOT:
[hot-rules.md](../hot-rules.md).

## Local contract (tree wins)

Know: owning Kconfig/Kbuild, public/binding boundary, nearby in-tree precedent.
Do not invent `ARCH`, toolchain, or kernel-version range the tree does not state.

## Linux-specific ownership (keep)

| Concern | Required decision |
|---|---|
| Style / idiom | Linux coding style, subsystem rules, nearby code over Base formatting/decomposition |
| Types / annotations | Keep `u32`, `__iomem`, `__user`, kernel wrappers; do not force Base C11/userspace conventions |
| Resource lifetime | Owner + release; `devm_*` or manual only when lifetime matches device/error/unbind |
| Error unwind | Prefer in-tree forward `goto` cleanup (`goto err_…`) when local and visible; keep subsystem label names/order. **Do not** remove goto only to match Base “no goto”. |
| Kconfig/Kbuild | Preserve `select`/`depends on`, linkage, build coverage |
| DT / bindings | Compatible, properties, schemas are interfaces; update bindings when DT contract changes |
| uAPI / exports | BOUND; preserve layout, numbering, compatibility unless ABI change approved |

## Linux-specific mechanism pointers

Do **not** re-derive generic ISR/lock lessons here — use concurrency + HOT.
Pick **which Linux primitive** from tree + sharing CTXs:

| Concern | Point at tree / choose |
|---|---|
| CTX labels | hard IRQ, threaded IRQ, softirq/deferred, workqueue, process, probe/remove, PM |
| Sync | mutex, spinlock/raw, IRQ/BH variant, atomic, `READ_ONCE`/`WRITE_ONCE`, barriers; preserve order |
| Alloc | kernel helpers not libc; flags match CTX; *quiesce* async users before free (`devm_*` ≠ quiesce) |
| MMIO | `__iomem`, width/endian/order; `read*`/`write*`, `ioread*`/`iowrite*`, or `regmap` as used nearby |
| DMA | ownership, direction, map lifetime, barrier/sync the device needs; subsystem helpers |
| HOT path | H1–H6; hard path = ack + bounded capture + justified deferral |

## Verification matrix

Narrowest tree command; documented `ARCH`, O=, toolchain, config.

| Diff includes | Verify when available |
|---|---|
| C driver/core | Build changed object/module/kernel target; modpost/warnings if normal for that target |
| Kconfig/Kbuild | Config that enables the symbol; dependency/linkage failures |
| DT/binding | `dt_binding_check` / `dtbs_check` for affected arch/board |
| Style/API | `scripts/checkpatch.pl` on the diff when present |
| Runtime | Documented board/emulator path; else state missing evidence + risk |

**Done when:** every relevant row passed, deferred with reason, or unavailable.
Host-only build ≠ proof of target kernel/board config.
