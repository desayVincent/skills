# Concurrency and memory contract

Load this reference when touched code crosses execution contexts, shares
mutable state, holds a lock or interrupt/scheduler mask, or allocates/releases
memory. Treat context, ownership, synchronization, and teardown as one
contract.

Do not substitute a pretrained “common” locking, allocator, or ISR pattern for
the active tree’s contract (**prior contamination**). Name each mechanism and
cite the header or nearby in-tree precedent that establishes the required use.

## 1. Map execution contexts

For every touched entry point and callback, record:

- CTX: ISR, Deferred, Thread, or Init.
- Whether it may sleep, wait, block, or be preempted.
- Whether it may run concurrently or re-enter on another CPU, interrupt, task,
  callback, or teardown path.
- Its *bounded*-latency requirement and the mechanism that enforces it.

**Done when:** every operation introduced or moved by the change is
*context-legal* in all contexts that can reach it, with sleepability and
latency bounds taken from the active platform or nearby code — not from generic
priors.

## 2. Prove each shared object's contract

For every touched mutable object, identify its owner, lifetime, readers,
writers, execution contexts, synchronization primitive, and required memory or
device ordering. Use the active platform's MMIO accessors for registers and its
lock, atomic, barrier, or IRQ-safe critical-section primitive for normal shared
state. A hardware interface may require `volatile`; normal inter-thread state
requires a synchronization contract.

**Done when:** each cross-context access and lifetime transition is protected
by one **named** mechanism (including teardown), and that mechanism is tied to a
header or nearby precedent in the active tree.

## 3. Audit held-lock calls

Mark the exact region covered by each mutex, spinlock, critical section,
interrupt mask, scheduler lock, or preemption disable. Trace every call made in
that region far enough to establish whether it:

- sleeps, waits, blocks, allocates, or enters reclaim;
- acquires another lock and preserves the established lock order;
- invokes callbacks, logs through a potentially blocking path, or re-enters
  code that can acquire the same lock;
- has a *bounded* execution time compatible with interrupt and scheduling
  latency.

When a call violates the region's contract, move it outside using a validated
snapshot, ownership transfer, reference, or deferred-work boundary, or select
the platform primitive that matches the actual sharing contexts.

**Done when:** every call under a held lock or mask has a context, lock-order,
re-entrancy, and latency justification grounded in the tree (API docs, nearby
callers, or subsystem rules) — not a generic claim that the call is “usually
safe.”

## 4. Prove allocation and release

Prefer static storage, preallocation, fixed-size pools, or slabs where ISR or
bounded latency makes heap behavior unsuitable. When dynamic allocation fits
the lifecycle:

- Use the active kernel, RTOS, BSP, or subsystem allocator. Use libc
  `malloc/free` only in an actual libc userspace environment.
- Choose the API, flags, timeout, alignment, DMA/cache properties, and failure
  path from the real execution context. Use overflow-safe size calculations
  for arrays and variable-sized objects.
- Name the owner after every successful allocation and every ownership
  transfer. Unwind partial construction in reverse acquisition order, exactly
  once.
- *Quiesce* every producer and consumer before release: IRQ, deferred work,
  timer, thread/task, DMA, callback, queue, device user, and outstanding
  reference as applicable.
- Audit allocation and release performed under a held lock using section 3;
  allocator and destructor behavior is part of the call contract.

**Done when:** allocation failure, normal release, initialization failure,
shutdown, detach/remove, and concurrent teardown each have one complete owner
and release path, with no user remaining after lifetime ends, and the chosen
allocator API/flags are justified from the active context and tree.

## Completion checklist

- [ ] Every touched entry point has a CTX and sleepability decision from the tree.
- [ ] Every shared object has named ownership, synchronization, and ordering, with the primitive cited to a header or nearby precedent.
- [ ] Every held-lock call has legality, lock-order, re-entrancy, and latency evidence from the tree.
- [ ] Every allocation has a *context-legal* failure and ownership path.
- [ ] Every release occurs after all asynchronous users are *quiesced*.
- [ ] No pretrained “common pattern” was used where the active tree specifies a different mechanism.
