# Concurrency and memory contract

Load when code crosses execution contexts, shares mutable state, holds a
lock/mask, or allocates/releases memory.

**Not a locking tutorial.** Mechanisms, APIs, and legality come from the
**active tree** and the selected L1 appendix under [platforms/](platforms/).
This file is only a **fail-closed gate**.

If a mechanism has no header or nearby precedent: ask or block; do not invent
from pretrained “common embedded” patterns (see PC8).

---

## Prior-contamination ban list (all must pass)

Any unchecked item ⇒ concurrency gate **fails**.

- [ ] **PC1** — No portable mutex/condvar/“generic sync” layer when the tree already has a primitive.
- [ ] **PC2** — No custom reactor/actor/event-loop replacing the tree’s deferred/work/thread model.
- [ ] **PC3** — `volatile` is not sole cross-context sync for normal shared state (platform MMIO `volatile` OK).
- [ ] **PC4** — No heap alloc/free on ISR/HOT unless the tree explicitly allows it at this site.
- [ ] **PC5** — No sleep, blocking wait, or sleeping lock in ISR/HOT (or under non-sleepable lock/mask) without a cited tree exception.
- [ ] **PC6** — No zero-call-in-ISR dogma the host tree does not use; HOT calls use [hot-rules.md](hot-rules.md) H2 notes.
- [ ] **PC7** — No raw MMIO loads/stores when the tree/appendix provides accessors.
- [ ] **PC8** — No mechanism justified only by “common practice” without tree citation (or *none — asked/blocked* in the Classification record / delivery).

---

## Completion checklist

- [ ] PC1–PC8 all checked
- [ ] Every touched entry has CTX + sleepability from the tree (EMBEDDED: Path Class + CTX in [classify-repo.md](classify-repo.md))
- [ ] Every cross-context object has named owner, sync, ordering + tree citation (incl. teardown)
- [ ] Every held-lock/mask call is legal for that region (order, re-entry, *bounded* hold) per tree
- [ ] Every alloc has *context-legal* API/flags, failure path, and owner; release after *quiesce*
