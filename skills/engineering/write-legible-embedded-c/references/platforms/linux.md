# L1 appendix: Linux (conflict table only)

Load only for Nested Kernel/BSP with platform **linux**. Not a driver HOWTO.

| Topic | Overlay / Base interaction |
|-------|----------------------------|
| Coding style | In-tree **Linux kernel coding style** and checkpatch expectations beat Base formatting religion when they conflict. |
| Cleanup `goto` | Single forward `goto` to one cleanup label on multi-resource failure is **host-normal**; do not “Base-ban” it without a better in-tree pattern. |
| ISR | Use only IRQ-safe primitives; sleepable APIs → Deferred (workqueue) or thread. HOT H1–H6 apply. |
| Deferred | `tasklet` / `workqueue` / threaded IRQ as appropriate; mark CTX Deferred when editing those functions. |
| User API | ioctl/uAPI freezes → BOUND on the boundary; do not reshape for Base status enums if ABI frozen (deviation comment). |
| MMIO | `readl`/`writel` (or arch helpers); do not invent host-style plain pointer walks without `volatile`/helpers. |

Full subsystem docs: kernel documentation tree (L2 — outside this skill).
