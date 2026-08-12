---
name: domain-model-c
description: >
  Domain model for C/C++ and SDK. Use when sharpening ubiquitous language
  (session, stream, message, device, error semantics), writing or updating
  CONTEXT.md, offering an ADR, challenging terms against public headers, or
  maintaining the domain model. Active model change only — not passive glossary
  read.
metadata:
  short-description: "Domain language for C/C++ SDK"
---

# Domain model (C/C++)

**Active** discipline: challenge terms, force edge scenarios, capture glossary
and decisions when they crystallise. Reading `CONTEXT.md` alone is not this
skill.

## Write gate

| Task posture | Action |
|--------------|--------|
| User asked to model / update docs / implement, or explicitly allows edits | Write `CONTEXT.md` / ADRs when terms resolve |
| Read-only, review-only, or “advise only” | Output proposed terms, full definitions, ADR drafts, and target paths — **do not** create or edit files |

**Done when:** writes happen only under the write column; otherwise proposals
are complete enough for a human to paste.

## Process

### 1. Load layout and glossary

1. Detect layout: `CONTEXT-MAP.md` → multi-context; else root `CONTEXT.md` →
   single; else none yet.
2. Multi-context cues (separate product languages: media / transport / platform
   HAL, nested BSP roots) → use or propose a map **before** creating files.
   Format: [CONTEXT-FORMAT.md](CONTEXT-FORMAT.md).
3. Read the active glossary for this topic. Do **not** create files until a term
   is resolved **and** the write gate allows.

**Done when:** single vs multi is chosen, the active context path is known (or
explicitly “none yet”), and no file was created prematurely.

### 2. Work the language in-session

On every fuzzy or contested term:

| Move | Action |
|------|--------|
| **Challenge** | User term vs glossary conflict → surface immediately |
| **Sharpen** | Overloaded word → one canonical term + `_Avoid_` list |
| **Scenario** | Stress relationships (half-close, hotplug, rekey, overrun) |
| **Cross-check** | User claim vs public headers / control flow; surface mismatch |

Prefer **domain** names (Session, Stream, Frame) over mechanism labels.
Families and error-contract language:
[references/term-families.md](references/term-families.md).

**Done when:** each contested term this thread is resolved or parked with an
open question.

### 3. Capture when a term resolves

Format: [CONTEXT-FORMAT.md](CONTEXT-FORMAT.md).

`CONTEXT.md` holds **stable product meanings** (Session, Stream, “link down”).
Mechanisms, enum tables, file paths, and lock types live in code or ADRs.

- Write gate allows → update the right CONTEXT immediately (lazy create).
- Write gate forbids → emit the exact glossary block and path for the user.

**Done when:** every resolved term is either on disk in the right CONTEXT or
delivered as a paste-ready block with path.

### 4. Offer an ADR only on the three-gate

Offer when **all** hold (SSOT — do not restate elsewhere as a second rule set):

1. **Hard to reverse** (ABI, wire layout, public error space, ownership)
2. **Surprising without context**
3. **Real trade-off** (alternatives existed)

Format only: [ADR-FORMAT.md](ADR-FORMAT.md). Create `docs/adr/` lazily under
the write gate.

Typical C/C++ SDK ADRs: opaque public handles; stable error space vs errno
passthrough; who frees buffers after `submit`; process-wide device table vs
explicit handles.

**Done when:** every three-gate decision is written, proposed (read-only), or
explicitly declined; ephemeral “not now” leaves no ADR.

Optional peers (not required): `deep-modules-c`, `improve-architecture-c`.
