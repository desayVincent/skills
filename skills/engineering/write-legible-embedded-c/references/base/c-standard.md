# C standard for machine-written code

Rules for C that is maximally legible to language models and humans. Every
rule exists to cut the tokens and working memory needed to reason about any
region of code, to make every symbol greppable to few sites, and to keep every
edit local. Follow the rules mechanically. Deviation requires a comment at the
deviation site explaining why.

## Contents

1. [File layout](#1-file-layout)
2. [Constants](#2-constants)
3. [Naming](#3-naming)
4. [Functions](#4-functions)
5. [Control flow](#5-control-flow)
6. [Errors](#6-errors)
7. [Types and data](#7-types-and-data)
8. [Boundary discipline](#8-boundary-discipline)
9. [Macros](#9-macros)
10. [Duplication](#10-duplication)
11. [Comments](#11-comments)
12. [Formatting mechanics](#12-formatting-mechanics)
13. [Build hygiene](#13-build-hygiene)
14. [Pre-delivery checklist](#14-pre-delivery-checklist)

**Disclosed (load only when the skill pointer fires):**

- Greenfield module shape → [skeleton.md](skeleton.md) (former §15)
- Existing short-but-wrong code / near-miss → [near-miss-map-eat.md](near-miss-map-eat.md) (former §16)
- Repository `AGENTS.md` / agent guidance → [repository-level.md](repository-level.md) (former §17)
- Rule sources (human-facing) → [PROVENANCE.md](PROVENANCE.md) (former §18)


## 1. File layout

Every `.c` file has this exact order:

1. File comment: one or two lines stating what this module owns and does.
2. Includes: system headers, blank line, project headers. Alphabetical within
   each group.
3. Constants: enums first, then defines.
4. Types: structs, unions, typedefs.
5. Prototypes for every static function, each with its contract comment.
6. Public function definitions, in the same order as the header.
7. Static function definitions, in call order.

Every `.h` file: include guard, includes, constants, types, prototypes.
Nothing else. No function bodies, no variables.

Why: a model reading the first screen of the file learns the complete
vocabulary before meeting any logic. It never encounters an unexplained
symbol, so it never spends tokens searching downward to resolve one.

## 2. Constants

- No naked literals. The only bare numbers allowed in logic are 0 and 1 where
  meaning is obvious. Every other value gets a name at the top of the file or
  in the header.
- Use `enum` for related integer constants so debuggers and models see names,
  not values. Use `#define` only for string literals and conditional
  compilation.
- Units go in the name: `TIMEOUT_MS`, `MAX_PAYLOAD_BYTES`, `RETRY_COUNT`.
- Derived values are computed, never restated:
  `POOL_BYTES = POOL_SLOTS * SLOT_BYTES`.
- One definition site per constant in the whole program.

Why: a magic number is a fact with no grep anchor. A named constant is
self-documenting at every use site and editable in exactly one place.

## 3. Naming

- Every symbol with external linkage carries the module prefix: `rb_push`,
  `net_send`. Static helpers carry it too.
- Functions are verb_object: `parse_header`, `flush_queue`. Predicates start
  with `is_` or `has_` and are never negated: `is_valid`, never
  `is_not_ready`.
- Lifetime pairs are exact: `_create` pairs with `_destroy` and implies heap
  allocation with ownership transfer. `_init` pairs with `_deinit` and
  implies caller-owned storage. `_open` pairs with `_close`.
- Sanctioned abbreviations: `buf`, `len`, `ctx`, `cfg`, `idx`. Nothing else.
  `tmp`, `data2`, `do_stuff` are banned.
- Variable name length scales with distance between declaration and last use.
  `i` is fine inside a 5-line loop. Anything crossing 20 lines gets a
  descriptive name.
- Precise beats verbose. A name is the shortest string that states the
  concept: `retry_count`, not `number_of_connection_retry_attempts`.

Why: consistent naming turns grep into a reliable navigation tool. A model
can find every producer of a symbol without reading intervening code.

## 4. Functions

- One job per function. If the contract comment needs the word "and", split
  the function.
- Target 15 lines. Hard cap 40. A function is a table of contents for its
  helpers, not a container for logic phases.
- Maximum nesting depth 2. Guard clauses run first, then the happy path
  proceeds at the left margin.
- Parameter order is fixed: the module context pointer first, output
  parameters next, pure inputs last. A function with no context starts with
  its outputs, mirroring `memcpy`. A buffer and its length are always
  adjacent, buffer first.
- Maximum 4 parameters. More means the parameters are a struct trying to
  exist.
- No static variables inside functions except `static const` lookup tables.
  All state is passed in or owned by a context struct.
- Every function is an orchestrator, a leaf, or an adapter, never a mix. An
  orchestrator is a sequence of helper calls with status checks, branches on
  named predicates, and result binding, and contains no other logic. A leaf
  is straight-line logic that calls nothing but the module's accessors and
  pure utilities. An adapter wraps exactly one call into a foreign module and
  translates its status and calling convention into this module's.
- Decomposition terminates at the name test: if the most honest name for a
  candidate helper merely paraphrases its body, inline it and stop. A helper
  earns existence by naming a concept, owning an error value, or isolating a
  side effect.
- Cognitive complexity budget: target 8 per function, hard cap 15, measured
  by the Sonar rules that charge each break in linear flow and charge nesting
  progressively. Code conforming to the depth cap and decomposition rules
  sits far under budget; the metric is the tripwire, not the goal.

Why: a small flat function fits entirely in attention while reasoning about
any line of it. Nesting is state the reader must carry. Guard clauses
discharge preconditions immediately so nothing accumulates. The orchestrator
and leaf split gives every function one altitude: the reader follows a plan or
follows arithmetic, never both at once. The name test stops the regress toward
ravioli code, where a hundred two-line functions turn every read into a
pointer chase.

## 5. Control flow

- Early return over else chains. The success path is the unindented path.
- No `goto`. A function that acquires multiple resources decomposes into
  helpers where each helper releases what it acquired on its own failure,
  locally, next to the acquisition.
- A `goto` whose label only returns is banned with no exception. That is the
  cleanup pattern with the cleanup deleted: indirection purchasing nothing.
  Pure status propagation uses `MODULE_TRY`, section 9.
- Narrow exception: a function juggling three or more interdependent
  resources, where decomposition would smear half-initialized state across
  helpers, may use one forward `goto` to one cleanup label. The label site
  carries a comment justifying it.
- Every `switch` case ends in `break` or `/* fallthrough */`. `default` is
  always present.
- A loop body over 10 lines becomes a named function. The call site then
  documents the iteration in one line.
- Every loop has a statically evident upper bound. The one exception is an
  intentionally nonterminating loop, an event pump or scheduler, marked with
  a comment saying exactly that.
- No recursion, direct or indirect. Recursive shapes convert to a loop over
  an explicit bounded worklist, which makes stack use visible and termination
  checkable.
- No side effects inside conditions. No assignment inside `if`. Ternaries
  only for simple value selection, never nested.

Why: control flow is the most expensive thing to simulate while reading.
Every rule here reduces the number of paths a reader must hold to understand
one path.

## 6. Errors

- Every fallible function returns a module status enum. Success is 0 and is
  named: `RB_OK`.
- One status enum per module, values prefixed: `RB_ERR_ALLOC`, `RB_ERR_FULL`.
- Never return `bool` from anything that can fail more than one way. Never mix
  errno-style and enum-style in module code. Wrap libc at the boundary and
  convert.
- Every fallible call is checked. Status propagates upward unchanged. Only
  the top of the call chain logs, converts, or decides.
- Minimize producers per error value. `grep RB_ERR_FULL` should land on one
  producing line and its handlers.

Why: error enums are documentation, grep anchors, and debugging breadcrumbs
in one mechanism. A model tracing a failure follows the name straight to the
cause.

## 7. Types and data

- Fixed-width types everywhere: `uint32_t`, `int64_t`. `size_t` for sizes,
  counts, and indices. Bare `int` only where an external API forces it.
- `const` on every pointer parameter the function does not write through.
- Struct fields are grouped by relatedness, and every invariant that ties two
  fields together is documented in a comment above the struct.
- Opaque structs only at true library boundaries. Internal modules expose
  layout so instances can live on the stack, embed in parent structs, and be
  inlined across.
- Every union carries a tag field. Every variable is initialized at
  declaration. Structs use designated initializers.
- Declare every object at the smallest scope that works, at the latest point
  that works. Scope is working memory: the fewer live names at any line, the
  less state any reader carries.
- One level of dereference per expression. A chain like `a->b->c->d` smuggles
  three lifetimes and three nullability questions into one term; bind
  intermediates to named locals.
- Function pointers appear only as entries in `static const` dispatch tables.
  Control flow through data is legible when the table is immutable, named,
  and complete; a function pointer passed around loose is control flow no
  reader can trace.

## 8. Boundary discipline

- Public entry points validate their arguments and return `ERR_ARG` on
  violation.
- Internal static helpers do not re-validate. They `assert` their invariants.
  The assert documents the contract in debug builds and costs nothing in
  release.
- Assertion density is a feature. Every leaf that mutates state asserts at
  least one invariant, and the module-wide target is the Power of 10 floor of
  two assertions per function. Each assert is a machine-checked comment: it
  states what must stay true, at zero release cost, exactly where an editor is
  about to change something.

Why: validation logic duplicated at every level is noise that hides logic.
One validation site per boundary, asserts everywhere else, tells the reader
exactly who is responsible for what.

## 9. Macros

- Uppercase names. Every argument and the whole body parenthesized.
  Multi-statement bodies wrapped in `do { } while (0)`.
- No macro contains `return`, `goto`, `break`, or `continue`. No macro
  evaluates an argument twice.
- One sanctioned exception: each module may define `MODULE_TRY(expr)` beside
  its status enum, the sole macro permitted to contain a return. It evaluates
  `expr` once and returns any non-OK status to the caller. It is C's answer to
  Rust's `?`.
- `TRY` may appear only in functions that acquire nothing. This is greppable
  through section 3 naming: any function whose body calls `_create`, `_init`,
  `_open`, `alloc`, or any acquiring function uses explicit checks with
  explicit release instead.
- Prefer `static inline` functions over function-like macros in every case
  where types allow.

Why: a macro that hides control flow makes the visible code lie about its own
paths, so hidden control flow is banned wherever it could skip an obligation.
Orchestrators hold no obligations by construction, section 4, so a hidden
return inside one cannot leak anything. There `TRY` buys real safety: a
fallible call sitting outside `TRY` or an `if` becomes greppable as an
unchecked call, the single most common machine-written C bug. The cost is
priced in: a grep for `return` misses these exits, and a debugger steps into
the macro. Both are cheaper than the forgotten check the macro makes
impossible.

## 10. Duplication

- Logic never appears twice. The second occurrence becomes a named function
  at the moment it is written.
- A string literal used twice becomes a define.

Why: duplicated logic diverges under machine editing. A model patching one
copy has no link telling it the other copy exists. Single sourcing makes every
fix total.

## 11. Comments

- Above every prototype: one contract comment stating what the function does,
  ownership and nullability of every pointer, and the failure modes. Never
  restate the signature.
- Inside bodies: comment why, never what. The code says what.
- No commented-out code, ever. Version control remembers.

## 12. Formatting mechanics

- 4-space indent, no tabs. 100-column limit.
- One statement per line. One declaration per line.
- Function opening brace on its own line. Control-flow braces on the same
  line.
- A single-statement guard clause may omit braces with the statement on the
  next line. Everything else is braced.

## 13. Build hygiene

- Compiles clean under `-Wall -Wextra -Werror -Wconversion -Wshadow` from the
  first commit.
- C11 minimum. No compiler extensions without a wrapping macro and a comment.

## 14. Pre-delivery checklist

Before presenting any C code, verify:

1. Any literal that is not 0 or 1? Name it.
2. Any function over 40 lines or nested past depth 2? Split it.
3. Any contract comment containing "and"? Split the function.
4. Any `goto`? Decompose, or justify at the label.
5. Every fallible call checked and propagated?
6. Prototypes at the top of the file, matching every definition?
7. Each new error value: how many producers? Reduce toward one.
8. Any logic pasted twice? Extract it.
9. Any parameter list past 4? Struct it.
10. Header exposes only what callers need?
11. Any function mixing helper calls with inline logic? Push the logic into a
    leaf.
12. Any helper whose name paraphrases its body? Inline it.
13. `TRY` inside a function that acquires anything? Switch to explicit checks
    with explicit release.
14. Parameters out of context, outputs, inputs order? Reorder.
15. Any loop without a statically evident bound or a nonterminating marker?
    Bound it.
16. Any recursion? Convert to a bounded worklist loop.
17. Any state-mutating leaf with zero asserts? State the invariant.

## Disclosed references

These files hold material that only some branches need. Do not load them on
every C change.

| When | Open |
|------|------|
| Greenfield module or full file layout exemplar | [skeleton.md](skeleton.md) |
| Existing function looks short/flat but may fail the standard | [near-miss-map-eat.md](near-miss-map-eat.md) |
| Changing repo agent guidance, `AGENTS.md`, or test feedback loop | [repository-level.md](repository-level.md) |
| Human question about rule provenance (not a code gate) | [PROVENANCE.md](PROVENANCE.md) |
