# C Quality Floor

Apply this reference to every HOST and EMBEDDED branch before legibility
styling. It covers language semantics and resource contracts;
`concurrency-memory.md` and `platforms/*.md` cover execution-context legality,
synchronization, MMIO APIs, and OS-specific mechanisms.

Repository dialect, public API/ABI, wire format, hardware documentation, and
nearby target code are the live contract. Treat Base file order, line and
parameter limits, status-enum/`TRY` protocol, exact type spelling,
initialization style, assertion density, cleanup shape (including Base
“no `goto`”), recursion/allocation policy, and warning flags as house style:
apply them when compatible, and record a precise deviation when they are not.

**`goto` policy:** do **not** ban or rewrite a tree’s established cleanup
idiom. Linux kernel and many drivers use a single forward `goto` to one (or
a short ordered set of) cleanup labels; that is preferred when nearby code
does the same. Base §5/§14 “No `goto`” never outranks the live tree, Linux L1,
or this floor’s ownership/unwind rules. Ban only unstructured jumps that the
tree itself rejects (e.g. jumping backward into half-initialized state).

## 1. Establish the contract

Before editing, identify:

- language dialect, compiler extensions, warning policy, and target config;
- nullability, sizes, units, ownership transfer, and error convention at each
  changed interface;
- exact external representation: width, signedness, byte order, alignment,
  packing, register semantics, and ABI layout;
- acquisition/release order, asynchronous users, and the state published on
  success or failure;
- execution context and mutable sharing when the region crosses contexts.

**Pass when:** every changed boundary and risky operation below resolves to a
live contract rather than a generic C preference.

## 2. Keep integer operations representable

- Use `size_t` for object sizes and array extents unless an API fixes another
  type. Use exact-width or project-native register types where the external
  representation requires a width; do not force fixed-width types onto
  ordinary loop counters or native APIs.
- Validate before narrowing, signed/unsigned conversion, addition,
  multiplication, pointer-offset calculation, or allocation-size calculation.
  Structure length checks so the check itself cannot wrap or underflow.
- Perform bitwise work on an appropriate unsigned type. Prove shift counts are
  within the promoted left operand's width and that the value is representable.
- Keep units visible in names or types; convert once at a named boundary.

**Pass when:** each conversion and size expression has an evident range, and
no result depends on signed overflow or accidental unsigned wrap.

## 3. Access objects through valid representations

- Check bounds before indexing, dereferencing, copying, or advancing a pointer.
  Pointer arithmetic stays within one array object or its one-past position.
- Decode wire/storage data with byte assembly, `memcpy`, or repository
  accessors. A pointer cast is not proof of alignment, effective type, packing,
  or byte order.
- Preserve ABI-visible field order, enum values, padding, packing, and calling
  convention. Use compile-time assertions already supported by the tree for
  layouts that must be exact.
- Use masks and accessors for MMIO. Use C bit-fields for an external layout only
  when the toolchain/ABI contract explicitly fixes their allocation and order.

**Pass when:** every external byte or register access states how width,
alignment, aliasing, and byte order are satisfied.

## 4. Make initialization and publication deliberate

- Initialize every object before its first read on every path. Prefer an
  initializer that expresses the real initial state; avoid dummy values that
  merely silence a warning and can hide a missing assignment.
- Build fallible results in locals and publish them only after validation when
  the API promises an unchanged output on failure.
- Use designated initializers where they make member intent and future layout
  changes safer; follow generated-code and ABI conventions where they differ.
- Treat external input as recoverable failure. Use assertions for internal
  invariants only under the repository's assertion policy.

**Pass when:** success and every failure path leave outputs and module state in
their documented states.

## 5. Make ownership and cleanup total

- Give every acquired resource one named owner and one matching release
  responsibility. State ownership transfer at the interface.
- Keep unwind visible and release in reverse acquisition order. A local forward
  `goto` cleanup label (Linux-style `goto err_free_x`) is valid and often
  required when it matches the tree; small single-resource functions may use
  direct returns. Do not decompose away a clear multi-resource `goto` chain
  only to satisfy Base “no `goto`”.
- Quiesce callbacks, interrupts, work items, DMA, and other asynchronous users
  before releasing their state. Managed allocation does not prove quiescence.
- Publish a constructed object only after all required acquisition succeeds;
  leave it closed, detached, or otherwise documented after failure.

