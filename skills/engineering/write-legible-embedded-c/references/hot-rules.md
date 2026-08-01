# HOT rules (H1–H6)

Apply when **Path Class = HOT** (typically **CTX = ISR** or an explicit fast path). These override Base Standard line-count and “split for cleanliness” pressure.

## H1 — Line budget off

Base **target 15 / hard 40** do **not** force splits on HOT. Nesting still prefer ≤2. Split only for a real concept, shared data boundary, or required deferral—not for line count.

## H2 — Call budget default 0

Default: no out-of-line helper calls on the HOT path (compiler-forced inline / single-line accessors OK). Any real call needs a one-line comment: *why this cannot be deferred*.

## H3 — Defer when possible

HOT does: ack hardware, minimal state, schedule **Deferred** / Thread work. Business logic belongs outside ISR.

## H4 — Shared data explicit

Data shared between ISR and Thread/Deferred must name the mechanism: `volatile` (MMIO/flags as appropriate), atomics, IRQ-safe critical section, or platform primitive. Do not “fix safety” by splitting functions alone.

## H5 — No blocking on HOT/ISR

No sleep, blocking wait, unbounded lock wait, or complex allocation unless the platform documents it as legal **and** a deviation comment cites that document.

## H6 — Label the path

Entry or section mark: `/* PATH: HOT; CTX: ISR */` (adjust CTX if Deferred fast path).

## HOT checklist (pre-delivery)

- [ ] H1: no split done only for Base 15/40
- [ ] H2: call budget respected or commented
- [ ] H3: nothing deferrable left in ISR without reason
- [ ] H4: shared data sync named
- [ ] H5: no illicit block/alloc
- [ ] H6: PATH/CTX annotation present
