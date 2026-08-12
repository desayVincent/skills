---
name: deep-modules-c
description: >
  Deep modules for C/C++ and SDK. Use when designing a module interface,
  placing a seam (ops table, HAL, plugin), judging deep vs shallow, deepening
  a cluster, comparing alternative interfaces, or teaching the module /
  interface / depth / seam vocabulary for C/C++.
metadata:
  short-description: "Deep modules for C/C++ SDK"
---

# Deep modules (C/C++)

Design **deep** modules: much behaviour behind a small **interface**, at a
clean **seam**, testable through that interface. Callers get **leverage**;
maintainers get **locality**.

## Glossary

Use these terms for **architecture analysis**. Keep the project’s domain, API,
and ABI names from `CONTEXT.md` / headers when naming product things.

**Module** — anything with one interface and an implementation. Scale-agnostic:
one `.c`/`.cc` + public header, a static library, or a whole SDK layer.

_C/C++ shape:_ the **public header** callers include is the usual edge; private
headers and bodies are implementation.

**Interface** — every fact a caller must know: prototypes, invariants, call
order, error meanings, buffer/handle ownership, threading, init, performance.

_C/C++ shape:_ public functions + **opaque** types + those contracts (C++ may
also use a narrow abstract class or `extern "C"` surface). Few exports can still
be a large interface if callers must learn globals and lock order.

**Implementation** — code inside the module. Distinct from **adapter** (role at
a seam).

**Depth** — behaviour exercisable per unit of interface learned. **Deep** =
large implementation, small interface. **Shallow** = interface nearly as complex
as the implementation. Measure **depth-as-leverage**, not line counts.

**Seam** _(Feathers)_ — place where behaviour can change without editing that
place; the *location* of the interface.

_C/C++ shape:_ ops table, HAL vtable, plugin register, weak stubs, callback +
user data, C++ abstract interface / strategy. A seam exists to isolate a
**known** variation, platform, or ownership boundary — not to add indirection.

**Adapter** — concrete fill of a seam (prod HAL, loopback, test fake). Role,
not substance. Adapter count is **evidence**, not the definition of a seam.

**Leverage** — capability per unit of interface callers learn.

**Locality** — change, bugs, and verification concentrate in one place.

## Principles

- **Depth lives on the interface.** Internals may be fine-grained; keep them
  off the public surface. Prefer **internal seams** for tests.
- **Deletion test.** Delete the module. Complexity vanishes → pass-through.
  Complexity reappears at N callers → it earns its keep.
- **Interface is the primary test surface.** Contract tests cross the public
  seam. Private/white-box tests stay valid for fault injection, safety
  properties, and hardware-specific checks the public surface cannot express.
- **Seam rule (SSOT here).** Introduce a seam only when it isolates a known
  variation, platform edge, or ownership boundary. A second adapter (often
  prod + test) *supports* the claim; one fill alone is a smell of unneeded
  indirection — cut or justify with the known boundary (e.g. single-board HAL
  behind an ops table for testability is fine when tests need a fake).

**Done when (design check):** each public module you touch has named interface
facts, a deletion-test stance, and each seam either names its known boundary or
is removed as pure indirection.

## Design for testability

1. **Inject dependencies** — pass `ops` + `ctx`; leave process globals to
   proven board singletons only.
2. **Return results** — error codes + clear ownership of out-params; keep
   side effects on the interface contract.
3. **Small surface** — fewer entry points and public fields; prefer opaque
   handles unless ABI forces layout.

```c
int session_open(Session **out, const SessionOps *ops, void *ops_ctx);
int msg_decode(const uint8_t *buf, size_t len, Msg **out);
```

## Relationships

Module → one Interface → lives at a Seam → satisfied by Adapter(s). Depth →
Leverage + Locality.

## Load when needed

| Branch | Open |
|--------|------|
| Deepening a cluster; dependency class for tests | [DEEPENING.md](DEEPENING.md) |
| Alternative interfaces | [DESIGN-IT-TWICE.md](DESIGN-IT-TWICE.md) |
| Public header / SDK checklist (C and C++ ABI) | [references/c-cpp-sdk.md](references/c-cpp-sdk.md) |

Optional peers (not required): `domain-model-c`, `improve-architecture-c`,
`write-legible-embedded-c`.
