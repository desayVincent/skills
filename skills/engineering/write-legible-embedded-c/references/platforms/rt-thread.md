# L1 appendix: RT-Thread (conflict table only)

Load only for Nested Kernel/BSP with platform **rt-thread**.

| Topic | Overlay / Base interaction |
|-------|----------------------------|
| Coding style | Follow RT-Thread / tree conventions when in-tree; Base is supplement. |
| ISR | Keep ISR short; use deferred thread/work patterns provided by the tree (HOT H3). |
| Interrupt enter/leave | Use platform-required enter/leave or nest APIs when the tree requires them. |
| Sleep | No sleep in ISR; Thread context uses RT-Thread IPC per docs. |
| Components | Vendor/component APIs at BOUND; do not rewrite component guts for Base aesthetics. |
| MMIO / registers | Named constants and H4 for ISR-shared state. |

Full API: RT-Thread documentation (L2).
