# Path Class and Execution Context

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

## Default matrix

| Repo Kind | Typical region | Default Path | Default CTX |
|-----------|----------------|--------------|-------------|
| Nested Kernel/BSP | IRQ handler | HOT | ISR |
| Nested Kernel/BSP | probe/init | ORCH or DRIVER | Init |
| Nested Kernel/BSP | normal driver ops | DRIVER | Thread |
| Super SDK | middleware, API, samples | ORCH | Thread / Init |
| Super SDK | glue calling kernel/BSP headers | BOUND | Thread |
| Super SDK | must not contain kernel-private includes | — | fix structure |

## Classification record

Record **Path Class** and **CTX** in [classify-repo.md](classify-repo.md) —
the only required artifact for “classification recorded.” EMBEDDED: multi-region
(minimal: edited Path×CTX only), HOT `HOT call notes` required / non-HOT omit,
fail-closed per SKILL.md Deliver.

Source comments only when context is not evident from entry/locking/API; host
style (no invented `/* PATH: HOT */` unless the tree already uses that).
