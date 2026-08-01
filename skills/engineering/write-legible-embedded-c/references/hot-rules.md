# HOT rules (H1–H6)

Apply when **Path Class = HOT** (typically **CTX = ISR** or an explicit fast path). These override Base Standard line-count and “split for cleanliness” pressure.

## H1 — Line budget off

Base **target 15 / hard 40** do **not** force splits on HOT. Nesting still prefer ≤2. Split only for a real concept, shared data boundary, or required deferral—not for line count.

## H2 — Call budget follows the latency contract

Treat each call on the HOT path as a latency, stack, locking, and deferral
decision. Keep calls whose context and bounded work fit the actual contract;
use the tree's existing inline or leaf patterns for simple register access.
Avoid duplicating logic merely to satisfy an artificial zero-call budget. A
non-obvious hard-IRQ call or exception gets a source-site reason.

## H3 — Defer when possible

HOT does: ack hardware, minimal state, schedule **Deferred** / Thread work. Business logic belongs outside ISR.

## H4 — Shared data and ordering explicit

For every datum shared across HOT, Deferred, or Thread context, identify the
writer, reader, context, and synchronization mechanism. Use the platform's
MMIO accessor for device registers; use the tree's lock, atomic, IRQ-safe
critical section, `READ_ONCE`/`WRITE_ONCE`, or documented memory-ordering
primitive for normal shared state. `volatile` is not a generic synchronization
or ordering mechanism; use it only where the platform interface requires it.

## H5 — Context-legal work only

Apply the [concurrency and memory contract](concurrency-memory.md). Use only
operations legal in the active execution context. Keep waits and lock hold time
bounded; move work whose latency or sleepability cannot be justified to
Deferred or Thread context. A documented platform exception gets a source-site
comment that names the constraint.

## H6 — Record the path

Record the HOT/CTX classification in the delivery or review record. Add a
source comment only when the context constraint is not obvious from the entry
point, locking, or platform API; follow the host tree's comment style.

## HOT checklist (pre-delivery)

- [ ] H1: no split done only for Base 15/40
- [ ] H2: every HOT call is context-legal and justified by the latency contract
- [ ] H3: nothing deferrable left in ISR without reason
- [ ] H4: every cross-context datum has an explicit synchronization and ordering story
- [ ] H5: every operation is legal for the active context
- [ ] H6: HOT/CTX recorded; non-obvious source constraints documented