When ownership crosses execution contexts or teardown races asynchronous users,
complete [concurrency-memory.md](concurrency-memory.md) before delivery. This
section proves ownership and unwind; that reference proves synchronization,
ordering, context legality, and quiescence.

**Pass when:** every acquisition maps to release on all later failures, normal
shutdown, and partial-initialization paths.

## 6. Keep types, casts, and macros honest

- Encode read-only intent with `const`. A cast that removes `const` or
  `volatile` needs a local hardware, ABI, or frozen-API reason.
- Use `volatile` for repository-approved MMIO or objects observed outside the
  implementation's ordinary control flow. Use tree atomics, locks, barriers,
  or IPC for synchronization; `volatile` alone does not provide it.
- Prefer functions or `static inline` functions to function-like macros. When
  a macro is required, evaluate each argument once, parenthesize expressions,
  and keep hidden control flow within an established repository protocol.
- Make every non-trivial cast's range, alignment, qualifiers, and
  representation valid at the site. Keep pointer/integer round-trips at the
  boundary that owns them.
- Write expressions whose result does not depend on operand evaluation order;
  split mixed side effects and precedence-sensitive arithmetic into named
  steps.

**Pass when:** a reviewer can determine the value, object, and side effects of
each operation without relying on macro expansion or undocumented compiler
behavior.

## 7. Shape code around concepts and obligations

- Minimize scope and linkage; use `static` for file-local objects and functions.
- Follow the repository's error protocol at public and foreign boundaries.
  Adapt locally rather than introducing a parallel enum, errno, exception, or
  logging convention.
- Split functions at named concepts, representation boundaries, or ownership
  obligations. Treat line counts and parameter counts as review prompts, not
  reasons to create pass-through helpers.
- Comment invariants, ownership, hardware assumptions, context restrictions,
  non-obvious conversions, and deliberate deviations. Public or cross-context
  APIs document return and context contracts; body comments do not narrate the
  next statement.

**Pass when:** the code exposes its contracts without changing local idiom or
adding indirection that carries no invariant.

## 8. Verify the configured target

- Build the narrowest real target with its actual dialect, config, generated
  headers, and warning policy. A host-only compile does not validate target C.
- Exercise changed success, boundary, and failure behavior. Use the tree's
  static analysis, sanitizers, or hardware/emulator checks when already
  available and relevant.
- Report commands and outcomes. Mark unavailable target evidence with the
  missing tool/config/hardware and the remaining risk.

**Pass when:** the final diff has evidence for language acceptance, boundary
behavior, failure cleanup, and any changed target-specific mechanism.

## Pre-delivery checklist

- [ ] Live dialect, API/ABI, representation, ownership, and context identified
- [ ] Bounds, size arithmetic, conversions, shifts, and units checked
- [ ] Alignment, aliasing, byte order, packing, and MMIO access resolved
- [ ] Initialization, output publication, and all failure states valid
- [ ] Acquisition, reverse-order unwind, shutdown, and quiescence complete
- [ ] Qualifiers, casts, macros, and expression side effects justified
- [ ] Local error/style conventions preserved; Base deviations precise
- [ ] Configured-target build/tests/tooling run or remaining evidence gap named

## Source basis

These rules synthesize checkable properties rather than copy a book's house
style. Author-published code and books contribute interface patterns; language
and platform sources decide correctness.

- Language semantics: WG14 [N1570](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf), the [C99 Rationale](https://www.open-std.org/jtc1/sc22/wg14/www/C99RationaleV5.10.pdf), and [SEI CERT C](https://wiki.sei.cmu.edu/confluence/display/c/SEI+CERT+C+Coding+Standard).
- Enforceable embedded guidance: Barr Group's [Embedded C Coding Standard](https://barrgroup.com/sites/default/files/barr_c_coding_standard_2018.pdf) and [MISRA Compliance](https://misra.org.uk/compliance/).
- Platform contracts: [Linux](https://docs.kernel.org/process/coding-style.html), [Zephyr](https://docs.zephyrproject.org/latest/contribute/coding_guidelines/index.html), and [RT-Thread](https://www.rt-thread.io/document/site/development-guide/style/style/).
- Interface patterns: Hanson's [C Interfaces and Implementations code](https://github.com/drh/cii); its exception macros are not imported.
- Context-specific safety subsets: Holzmann's [Power of Ten](https://spinroot.com/gerard/pdf/P10.pdf), not a universal C house style.
