# L1 appendix: Zephyr (conflict table only)

Load only for Nested Kernel/BSP with platform **zephyr**.

| Topic | Overlay / Base interaction |
|-------|----------------------------|
| Coding style | Follow Zephyr / tree conventions when in-tree; Base is supplement. |
| ISR | ISR must stay short; use `k_work` / threads for deferred work (HOT H3). |
| Deferred | Prefer `k_work` / system workqueue; mark CTX Deferred. |
| Sleep | No sleep in ISR; Thread context may use Zephyr sync objects per docs. |
| Device model | Do not restructure upstream device APIs for Base parameter-count rules (BOUND / deviation). |
| MMIO | Use Zephyr sys/device helpers; name shared flags with H4 discipline. |

Full API: Zephyr Project docs (L2).
