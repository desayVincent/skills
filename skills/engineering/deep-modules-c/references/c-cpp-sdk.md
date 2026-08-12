# C/C++ SDK checklist

Load when designing **public headers**, SDK layers, or platform seams.
Vocabulary and seam rule: parent [SKILL.md](../SKILL.md).

## Instantiation table

| Term | Typical form |
|------|----------------|
| Module | Public `.h` + implementing `.c`/`.cc` (or small static lib) |
| Interface | Functions + opaque types + error/lifetime/thread contracts |
| Seam | `FooOps`, HAL vtable, plugin register, weak stubs, C++ abstract iface |
| Adapter | One concrete fill (prod / fake / loopback) |

Keep glossary terms in speech; use this table only as shape.

## Public header (shallow risk)

- Full struct in public header when a handle suffices
- Field-wise getters/setters for every member
- Private macros or driver includes on the public edge
- Init order that exists only as folklore

## Seam smell (not automatic ban)

- Ops table with **no** known platform/ownership/test boundary
- Function pointers fixed forever to the same static targets with no replace
- Plugin registration that only ever loads one in-tree plugin and never varies

A single-board HAL behind ops **with** a test fake is a justified seam.

## Globals and shared ABI (C and C++)

- Prefer `ctx` / handle; document board-level singletons in an ADR when forced
- Opaque handles + stable error meanings keep depth while implementation moves
- Freezing a large public struct freezes shallowness — ADR if intentional
- Public header must not force half the tree through includes; forward-declare
- Cross-layer includes (product → driver-private) usually mean a misplaced seam

## C++ ABI branch

Load this section when the public surface is C++ or mixed C/C++.

| Concern | Prefer |
|---------|--------|
| Stable shared-lib edge | `extern "C"` + opaque handles for the frozen surface |
| Symbol visibility | explicit export map / visibility attributes; hide internals |
| Exceptions | no exceptions across the public ABI unless documented and matched on both sides |
| RTTI / vtables | keep polymorphic types out of the stable ABI, or version them deliberately |
| Layout | no leaked private class layout; pimpl / opaque where ABI must move |
| Allocators | who allocates/frees across the boundary is part of the interface |
| Calling convention / packing | document if non-default; match toolchains |
| Versioning | symbol versions or explicit API version fields when clients ship separately |

C++ abstract interfaces are fine **inside** the module or at a real seam; prefer
not to freeze a wide virtual hierarchy as the long-term public SDK edge unless
that is an explicit ADR.
