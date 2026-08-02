# HOT rules (H1–H6)

Apply when **Path Class = HOT** (typically **CTX = ISR** or an explicit fast path).
Overrides Base **15/40** and “split for cleanliness.”

Do not invent zero-call budgets, lock styles, or deferral shapes the tree does
not use — [concurrency-memory.md](concurrency-memory.md) ban list.

**Record coupling:** H2 and H6 are verified **only** against the Classification
record in [classify-repo.md](classify-repo.md). Missing required fields ⇒ those
checks **fail** (fail-closed).

## H1 — Line budget off

Base 15/40 does **not** force HOT splits. Nesting still prefer ≤2. Split only
for a real concept, shared-data boundary, or required deferral.

## H2 — Calls ↔ record field `HOT call notes`

Each non-trivial HOT call is a latency/stack/lock/deferral decision; cite the
tree, do not invent a zero-call budget.

| Record field | Required content |
|--------------|------------------|
| **HOT call notes** | `call site → why not deferred / latency bound source` per call; or exactly `none` |

**Fail:** HOT region and field missing, blank, vague prose, or not `none` / `→` lines.

## H3 — Defer when possible

Business work off HOT; use the **tree’s** deferred primitive (name from tree/L1).
See PC2 if tempted to invent a reactor.

## H4 — Shared data explicit

Cross-context datum ⇒ named tree sync + citation (or *none — asked/blocked*).
Details: PC3/PC7 and concurrency checklist — not retaught here.

## H5 — Context-legal only

Only operations legal in this CTX; *bounded* hold/latency. Unjustified sleep or
work ⇒ Deferred/Thread. Full gate: [concurrency-memory.md](concurrency-memory.md).

## H6 — Record the path ↔ `Path Class`, `CTX`, `HOT call notes`

| Record field | Required when Path Class = HOT |
|--------------|--------------------------------|
| **Path Class** | `HOT` |
| **CTX** | Filled (typically `ISR`); not blank |
| **HOT call notes** | Same rule as H2 |

**Fail:** any of the three missing/blank, or H2 content rule failed.  
No invented `/* PATH: HOT */` unless the host tree already uses that convention.

## HOT checklist (pre-delivery)

- [ ] **H1:** no split only for Base 15/40
- [ ] **H2:** **HOT call notes** valid — *field missing ⇒ fail*
- [ ] **H3:** deferrable work not left on HOT without reason; deferred API from tree
- [ ] **H4:** cross-context sync named + tree-cited
- [ ] **H5:** context-legal + *bounded*; concurrency gate passes
- [ ] **H6:** **Path Class** + **CTX** + **HOT call notes** — *any missing ⇒ fail*
