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
| **ORCH** | Full Base Standard: 15 target / 40 hard, orchestrator/leaf/adapter, status enums, §14 gate; near-miss file when code already looks short/flat. |
| **HOT** | [hot-rules.md](hot-rules.md) overrides Base line budgets and call pressure. Still limit nesting; prefer deferral. |
| **BOUND** | Thin adapter over frozen foreign API (Vendor, SDK export, kernel uAPI). Do not rewrite the foreign side. |
| **DRIVER** | Host tree style wins (Linux kernel coding style, Zephyr conventions, etc.). Base supplements; see platforms/*.md. |

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