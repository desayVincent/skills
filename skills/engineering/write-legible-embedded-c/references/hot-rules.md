# HOT rules (H1–H6)

Apply when **Path Class = HOT** (typically **CTX = ISR** or an explicit fast path). These override Base Standard line-count and “split for cleanliness” pressure.

## H1 — Line budget off

Base **target 15 / hard 40** do **not** force splits on HOT. Nesting still prefer ≤2. Split only for a real concept, shared data boundary, or required deferral—not for line count.

## H2 — Call budget follows the latency contract

Treat each call on the HOT path as a latency, stack, locking, and deferral
decision. Prefer the tree's existing inline or leaf patterns for simple
register access. Do not invent a zero-call budget that the host tree does not
use.

**Checkable product:** list every non-trivial HOT call in the Classification
record **HOT call notes** field
([classify-repo.md](classify-repo.md)) as
`call site → why not deferred / latency bound source`. Use `none` when there
are no such calls. A non-obvious hard-IRQ exception may also get a source-site
reason in host style.

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

Record HOT/CTX in the Classification record template in
[classify-repo.md](classify-repo.md) (fields **Path Class**, **CTX**, and when
applicable **HOT call notes**). That is the verification target for H6.

Add a source comment only when the context constraint is not obvious from the
entry point, locking, or platform API; follow the host tree's comment style.

## HOT checklist (pre-delivery)

- [ ] H1: no split done only for Base 15/40
- [ ] H2: every non-trivial HOT call is listed in Classification record **HOT call notes** as `call site → why not deferred / latency bound source` (or `none`)
- [ ] H3: nothing deferrable left in ISR without reason
- [ ] H4: every cross-context datum has an explicit synchronization and ordering story
- [ ] H5: every operation is legal for the active context
- [ ] H6: Path Class + CTX filled in Classification record; non-obvious source constraints documented