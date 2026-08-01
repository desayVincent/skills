# ADR 0001: Base write-legible-c + Embedded Overlay bundle

## Status

Accepted

## Context

We need machine-legible C for Super SDK trees that nest Linux/Zephyr/RT-Thread BSP git repos, including ISR and driver paths. Upstream `write-legible-c` is excellent for ORCH code but forces harmful decomposition on HOT/ISR and omits MMIO/context rules. Team members may not have marketplace access to Base.

## Decision

1. **Single skill** `write-legible-embedded-c` for the team (host + embedded).
2. Vendor Base **write-legible-c** (MIT, 7etsuo) under `references/base/` (unmodified); HOST branch runs Base procedure in-process (no second skill install).
3. EMBEDDED branch: Hard Order, Active Git Root + keywords, Path Class, HOT H1–H6, thin platform appendices.
4. Constraint Priority: platform/latency/size/frozen API ≥ Overlay ≥ Base.
5. README/NOTICE for attribution.

## Consequences

- Teammates install one path; no required marketplace step for Base.
- Upstream Base can still be updated by refreshing `vendor/write-legible-c`.
- Agents must classify before applying 15/40 rules—reduces ISR foot-guns.
- Overlay must stay small; full kernel docs stay out of the skill (L2).
