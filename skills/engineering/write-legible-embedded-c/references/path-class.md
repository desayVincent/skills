# Path Class and Execution Context

Definitions only. **Defaults**, **Classification record**, and multi-region
rules live in [classify-repo.md](classify-repo.md).

## Execution Context

Where the code runs (cross OS):

| Context | Meaning |
|---------|---------|
| **ISR** | Hard IRQ / non-sleepable interrupt top half (same severity constraints). |
| **Deferred** | Bottom half: tasklet, workqueue, softirq deferred, RTOS deferred work. |
| **Thread** | Sleepable thread/task (user, kernel thread, or RTOS task—as platform allows). |
| **Init** | Boot, module init, BSP bring-up sequences (non-hot orchestration). |

## Path Class

Which legibility regime applies:

| Class | Regime |
|-------|--------|
| **ORCH** | Quality floor first; Base legibility where compatible: orchestrator/leaf/adapter, status handling, and §14 gate; near-miss file when code already looks short/flat. |
| **HOT** | Quality floor first, then [hot-rules.md](hot-rules.md); selected platform/concurrency rules follow when triggered. HOT overrides Base line budgets and call pressure. |
| **BOUND** | Quality floor first; then a thin adapter over the frozen foreign API (Vendor, SDK export, kernel uAPI). Base adapter style applies only where compatible. |
| **DRIVER** | Quality floor first; then host-tree style and selected platform rules. Base only supplements Linux, Zephyr, RT-Thread, or BSP conventions. |

## Source comments

Comment only when context is not evident from entry/locking/API; host style
(no invented `/* PATH: HOT */` unless the tree already uses that).
